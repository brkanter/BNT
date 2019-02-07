% Locate MClust file names from session data
%
% This function normalizes information about cut files. It tries to autodetect cut filename,
% when it is omitted from an input file. Several naming schemas are used for autodetection.
% The function also calculates hashes of provided/detected cut files and prepares everything
% what is needed to load cells.
% Note that MClust saves one file per cell.
%
function sessionData = detectMClustCuts(sessionData)
    numSessions = length(sessionData.sessions);
    cutFiles = sessionData.cuts;
    tetrodes = unique(sessionData.units(:, 1), 'stable');
    lastDetectedSession = -1; % ID of a session for which

    cutExt = 't*'; % must be without .; * - includes .t, .t32, .t64
    
%     cutPatternsWithCells = {'SC%u_%u', ...
%         'SC%u_%02u', ...
%         'TT%u_%u', ...
%         'TT%u_%02u', ...
%         '

    tetrodesToDelete = [];
    for t = 1:length(tetrodes)
        tetrode = tetrodes(t);
        selected = sessionData.units(:, 1) == tetrode;
        cells = sessionData.units(selected, 2);

        if ~isempty(cutFiles)
            if t <= size(cutFiles, 1)
                numCuts = sum(~cellfun('isempty', cutFiles(t, :)));
            else
                numCuts = 0;
            end
        else
            numCuts = 0;
        end

        if numCuts == 0 && (size(cutFiles, 1) > 0 && size(cutFiles, 1) == t-1) && length(tetrodes) > 1
            % inheritance of cut information
            searchDir = sessionData.sessions{1};
            cutCandidate = cutFiles{t-1, 1};
            [cutPath, cutCandidate] = helpers.fileparts(cutCandidate);
            if ~isempty(cutPath)
                searchDir = cutPath;
            end
            s = 1; % used in detectPattern
            if isnan(cells(1))
                shallBrake = detectPattern(cutCandidate);
            else
                numPerc = length(strfind(cutCandidate, '%'));
                if numPerc > 1
                    shallBrake = detectPattern(cutCandidate, cutCandidate);
                else
                    shallBrake = detectPattern(cutCandidate);
                end
            end
            if shallBrake && ~isempty(cutPath)
                cutFiles{t, 1} = fullfile(cutPath, cutFiles{t, 1});
            end
            if t <= size(cutFiles, 1)
                numCuts = sum(~cellfun('isempty', cutFiles(t, :)));
            else
                numCuts = 0;
            end
        end

        if numCuts == 0
            % autodetect for all sessions
            for s = 1:numSessions
                searchDir = sessionData.sessions{s};
                
                % use an ultimate naming schema
                detectPattern('*%u_*', '*%u_*%u');
            end
        end
        
        if t > size(cutFiles, 1) || isempty(cutFiles{t})
            tetrodesToDelete = cat(1, tetrodesToDelete, tetrode);
            continue;
        end

        for c = 1:size(cutFiles, 2)
            % go through all the provided cuts and check if only first part of the
            % pattern is provided
            if c > size(cutFiles, 2) || isempty(cutFiles{t, c})
                cutCandidate = cutFiles{t, 1};
            else
                cutCandidate = cutFiles{t, c};
            end
            if isempty(strfind(cutCandidate, '%'))
                [cutPath, cutCandidate] = helpers.fileparts(cutCandidate);
                for s = 1:numSessions
                    searchDir = sessionData.sessions{s};
                    if ~isempty(cutPath)
                        searchDir = cutPath;
                    end

                    % check with TT naming schema
                    shallBreak = detectPattern([cutCandidate '%u_*'], [cutCandidate '%u_%u']);
                    if shallBreak
                        continue;
                    end

                    shallBreak = detectPattern([cutCandidate '%u_*'], [cutCandidate '%u_%02u']);
                    if shallBreak
                        continue;
                    end

                    shallBreak = detectPattern(['*' cutCandidate '%u_*'], ['*' cutCandidate '%u_%u']);
                    if shallBreak
                        continue;
                    end

                    shallBreak = detectPattern(['*' cutCandidate '%u_*'], ['*' cutCandidate '%u_%02u']);
                    if shallBreak
                        continue;
                    end
                end
            end
        end

        if numCuts == numSessions
            % 1. single session, single cut
            % 2. multiple sessions, multiple cuts
            % do nothing
            searchDir = sessionData.sessions{1};
            [cutPath, cutCandidate] = helpers.fileparts(cutCandidate);
            if ~isempty(cutPath)
                searchDir = cutPath;
            end
        else
            % check that all sessions are covered
            sessionCoverage = false(1, numSessions);
            for s = 1:numSessions
                for c = 1:size(cutFiles, 2)
                    if c > size(cutFiles, 2) || isempty(cutFiles{t, c})
                        cutPattern = [cutFiles{t, 1} '.t*'];
                    else
                        cutPattern = [cutFiles{t, c} '.t*'];
                    end

                    % there should be no escape sequences, so remove them
                    cutPattern = strrep(cutPattern, '\', '\\');

                    cutCandidate = fullfile(sessionData.sessions{s}, sprintf(cutPattern, tetrode, cells(1)));
                    cutFile = dir(cutCandidate);
                    if isempty(cutFile)
                        cutCandidate = sprintf(cutPattern, tetrode, cells(1));
                        cutFile = dir(cutCandidate);
                    end
                    if ~isempty(cutFile)
                        sessionCoverage(s) = true;
                        tDir = helpers.fileparts(cutCandidate);
                        if s == 1
                            searchDir = tDir;
                        end
                        if ~strcmpi(tDir, searchDir)
                            searchDir = '';
                        end
                        break;
                    end
                end
            end
            if ~all(sessionCoverage)
                tetrodesToDelete = cat(1, tetrodesToDelete, tetrode);
                if ~isnan(cells(1))
                    % only output a warning if we do not do an auto-detection
                    warning('MClust: failed to find cut files for some sessions (tetrode: %u). Check your input file.\nFirst session:\n%s', tetrode, sessionData.sessions{1});
                end
            end
        end
    end
    if exist('searchDir', 'var') == 1 && isempty(searchDir)
        clear searchDir;
    end
    
    for i = 1:length(tetrodesToDelete)
        badInd = sessionData.units(:, 1) == tetrodesToDelete(i);
        sessionData.units(badInd, :) = [];
    end    
    if ~isempty(cutFiles)
        badInd = cellfun(@(x) isempty(x), cutFiles(:, 1));
        cutFiles(badInd, :) = [];
    end
    
    tetrodes = unique(sessionData.units(:, 1), 'stable');
    sessionData.cuts = cutFiles;

    hashOpt.Method = 'MD5';
    hashOpt.Input = 'file';

    for t = 1:length(tetrodes)
        if t > size(cutFiles, 1)
            error('Failed to find NeuraLynx cut files. Check your input file.');
        end
        for s = 1:numSessions
            madeAssignment = false;
            tetrodeCells = sessionData.units(sessionData.units(:, 1) == tetrodes(t), :);
            cellLinearInd = helpers.tetrodeCellLinearIndex(tetrodeCells(:, 1), tetrodeCells(:, 2));
            
            for j = 1:size(cutFiles, 2)
                if isempty(cutFiles{t, j})
                    cutPattern = [cutFiles{t, 1} '.t*'];
                else
                    cutPattern = [cutFiles{t, j} '.t*'];
                end
                % there should be no escape sequences, so remove them
                cutPattern = strrep(cutPattern, '\', '\\');

                for c = 1:length(cellLinearInd)
                    curCell = cellLinearInd(c);
                    cutCandidate = fullfile(sessionData.sessions{s}, sprintf(cutPattern, tetrodeCells(c, :)));
                    if exist('searchDir', 'var') == 1
                        % this uses latest searchDir, which should contain valid directory
                        cutCandidateAlt = fullfile(searchDir, sprintf(cutPattern, tetrodeCells(c, :)));
                        cutFileAlt = dir(cutCandidateAlt);
                    else
                        cutFileAlt = [];
                    end
                    cutFile = dir(cutCandidate);
                    onlyPattern = true;
                    if ~isempty(cutFile) && ~isempty(cutFileAlt) && ~strcmpi(sessionData.sessions(s), searchDir)
                        cutFile = cutFileAlt;
                        cutCandidate = cutCandidateAlt;
                        onlyPattern = false;
                    end
                    if isempty(cutFile)
                        cutCandidate = sprintf(cutPattern, tetrodeCells(c, :));
                        cutFile = dir(cutCandidate);
                        onlyPattern = false;
                    end

                    if length(cutFile) > 1
                        foundCells = cellfun(@(x) str2double(regexpi(x, '\d*', 'match')), {cutFile(:).name}, 'uniformOutput', false);
                        cellMatch = cellfun(@(x) length(x) > 1 && isequaln(x(1:2), tetrodeCells(c, :)), foundCells);
                        correctIdx = find(cellMatch);
                        if isempty(correctIdx)
                            error('BNT:noCutFile', 'MClust: failed to find cut file for units [%d %d], session %s.', tetrodeCells(c, 1), tetrodeCells(c, 2), sessionData.sessions{s});
                        end
                        if length(correctIdx) > 1
                            allCuts = sprintf('%s\n', cutFile(:).name);
                            warning('BNT:io:cutAmbiguity', 'MClust: found more than one possible cut file for cell T%uC%u (first one will be used), session %s.\nList of found cuts:\n%s', ...
                                tetrodeCells(c, 1), tetrodeCells(c, 2), sessionData.sessions{s}, allCuts);
                        else
                            cutFile = cutFile(correctIdx);
                        end
                    end
                    if isempty(cutFile)
                        % just break and test other cut entries/patterns
                        break;
                    end
                    
                    if onlyPattern
                        cutFile = fullfile(sessionData.sessions{s}, cutFile(1).name);
                    else
                        cutPath = helpers.fileparts(cutCandidate);
                        cutFile = fullfile(cutPath, cutFile(1).name);
                    end
                    fileHash = DataHash(cutFile, hashOpt);

                    madeAssignment = true;
                    newEntry = {cutFile fileHash s};
                    if sessionData.cutHash.isKey(curCell)
                        curData = sessionData.cutHash(curCell);
                        curData = cat(1, curData, newEntry);
                        sessionData.cutHash(curCell) = curData;
                    else
                        sessionData.cutHash(curCell) = newEntry;
                    end
                end
                if madeAssignment
                    break;
                end
            end
        end
    end
    
    cellLinearInd = helpers.tetrodeCellLinearIndex(sessionData.units(:, 1), sessionData.units(:, 2));
    unitsToDelete = false(size(sessionData.units, 1));
    for c = 1:size(sessionData.units, 1)
        curCell = cellLinearInd(c);        
        if ~sessionData.cutHash.isKey(curCell)
            unitsToDelete(c) = true;
        end
    end
    sessionData.units(unitsToDelete, :) = [];

    % nested function
    function shallBreak = detectPattern(pattern, patternWithCell)
        if nargin < 2
            patternWithCell = '';
        end
        shallBreak = false;
        patternWithExt = sprintf('%s.%s', pattern, cutExt);
        if isnan(cells(1))
            if isempty(patternWithCell)
                cutFilename = fullfile(searchDir, sprintf(patternWithExt, tetrode, cells(1)));
                cutFilename = strrep(cutFilename, 'NaN', '*');
                cutFilename = strrep(cutFilename, '**', '*'); % double start can appear 
                        % from NaN replacement and give error later on.
                patternWithCell = pattern;
            else
                cutFilename = fullfile(searchDir, sprintf(patternWithExt, tetrode));
            end
        else
            patternWithExt = sprintf('%s.%s', patternWithCell, cutExt);
            cutFilename = fullfile(searchDir, sprintf(patternWithExt, tetrode, cells(1)));
        end
        tFiles = dir(cutFilename);
        if ~isempty(tFiles)
            if isnan(cells(1))
                detectedCells = arrayfun(@(x) regexpi(x.name, '\d*', 'match'), tFiles, 'uniformoutput', false);
                if length(detectedCells) < 2
                    return;
                end
                detectedCells = cellfun(@(x) str2double(x{2}), detectedCells);

                sessionData.units(selected, :) = [];
                currentUnits = [ones(length(detectedCells), 1)*tetrode detectedCells];
                sessionData.units = cat(1, sessionData.units, currentUnits);
                selected = sessionData.units(:, 1) == tetrode;
                cells = sessionData.units(selected, 2);
            else
                %patternWithCell = pattern;
            end
         
            if s == 1
                cutFiles{t, s} = patternWithCell;
            end
            if s > 1 && (isempty(cutFiles) || ~strcmpi(patternWithCell, cutFiles{t, 1}))
                cutFiles{t, s} = patternWithCell;
            end
            shallBreak = true;
        end
    end
end
