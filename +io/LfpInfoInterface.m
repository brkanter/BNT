classdef LfpInfoInterface < handle
    %LfpInfo Class that helps to work with LFP (EEG) data. This is an abstract
    %        base class. Must be extended for concrete recording system.
    %        The idea is that we try to have EEG in memory for as little as possible.

    properties (Access = protected)
        sessions % cell array of sessions
        sessionData % stripped version of information about the current trial/session
    end

    methods
        function this = LfpInfoInterface(sessionData) %#ok<*INUSD>
            this.sessions = sessionData.sessions;

            this.sessionData.sessions = sessionData.sessions;
            this.sessionData.basename = sessionData.basename;
            this.sessionData.cuts = {};

            % channels = [];
            % for s = 1:length(this.sessions)
            %     newEegFilename = helpers.uniqueFilename(this.sessionData, 'eeg', s);

            %     if ~exist(newEegFilename, 'file')
            %         availableChannels = sort(this.availableChannels(this.sessions{s}));

            %         if isempty(channels)
            %             channels = availableChannels;
            %         else
            %             if ~isequal(channels, availableChannels)
            %                 error('BNT:loadEeg', 'Unable to locate the same set of EEG signals for the combined sessions.\nFirst session: %s', sessions{1});
            %             end
            %         end

            %         % get information necessary for memory preallocation.
            %         % Assume the same number of EEG samples throughout the session
            %         %numEegSamples = this.numSamplesPerChannel(this.sessions{s}, availableChannels(1));

            %         %allEeg = zeros(numEegSamples, length(availableChannels));
            %         %allFs = zeros(1, length(availableChannels));

            %         try
            %             this.h5write(newEegFilename, '/channels', availableChannels);
            %             for c = 1:length(availableChannels)
            %                 chId = availableChannels(c);
            %                 [eegSamples, Fs] = this.readRawEeg(this.sessions{s}, chId);
            %                 eegSamples = eegSamples';
            %                 %allEeg(:, c) = eegSamples;
            %                 %allFs(c) = Fs;

            %                 datasetName = sprintf('/channel_%02u/', chId);
            %                 this.h5write(newEegFilename, [datasetName 'data'], eegSamples);
            %                 this.h5write(newEegFilename, [datasetName 'Fs'], Fs);
            %                 h5writeatt(newEegFilename, datasetName, 'Units', 'Volts');
            %             end
            %         catch ME
            %             delete(newEegFilename);
            %             rethrow(ME);
            %         end

            %         % save eeg for that session
            %         % eeg = allEeg;
            %         % Fs = allFs;
            %         % channels = availableChannels;
            %         % units = 'Volts';
            %         % save(newEegFilename, 'eeg', 'Fs', 'channels', 'units');
            %         % clear allEeg allFs eeg;
            %     end
            % end
        end

        function [eeg, Fs] = getEeg(this, channels)
            Fs = [];

            % first check out the total number of samples
            numEegSamples = zeros(1, length(this.sessions));
            for s = 1:length(this.sessions)
                availableChannels = this.availableChannels(this.sessions{s});
                if ~isempty(setdiff(channels, availableChannels))
                    available_str = sprintf('%02u ', availableChannels);
                    requested_str = sprintf('%02u ', channels);
                    available_str(end) = [];
                    requested_str(end) = [];
                    error('Session %s does not contain requested EEG channel(s).\nAvailable: %s; requested: %s', this.sessions{s}, available_str, requested_str);
                end

                numEegSamples(s) = this.numSamplesPerChannel(this.sessions{s}, channels(1));
            end
            eeg = zeros(sum(numEegSamples), length(channels));

            % now fill the data
            sessionStart = 1;
            for s = 1:length(this.sessions)
                sessionEnd = sessionStart + numEegSamples(s) - 1;

                for c = 1:length(channels)
                    chId = channels(c);
                    % read raw EEG signal, convert it to Volts
                    [eeg(sessionStart:sessionEnd, c), curFs] = this.readRawEeg(this.sessions{s}, chId);
                end
                if s == 1
                    Fs = curFs;
                else
                    if ~isequal(Fs, curFs)
                        error('Combined sessions have different Fs of EEG signal. This is currently unsupported. First session %s', this.sessions{1});
                    end
                end

                sessionStart = sessionEnd + 1;
            end
        end

        function theta = getTheta(this, channels, thetaFrequency)
            if channels == -1
                channels = this.availableChannels(this.sessions{1});
            end
            if isempty(channels)
                theta = [];
                return;
            end
            [eeg, thetaFs] = this.getEeg(channels);
            theta = general.fastFftBandpass(eeg, thetaFs(1), thetaFrequency(1), thetaFrequency(2));

            maxTime = (size(theta, 1) - 1) / thetaFs;
            curTime = 0:1/thetaFs:maxTime;
            theta = [curTime(:) theta];

        %     thetaData = [];
        %     thetaTime = [];

        %     for s = 1:length(this.sessions)
        %         thetaFilename = helpers.uniqueFilename(this.sessionData, 'theta', s);
        %         needToCreate = true;

        %         if exist(thetaFilename, 'file')
        %             %p = load(thetaFilename);
        %             datasetName = sprintf('/channel_%02u/', channels(1));
        %             p.thetaFrequency = h5read(thetaFilename, [datasetName 'thetaFrequency']);
        %             % check frequency
        %             if isequal(thetaFrequency, p.thetaFrequency)
        %                 availableChannels = h5read(thetaFilename, '/channels');
        %                 if ~isempty(setdiff(channels, availableChannels))
        %                     available_str = sprintf('%02u ', availableChannels);
        %                     requested_str = sprintf('%02u ', channels);
        %                     available_str(end) = [];
        %                     requested_str(end) = [];
        %                     error('Theta file %s does not contain requested channel(s).\nAvailable: %s; requested: %s', thetaFilename, available_str, requested_str);
        %                 end
        %                 needToCreate = false;
        %                 %theta = p.theta;
        %                 %thetaFs = p.thetaFs;
        %                 %clear p;
        %             end
        %         end

        %         if needToCreate
        %             eegFilename = helpers.uniqueFilename(this.sessionData, 'eeg', s);
        %             %load(eegFilename); % variables eeg, Fs, channels, units
        %             descr = 'Obtained by general.fftBandpass';
        %             availableChannels = h5read(eegFilename, '/channels');
        %             for c = 1:length(availableChannels)
        %                 chId = availableChannels(c);

        %                 datasetName = sprintf('/channel_%02u/', chId);
        %                 thetaFs = h5read(eegFilename, [datasetName 'Fs']);
        %                 eeg = h5read(eegFilename, [datasetName 'data']);
        %                 theta = general.fastFftBandpass(eeg, thetaFs(1), thetaFrequency(1), thetaFrequency(2));

        %                 this.h5write(thetaFilename, [datasetName 'data'], theta);
        %                 this.h5write(thetaFilename, [datasetName 'thetaFrequency'], thetaFrequency);
        %                 this.h5write(thetaFilename, [datasetName 'Fs'], thetaFs);
        %                 h5writeatt(thetaFilename, datasetName, 'Description', descr);
        %             end
        %             this.h5write(thetaFilename, '/channels', availableChannels);
        %             % save(thetaFilename, 'theta', 'thetaFrequency', 'descr', 'thetaFs');
        %         end

        %         % get number of samples per channel, assume equal number per session
        %         datasetName = sprintf('/channel_%02u/', channels(1));
        %         info = h5info(thetaFilename, datasetName);
        %         numSamples = max(info.Datasets(2).Dataspace.Size);
        %         theta = zeros(numSamples, length(channels));
        %         thetaFs = h5read(thetaFilename, [datasetName 'Fs']);
        %         for c = 1:length(channels)
        %             chId = channels(c);
        %             datasetName = sprintf('/channel_%02u/', chId);
        %             theta(:, c) = h5read(thetaFilename, [datasetName 'data']);
        %         end

        %         maxTime = (size(theta, 1) - 1) / thetaFs;
        %         curTime = 0:1/thetaFs:maxTime;
        %         if isempty(thetaData)
        %             thetaData = theta;
        %             thetaTime = curTime';
        %         else
        %             curTime = curTime + thetaTime(end) + 1/thetaFs;
        %             thetaData = cat(1, thetaData, theta);
        %             thetaTime = cat(1, thetaTime, curTime);
        %         end
        %     end
        %     %thetaData = thetaData(:, channels);
        %     theta = [thetaTime thetaData];
        end
        
        function disp(this)
            if isempty(this.sessions)
                return;
            end
            ch = this.availableChannels(this.sessions{1});
            fprintf('Lfp information\n');
            fprintf(' Number of sessions: %u\n', length(this.sessions));
            fprintf(' First session %s\n', this.sessions{1});
            fprintf(' Available channels: ');
            if isempty(ch)
                fprintf('none\n');
            else
                fprintf('%u ', ch);
                fprintf('\n');
            end
        end
    end

    methods (Abstract, Access = protected)
        % return EEG filename for specified chId and session
        eegFile = channel2filename(this, session, chId)

        % return indices of available channels
        channels = availableChannels(this, session)

        % return number of EEG samples per channel. Assumes equal number
        % of samples across channels in one session
        % firstChannel - ID of the first available channel
        numEegSamples = numSamplesPerChannel(this, session, firstChannel)

        % read raw EEG signal, convert it to Volts
        [eegData_v, Fs] = readRawEeg(this, session, channel)
    end

    methods (Access = protected)
        function h5write(~, filename, datasetName, data, varargin)
            h5create(filename, datasetName, size(data), varargin{:});
            h5write(filename, datasetName, data);
        end
    end
end