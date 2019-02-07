% Load all the EEG and EGF files that are available for this session.
function eegData = getEEGs(channelGains, adcFullscale, session)

    import io.axona.readEEG;
    import io.axona.eegBits2Voltage;
    import io.axona.readEGF;

numPossibleEEGs = length(channelGains);
% 1 EEG samples
% 2 Sampling rate, Fs
% 3 File name
eegData = cell(2*numPossibleEEGs,3);
eegCounter = 0;

if adcFullscale == 3680 % Dacq 2
    % Get low resolution EEG
    for e = 1:numPossibleEEGs
        if ~isnan(channelGains(e))
            if e == 1
                eegFileName = sprintf('%s%s',session,'.EEG');
            else
                eegFileName = sprintf('%s%s%u',session,'.EG',e);
            end

            [status, eegSamples, Fs, bytesPerSample] = readEEG(eegFileName);
            if status == 1
                eegCounter = eegCounter + 1;

                sInd = strfind(eegFileName,'.');
                if ~isempty(sInd)
                    eegFileName = eegFileName(sInd(end)+1:end);
                end
                
                if strcmp(eegFileName,'EEG')
                    eegFileName = 'eeg';
                end
                if strcmp(eegFileName(1:2),'EG')
                    eegFileName = strcat('eeg',eegFileName(3:end));
                end

                eegData{eegCounter,1} = eegBits2Voltage(eegSamples, channelGains(e), adcFullscale, bytesPerSample);
                eegData{eegCounter,2} = Fs;
                eegData{eegCounter,3} = eegFileName;
            end
        end
    end
    
    % Get High resolution EEG (assumes only one high res EEG for Dacq2).
    if ~isnan(channelGains(1))
        eegFileName = sprintf('%s%s',session,'.EGF');
        [status, eegSamples, Fs, bytesPerSample] = readEGF(eegFileName);
        if status == 1
            eegCounter = eegCounter + 1;
            
            eegFileName = 'egf';
            
            % Convert the signal from bits to microvolts
            eegData{eegCounter,1} = eegBits2Voltage(eegSamples, channelGains(1), adcFullscale, bytesPerSample);
            eegData{eegCounter,2} = Fs;
            eegData{eegCounter,3} = eegFileName;
        end
    end
end

if adcFullscale == 1500 % Dacq USB
    % Get low resolution EEGs
    for e = 1:numPossibleEEGs
        if ~isnan(channelGains(e))
            if e == 1
                eegFileName = sprintf('%s%s',session,'.eeg');
                [status, eegSamples, Fs, bytesPerSample] = readEEG(eegFileName);
            else
                eegFileName = sprintf('%s%s%u',session,'.eeg',e);
                [status, eegSamples, Fs, bytesPerSample] = readEEG(eegFileName);
                if status == 0
                    eegFileName = sprintf('%s%s%u',session,'.eg',e);
                    [status, eegSamples, Fs, bytesPerSample] = readEEG(eegFileName);
                end
            end
            
            if status == 1
                eegCounter = eegCounter + 1;
            
                sInd = strfind(eegFileName,'.');
                if ~isempty(sInd)
                    eegFileName = eegFileName(sInd(end)+1:end);
                end
                
                if strcmp(eegFileName(1:2),'eg')
                    eegFileName = strcat('eeg',eegFileName(3:end));
                end

                % Convert the signal from bits to microvolts
                eegData{eegCounter,1} = eegBits2Voltage(eegSamples, channelGains(e), adcFullscale, bytesPerSample);
                eegData{eegCounter,2} = Fs;
                eegData{eegCounter,3} = eegFileName;
            end
            
        end
    end
    
    % Get high resolution EEGs
    for e = 1:numPossibleEEGs
        if ~isnan(channelGains(e))
            if e == 1
                eegFileName = sprintf('%s%s',session,'.egf');
                [status, eegSamples, Fs, bytesPerSample] = readEGF(eegFileName);
            else
                eegFileName = sprintf('%s%s%u',session,'.egf',e);
                [status, eegSamples, Fs, bytesPerSample] = readEGF(eegFileName);
                if status == 0
                    eegFileName = sprintf('%s%s%u',session,'.ef',e);
                    [status, eegSamples, Fs, bytesPerSample] = readEGF(eegFileName);
                end
            end
            if status == 1
                eegCounter = eegCounter + 1;
                sInd = strfind(eegFileName,'.');
                if ~isempty(sInd)
                    eegFileName = eegFileName(sInd(end)+1:end);
                end
                
                if strcmp(eegFileName(1:2),'ef')
                    eegFileName = strcat('egf',eegFileName(3:end));
                end
                
                % Convert the signal from bits to microvolts
                eegData{eegCounter,1} = eegBits2Voltage(eegSamples, channelGains(e), adcFullscale, bytesPerSample);
                eegData{eegCounter,2} = Fs;
                eegData{eegCounter,3} = eegFileName;
                
            end
            
        end
    end
end


eegData = eegData(1:eegCounter,:);
