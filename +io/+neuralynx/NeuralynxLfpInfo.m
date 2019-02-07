classdef NeuralynxLfpInfo < io.LfpInfoInterface
    methods
        function this = NeuralynxLfpInfo(sessionData)
            this = this@io.LfpInfoInterface(sessionData);
        end
    end

    methods (Access = protected)
        function eegFile = channel2filename(this, session, chId)
            filePattern = fullfile(session, sprintf('*%u.ncs', chId));
            ncsFile = dir(filePattern);
            eegFile = [];
            if ~isempty(ncsFile)
                % take the first one in case there are 1 and 11 and user is interested in 1.
                eegFile = fullfile(session, ncsFile(1).name);
            end
        end

        function channels = availableChannels(this, session)
            filePattern = fullfile(session, '*.ncs');
            ncsFiles = dir(filePattern);
            channels = zeros(length(ncsFiles), 1);
            for i = 1:length(ncsFiles)
                chNum = regexp(ncsFiles(i).name, '\d*', 'match');
                chNum = str2double(chNum{1});
                channels(i) = chNum;
            end
        end

        function numEegSamples = numSamplesPerChannel(this, session, firstChannel)
            eegFilename = this.channel2filename(session, firstChannel);
            channelNumbers = io.neuralynx.Nlx2MatCSC(eegFilename, [0 1 0 0 0], 0, 1);
            % NeuraLynx stores data in records with 512 samples per record
            numEegSamples = 512 * numel(channelNumbers);
        end

        function [eegData_v, Fs] = readRawEeg(this, session, chId)
            eegFilename = this.channel2filename(session, chId);

            [Fs, eegData_v, header] = io.neuralynx.Nlx2MatCSC(eegFilename, [0 0 1 0 1], 1, 1);
            if isempty(header)
                % look in one directory above
                [eegPath, eegFile, ext] = helpers.fileparts(eegFilename);
                eegFilename = fullfile(eegPath, '..', [eegFile ext]);
                header = io.neuralynx.Nlx2MatCSC(eegFilename, [0 0 0 0 0], 1, 1);
            end
            if isempty(header)
                error('Failed to extract header from file %s. I need the header to convert signal to Volts!', eegFilename);
            end

            bit2VoltsInd = cellfun(@(x) ~isempty(x), strfind(lower(header), lower('ADBitVolts')));
            bit2VoltsRecord = header(bit2VoltsInd);
            abBitVolts = regexp(bit2VoltsRecord, '\d*\.\d*', 'match');
            eegData_v = eegData_v * str2double(abBitVolts{1}{1});
            eegData_v = eegData_v(:);
            Fs = Fs(1);
        end
    end
end