% Locate Axona cut file names from session data
%
% This function normalizes information about cut files. It checks that information about cut files
% is provided, it autodetects cut files if they are not provided in input file. This prepares
% everything what is needed to load cells.
% Note that Axona saves one file per tetrode.
%
function sessionData = detectAxonaCuts(sessionData)
    numSessions = length(sessionData.sessions);
    cutFiles = sessionData.cuts;
    tetrodes = unique(sessionData.units(:, 1), 'stable');
    [~, sessionNames] = cellfun(@(x) helpers.fileparts(x), sessionData.sessions, 'uniformoutput', false);
    tetrodesToDelete = [];

    % 1. single session, single cut file
    % 2. single session, multiple cuts => makes no sense, unsupported
    % 3. multiple sessions, single cut file
    % 4. multiple sessions, multiple cuts (one per session)
    % 5. multiple sessions, some cuts are missed (makes no sense, unsupported)
    % 6. single session, no cut
    % 7. multiple sessions, no cut
    %
    for t = 1:length(tetrodes)
        if ~isempty(cutFiles)
            if t <= size(cutFiles, 1)
                numCuts = sum(~cellfun('isempty', cutFiles(t, :)));
            else
                numCuts = 0;
            end
        else
            numCuts = 0;
        end
        if numCuts == 0
            % autodetect for combined session if any
            if numSessions > 1
                cutFile = fullfile(sessionData.path, sprintf('%s_%u.cut', sessionData.basename, tetrodes(t)));
                if exist(cutFile, 'file') ~= 0
                    cutFiles{t, 1} = cutFile;
                    numCuts = numCuts + 1;
                end
            end

            if numCuts == 0 % no cut file with combined sessions was found or there is a single session
                % autodetect for all sessions
                for s = 1:numSessions
                    cutFile = fullfile(sessionData.path, sprintf('%s_%u.cut', sessionNames{s}, tetrodes(t)));
                    if exist(cutFile, 'file') ~= 0
                        cutFiles{t, s} = cutFile;
                        numCuts = numCuts + 1;
                        currentCutSessions = io.axona.getCutInfo(cutFile);
                        if isempty(setdiff(sessionNames, currentCutSessions))
                            % this is a hack if a cut file for first session contains information about all sessions
                            % This is most likely legacy code (from times of 'linear track tale' input 0.2).
                            break;
                        end
                    end
                end
            end
        end

        if numCuts > numSessions
            error('BNT:badCuts', 'Configuration when there are more cuts than sessions is not supported. Check your data and input file');
        end

        if numCuts == numSessions
            % 1. single session, single cut
            % 2. multiple sessions, multiple cuts
            % do nothing
        else
            if numCuts == 1
                % multiple sessions, single cut
                if exist(cutFiles{t, 1}, 'file') == 0
                    % not a full path?
                    cutFiles{t, 1} = fullfile(sessionData.path, cutFiles{t, 1});
                end
                currentCutSessions = io.axona.getCutInfo(cutFiles{t, 1});
                [~, missedSessionsInd] = setdiff(sessionNames, currentCutSessions);
                if length(currentCutSessions) == 1 || ~isempty(missedSessionsInd)
                    error('BNT:badCuts', 'Cut file does not correspond to specified multiple sessions.\nFirst session %s\nCheck your input file!', sessionData.sessions{1});
                end
            else
                if t > size(cutFiles, 1)
                    cellIdx = find(sessionData.units(:, 1) == tetrodes(t), 1, 'first');
                    if ~isnan(sessionData.units(cellIdx, 2))
                        % only output a warning if we do not do an auto-detection
                        warning('BNT:badCuts', 'Axona: Failed to find cut file(s) for tetrode %u, %s. This can be an error or you do auto-detection of units and do not have cut files for all tetrodes.', tetrodes(t), sessionData.basename);
                    end
                    tetrodesToDelete = cat(1, tetrodesToDelete, tetrodes(t));
                    continue;
                end
                % get list of sessions that are covered by cut files
                cutSessions = {};
                for s = 1:size(cutFiles, 2)
                    if s > size(cutFiles, 2) || isempty(cutFiles{t, s})
                        continue;
                    end
                    currentCutSessions = io.axona.getCutInfo(cutFiles{t, s});
                    if size(currentCutSessions, 2) > 1
                        currentCutSessions = currentCutSessions';
                    end
                    cutSessions = cat(1, cutSessions, currentCutSessions);
                end
                % find out which cut files are missed and autodetect them
                [~, missedSessionsInd] = setdiff(sessionNames, cutSessions);
                knownCuts = cell(size(sessionNames, 1), 1);
                ind = true(numSessions, 1);
                ind(missedSessionsInd) = false;
                knownCuts(ind) = cutFiles(t, :);
                for s = 1:length(missedSessionsInd)
                    ind = missedSessionsInd(s);
                    sessionName = sessionNames{ind};
                    cutFile = fullfile(sessionData.path, sprintf('%s_%u.cut', sessionName, tetrodes(t)));
                    if exist(cutFile, 'file') ~= 0
                        knownCuts{ind} = cutFile;
                    end
                end
                cutFiles(t, 1:length(knownCuts)) = knownCuts;
            end
        end
    end
    
    for i = 1:length(tetrodesToDelete)
        badInd = sessionData.units(:, 1) == tetrodesToDelete(i);
        sessionData.units(badInd, :) = [];
    end
    if isempty(cutFiles)
        return;
    end
    badInd = cellfun(@(x) isempty(x), cutFiles(:, 1));
    cutFiles(badInd, :) = [];

    sessionData.cuts = cutFiles;

    % let's see if we need to do cell auto-detection
    tetrodes = unique(sessionData.units(:, 1), 'stable');
    for t = 1:length(tetrodes)
        tetrodeIndices = sessionData.units(:, 1) == tetrodes(t);
        tetrodeCells = sessionData.units(tetrodeIndices, 2);
        
        if isnan(tetrodeCells(1))
            tetrodeCutData = [];
            for cc = 1:size(cutFiles, 2)
                if ~isempty(cutFiles{t, cc}) && exist(cutFiles{t, cc}, 'file') ~= 0
                    tmpCutData = io.axona.getCut(cutFiles{t, cc});

                    % in case of combined sessions and a single cut file for them,
                    % indices in tmpCutData are linear, but they are not linear in gBntData.spikes.
                    % so accumulate all the spikes and put it into .spikes later
                    tetrodeCutData = cat(1, tetrodeCutData, tmpCutData);
                end
            end
            if isempty(tetrodeCutData)
                error('Failed to find a cut file for tetrode %u, first session %s', tetrodes(t), sessionData.sessions{1});
            end
            
            sessionData.units(tetrodeIndices, :) = [];
            presentCells = unique(tetrodeCutData);
            presentCells(presentCells == 0) = [];
            presentCells = presentCells(:); % make it a column
            tetrodeUnits = [tetrodes(t)*ones(length(presentCells), 1) presentCells];
            sessionData.units = cat(1, sessionData.units, tetrodeUnits);
        end
    end
end