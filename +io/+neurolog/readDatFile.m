% Read spike timestamps from Neurolog-16 raw file
%
% This function reads raw data from Neurolog-16 file and extracts spikes from it.
% The spike extraction prcedure is threshold based. It tries to mimic NeuraLynx spike
% extraction algorithm.
%
%  USAGE
%   [spikes, samples] = io.neurolog.readDatFile(datFile, <options>)
%   datFile         path to .DAT file with raw data
%   spikes          Cell vector of length numTetrodes (4). Each
%                   element contains a vector of spike timestamps in micro sec.
%   samples         Cell vector of length numTetrodes (4). Each element is a matrix
%                   of data points of a spike. Refer to description of NeyraLynx data in
%                   http://neuralynx.com/software/NeuralynxDataFileFormats.pdf (tetrode spike data)
%                   Matrix has size <DATAPOINTS, CHANNELS, SPIKES>, where DATAPOINTS is 32,
%                   CHANNELS is 4 and value of SPIKES corresponds to number of detected spikes.
%                   samples{1}(:, 2, 3) denotes EEG signal of spike #3 on second channel
%                   of first tetrode.
%   <options>   Optional list of property-value pairs (see table below)
%
%   ==============================================================================================
%    Properties    Values
%   ----------------------------------------------------------------------------------------------
%    'samplingTime'   Sampling time in seconds at which data has been written to .dat
%                     file. Default value is 3.41333328E-5.
%    'channels'       Number of channels in use. Default value is 16.
%    'resolution'     ADC resolution in micro Volts. Default value is: 3.3 microV.
%   ==============================================================================================
%
function [spikes, samples] = readDatFile(dataFile, varargin)
    numSamples = 512*1024;
    numTetrodes = numChannels / 4;

    defaultSamplingTime = 3.41333328E-5; % sec, time between two measurements
    defaultNumChannels = 16;
    defaultResolution = 3.3;

    inp = inputParser;
    addRequired(inp, 'dataFile');
    addParameter(inp, 'samplingTime', defaultSamplingTime, @(x) ~isempty(x));
    addParameter(inp, 'channels', defaultNumChannels, @(x) ~isempty(x) && x > 0);
    addParameter(inp, 'resolution', defaultResolution, @(x) ~isempty(x) && x > 0);
    parse(inp, dataFile, varargin{:});

    sampleTime = inp.Results.samplingTime;
    numChannels = inp.Results.channels;
    adcResolution = inp.Results.resolution;

    Fs = 1 / sampleTime;
    time = 0:sampleTime:(numSamples-1)*sampleTime;
    time_microSec = time * 10^6;

    filter = [600 6000]; % frequencies of bandpass filter

    threshold_microvolts = 250; % threshold = mean + threshold_microvolts
    threshold_mV = threshold_microvolts / 10^3;

    activityDelta_num = ceil(160 / 10^6 / sampleTime); % 160 microseconds
    retrigger_num = ceil(100 / 10^6 / sampleTime);

    numBefore = 7;
    numAfter = 24;

    fid = fopen(dataFile, 'r', 'l');
    % the documentation says that data is stored as 2D array: 524288 lines,
    % each line contains 16 2-byte integers. However, the corresponding dimensions in Matlab are:
    % [numChannels numSamples].
    allData = fread(fid, [numChannels numSamples], 'uint16=>double');
    % convert from binary to volts according to 7.2.1.1 of Neurolog12 instructions
    allData = adcResolution * (allData - 2048);
    fclose(fid);

    for t = 1:numTetrodes
        firstChannel = (t-1)*4;
        channelData = cell(1, 4);
        for i = 1:4
            channelData{i} = allData(firstChannel + i, :);
            channelData{i} = channelData{i} * -1 / 30; % convert values from bits to muV
            [b, a] = butter(8, [filter(1) filter(2)]/(Fs/2), 'bandpass');
            mu = mean(channelData{i});
            channelData{i} = filtfilt(b, a, channelData{i}) + mu;
        end

        tetrodeSamples = zeros(32, 4, 20000); % spike EEGs, 32 samples per spike, 4 channels
        spikeTimestamps = zeros(1, 20000);
        numSpikes = 0;

        allChanels = [1 2 3 4];

        for i = 1:length(allChanels)
            dcRemoved = channelData{i};
            mu = mean(dcRemoved);
            threshold_mV = 3 * median(abs(dcRemoved - mu)/0.6745) + mu;

            [~, peakInd] = find(dcRemoved > threshold_mV);
            numSamples = length(dcRemoved);

%             validSamples = false(1, numSamples);

            while ~isempty(peakInd)
                excInd = peakInd(1); % excitation index, first pass over threshold
                endActivityInd = excInd + activityDelta_num;
                if endActivityInd > numSamples
                    endActivityInd = numSamples;
                end
                [~, calmInd] = find(dcRemoved(excInd:endActivityInd) < threshold_mV, 1);
                if isempty(calmInd)
                    peakInd(1) = [];
                    continue;
                end
                numSpikes = numSpikes + 1;

%                 fprintf(fid, 'Event %i, (%u - %u), time ms (%f - %f)\n', numSpikes+1, excInd, excInd+calmInd, excInd*samplePeriod_ms, (excInd+calmInd) * samplePeriod_ms);
%                 fprintf('Spike #%u\n', numSpikes);
                [~, maxInd] = max(dcRemoved(excInd:excInd+calmInd-1));
                maxInd = maxInd + excInd;
                indBefore = maxInd - numBefore;
                indAfter = maxInd + numAfter;
                indRetrigger = maxInd + retrigger_num;
                if indBefore < 1
                    indBefore = 1;
                    % add offset
                end
                if indAfter > numSamples
                    indAfter = numSamples;
                end
                if indRetrigger > numSamples
                    indRetrigger = numSamples;
                end

                %spikeEeg = (dcRemoved(indBefore:indAfter) ) * 1;
%                 validSamples(indBefore:indAfter) = true;

                spikeTimestamps(numSpikes) = time_microSec(maxInd);
                for j = 1:4
                    eeg = channelData{j}(indBefore:indAfter);
                    offset = (numBefore + numAfter + 1) - length(eeg);
                    if offset > 0
                        eeg = [eeg ones(1, offset)*mu];
                    end
                    tetrodeSamples(:, j, numSpikes) = eeg;
                end

                peakInd(peakInd <= indRetrigger) = [];
            end
    %         figure, plot(time, dcRemoved(validSamples));
        end
        tetrodeSamples(:, :, numSpikes+1:end) = [];
        spikeTimestamps(numSpikes+1:end) = [];

        spikes{t} = spikeTimestamps; %#ok<AGROW>
        samples{t} = tetrodeSamples; %#ok<AGROW>
    end
end