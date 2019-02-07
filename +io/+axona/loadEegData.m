function eegDataAll = loadEegData(trialNum)
    global gBntData;

    trialData = gBntData{trialNum};
    numSessions = length(trialData.sessions);
    eegDataAll = {};

    for s = 1:numSessions
        setFilename = strcat(trialData.sessions{s}, '.set');
        [channelGains, adcFullscale] = io.axona.getEegProperties(setFilename);

        fprintf('Loading available EEG data...')
        tEegData = io.axona.getEEGs(channelGains, adcFullscale, trialData.sessions{s});
        fprintf(' done\n');

        numEEGs = size(eegDataAll, 1);
        if s == 1
            eegDataAll = tEegData;
        else
            if size(tEegData, 1) ~= numEEGs
                warning('BNT:loadEeg', 'Unable to locate the same set of EEG signals for the combined sessions.');
            else
                for e=1:numEEGs
                    eegDataAll{e, 1} = [eegDataAll{e, 1}; tEegData{e, 1}];
                end
            end
        end
    end

    % remove empty entries
    toDelete = cellfun(@isempty, eegDataAll(:, 2));
    eegDataAll(toDelete, :) = [];
end