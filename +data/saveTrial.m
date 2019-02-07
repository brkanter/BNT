% Save data of current trial on disc in a format that is independent of a recording system
%
function saveTrial(trialNum)
    global gBntData;

    if length(gBntData) < trialNum
        error('Specified trial number is bigger than available amount of trials');
    end

    fprintf('Saving loaded data in Matlab format\n');

    if isfield(gBntData{trialNum}, 'eegData')
        for e = 1:size(gBntData{trialNum}.eegData, 1)
            if isempty(gBntData{trialNum}.eegData{e, 1})
                continue;
            end

            filename = gBntData{trialNum}.eegData{e, 3};

            eegData = cell(1, 3);
            eegData(1, :) = gBntData{trialNum}.eegData(e, :);

            % TODO: get filename through helper
            eegFile = fullfile(gBntData{trialNum}.path, sprintf('%s_%s.mat', gBntData{trialNum}.basename, filename));
            if ~exist(eegFile, 'file')
                fprintf('Saving file %s...', eegFile);
                save(eegFile, 'eegData');
                fprintf(' done\n');
            end
        end

        gBntData{trialNum} = rmfield(gBntData{trialNum}, 'eegData');
    end

    sessionData = gBntData{trialNum};

    key = helpers.uniqueKey(sessionData.basename, sessionData.cuts);

%     oldDataSchema = { ...
%         fullfile(gBntData{trialNum}.path, sprintf('%s_data.mat', gBntData{trialNum}.basename)), ...
%         fullfile(gBntData{trialNum}.path, sprintf('%s_%u_data.mat', gBntData{trialNum}.basename, gBntData{trialNum}.tetrode)), ...
%         fullfile(gBntData{trialNum}.path, sprintf('%s_T*_data_%s.mat', gBntData{trialNum}.basename, key)) ...
%     };
%     for kk = 1:length(oldDataSchema)
%         curFile = oldDataSchema{kk};
%         hasAsterisk = ~isempty(strfind(curFile, '*'));
%         if exist(curFile, 'file') ~= 0 || hasAsterisk
%             if ~hasAsterisk
%                 fprintf('Found old data file ''%s'', deleting\n', curFile);
%             end
%             delete(curFile);
%         end
%     end

    % Save cell data in separate files
    if isempty(gBntData{trialNum}.tetrode)
        numCells = size(gBntData{trialNum}.units, 1);
    else
        numCells = size(gBntData{trialNum}.units, 2);
    end
    for u = 1:numCells
        cellTS = [];  %#ok<*NASGU>
        if isempty(gBntData{trialNum}.tetrode)
            % we have different tetrodes
            unit = gBntData{trialNum}.units(u, :);
            if ~isempty(sessionData.spikes)
                cellTS = sessionData.spikes(sessionData.spikes(:, 2) == unit(1) & sessionData.spikes(:, 3) == unit(2), 1);
            end
            cellLinearInd = helpers.tetrodeCellLinearIndex(sessionData.units(u, 1), sessionData.units(u, 2));
            cutFileHash = gBntData{trialNum}.cutHash(cellLinearInd);
        else
            unit = gBntData{trialNum}.units(u);
            if ~isempty(sessionData.spikes)
                cellTS = sessionData.spikes(sessionData.spikes(:, 3) == unit, 1);
            end
            cutFileHash = {};
        end

        % save even when cellTS is empty. Otherwise cache loading will be broken
        cutDataFile = helpers.uniqueFilename(sessionData, 'cut', unit);
        save(cutDataFile, 'cellTS', 'cutFileHash');
    end

    % remove cell data from session data
    sessionData = rmfield(sessionData, 'spikes');

    % save position data separatly, remove it from sessionData
    creationTime = now;
    posDataFile = helpers.uniqueFilename(sessionData, 'pos');
    positions = sessionData.positions;
    save(posDataFile, 'positions', 'creationTime');

    sessionData = rmfield(sessionData, 'positions');

    cacheCreation = now;
    dataFile = helpers.uniqueFilename(sessionData, 'data');
    fprintf('Saving file %s...', dataFile);
    save(dataFile, 'sessionData', 'cacheCreation');
    fprintf(' done\n');
end
