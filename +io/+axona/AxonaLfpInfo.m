classdef AxonaLfpInfo < io.LfpInfoInterface

    properties (Access = private)
        adcFullscale
        channelGains
    end

    methods
        function this = AxonaLfpInfo(sessionData)
            this = this@io.LfpInfoInterface(sessionData);
        end

    end

    methods (Access = protected)
        function eegFile = channel2filename(this, session, chId) %#ok<INUSL>
            if chId == 1
                eegFile = sprintf('%s.eeg', session);
                if exist(eegFile, 'file')
                    return;
                end
            else
                eegFile = sprintf('%s.eeg%u', session, chId);
                if exist(eegFile, 'file')
                    return;
                end
                eegFile = sprintf('%s.eg%u', session, chId);
                if ~exist(eegFile, 'file')
                    warning('Failed to locate EEG file, session %s, channel %u', session, chId);
                end
            end
        end

        function channels = availableChannels(this, session)
            setFilename = strcat(session, '.set');
            [this.channelGains, this.adcFullscale] = io.axona.getEegProperties(setFilename);
            channels = find(~isnan(this.channelGains));
            invalidChannels = false(1, length(channels));
            for i = 1:length(channels)
                if exist(this.channel2filename(session, channels(i)), 'file') == 0
                    invalidChannels(i) = true;
                end
            end
            channels(invalidChannels) = [];
        end

        function numEegSamples = numSamplesPerChannel(this, session, firstChannel)
            eegFilename = this.channel2filename(session, firstChannel);
            if exist(eegFilename, 'file') == 0
                numEegSamples = 0;
                return;
            end
            header = io.axona.readTrackerHeader(eegFilename);
            numEegSamples = str2double(header.num_EEG_samples);
        end

        function [eegData_v, Fs] = readRawEeg(this, session, chId)
            gain = this.channelGains(chId);
            eegFilename = this.channel2filename(session, chId);

            [status, eegData_v, Fs, bytesPerSample] = io.axona.readEEG(eegFilename);
            eegData_v = io.axona.eegBits2Voltage(eegData_v, gain, this.adcFullscale, bytesPerSample);
        end
    end
end