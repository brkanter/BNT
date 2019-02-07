% Read spike timestamps and waveforms from Axona data file
%
% This function reads spike timestamps and waveforms from Axona tetrode file.
% Note that only 4 channels are supported for now.
% The function outputs waveforms in Volts. In order to do it, it tries to parse
% corresponding .SET file and to extract conversion coefficients. If function fails
% to find .SET file, then the default values are used!
%
%  USAGE
%   [spikes, waveforms] = io.axona.importspikes(filename)
%   filename        Path to a tetrode data file
%   spikes          Array of spike timestamps. The timestamps are given in seconds.
%   waveforms       3D array of waveform samples for each of the 4 channels and spike.
%                   Dimensions are [samples channels spikes], i.e. waveforms(:, 1, 1) is
%                   the waveform for the first spike on the first channel.
%
function [spikes, waveforms] = importspikes(filename)
    [fileHeader, dataStart] = io.axona.readTrackerHeader(filename);
    neededHeader = {'timebase', 9600; 'duration', inf; 'num_spikes', inf; 'bytesPerSample', 1; ...
        'bytes_per_timestamps', 4; 'samples_per_spike', 50};

    fileHeader = adjustHeader(fileHeader, neededHeader);

    if ~isfield(fileHeader, 'spike_format')
        error('BNT:io:axonaSpikeHeader', 'No spike format reported, cannot read spikes from %s\nAre you sure this is a spike file?', filename);
    end
    supportedFormat = 't,ch1,t,ch2,t,ch3,t,ch4';
    if ~strcmpi(fileHeader.spike_format, supportedFormat)
        error('BNT:io:axonaSpikeFormat', 'Unsupported format of Axona spike file. Expect to have %s, but got %s.', supportedFormat, fileHeader.spike_format);
    end

    if nargout > 1
        % try to extract gain and ADC information from the .set file
        [sessionPath, sessionName, ext] = helpers.fileparts(filename);
        setFilename = fullfile(sessionPath, sprintf('%s.set', sessionName));
        try
            setContent = io.axona.readTrackerHeader(setFilename);
            adcFullscale_uV = str2double(setContent.ADC_fullscale_mv) * 1e3; % in microvolts
            tetrodeNum = str2double(ext(2:end)); % range is 1-16
            if isnan(tetrodeNum)
                warning('Unknown extension of spike file. Failed to extract correspondent gain values. Will use default value of 10000.');
                gains = ones(1, 4) * 10000;
            else
                channelStart = (tetrodeNum - 1) * 4;
                gainFields = strsplit(sprintf('gain_ch_%u ', channelStart:channelStart+3), ' ');
                % without loop just to make it straightforward
                gains(1) = str2double(setContent.(gainFields{1}));
                gains(2) = str2double(setContent.(gainFields{2}));
                gains(3) = str2double(setContent.(gainFields{3}));
                gains(4) = str2double(setContent.(gainFields{4}));
            end
        catch
            warning('BNT:noFile', 'Failed to find file %s. Will use default values for bit to volt conversion.', setFilename);
            adcFullscale_uV = 1500 * 1e3; % 1500 mV is default for DacqUSB
            gains = ones(1, 4) * 10000;
        end
    end

    timebase = digitize(fileHeader.timebase);
    numSpikes = digitize(fileHeader.num_spikes);
    bytesPerSample = digitize(fileHeader.bytes_per_sample);
    bytesPerTimestamp = digitize(fileHeader.bytes_per_timestamp);
    samplesPerSpike = digitize(fileHeader.samples_per_spike);
    numChannels = 4; % although it is possible to get it from the file, we only support
                     % 4 channels

    fid = data.safefopen(filename, 'r');
    % get spikes only from the first channel. Spikes are stored in
    % big-endian format.
    fseek(fid, dataStart, 'bof');
    spikes = fread(fid, numSpikes, 'uint32', samplesPerSpike*numChannels + bytesPerTimestamp*3, 'b');
    spikes = spikes / timebase;

    if nargout > 1
        % read out waveforms
        fseek(fid, dataStart + bytesPerTimestamp, 'bof');
        precission = sprintf('%u*int8', samplesPerSpike);
        % waveforms are little-endian.
        waveforms = fread(fid, samplesPerSpike*numChannels*numSpikes, precission, bytesPerTimestamp, 'l');
        if all(gains == gains(1))
            waveforms = io.axona.eegBits2Voltage(waveforms, gains(1), adcFullscale_uV, bytesPerSample);
            waveforms = reshape(waveforms, samplesPerSpike, numChannels, numSpikes);
        else
            waveforms = reshape(waveforms, samplesPerSpike, numChannels, numSpikes);
            for i = 1:numChannels
                waveforms(:, i, :) = io.axona.eegBits2Voltage(waveforms(:, i, :), gains(i), adcFullscale_uV, bytesPerSample);
            end
        end
        % permute increase execution time. Example, from 0.65 to 0.74 sec.
        %waveforms = permute(waveforms, [1 3 2]);
    end
end

% header - structure that we read from the file
% needHeader - Nx2 cell array. First column contains header field names,
%              second column contains default values.
% The function assigns default values for missing header field names.
function header = adjustHeader(header, neededHeader)
    for i = 1:size(neededHeader, 1)
        curParam = neededHeader(i, :);
        if ~isfield(header, curParam{1})
            header.(curParam{1}) = curParam{2};
        end
    end
end

function val = digitize(strVal)
    val = regexp(strVal, '\d+', 'match');
    val = str2double(val{1});
end