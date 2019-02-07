% Initialize information about cut files
%
% This function detects which system (Axona/MClust) was used for cutting and processes
% information about cut files. The processing can include cut file autodetection.
% This function is used to decouple recording system from cut software.
%
function sessionData = initCuts(sessionData)
    sessionData.cutApp = bntConstants.CutApp.none;
    isMClustCuts = false;
    for e = 1:length(bntConstants.MClustExtensions)
        curExt = bntConstants.MClustExtensions{e};
        if ~isempty(dir(fullfile(sessionData.path, sprintf('*.%s', curExt))))
            isMClustCuts = true;
            break;
        end
    end
    isAxonaCuts = size(dir(sprintf('%s*.cut', sessionData.sessions{1})), 1) > 0; % NB! some versions of MClust can produce .cut files
    isAxonaCuts = isAxonaCuts | ~isempty(dir(fullfile(sessionData.path, sprintf('*%s*.cut', sessionData.basename))));
    isAxonaCuts = isAxonaCuts | ~isempty(dir(fullfile(sessionData.path, '*.cut')));
    isDbMaker = ~isempty(dir(sprintf('%s_T*C*.mat', sessionData.sessions{1})));
    
    if isDbMaker
        matFile = strcat(sessionData.sessions{1}, '_pos.mat');
        if exist(matFile, 'file')
            t = load(matFile);
            if isfield(t, 'recSystem')
                sessionData.cuts = {'*_T%uC%u.mat'};
                sessionData.cutApp = bntConstants.CutApp.mclust;
                return;
            end
        end
    end

    if ~isMClustCuts && ~isAxonaCuts
        if isempty(sessionData.cuts)
            error('BNT:badCuts', 'There is no cut information in the input file, and I''ve failed to guess any cut files. Check in your input file that data paths are correct.');
        end
        % Run both
        sessionData = io.axona.detectAxonaCuts(sessionData);
        sessionData = io.detectMClustCuts(sessionData);
        if isempty(sessionData.cutHash)
            error('BNT:badCuts', 'There is cut information in the input file, but I''ve failed to load it (find any cut files). Check in your input file that data paths are correct.');
        end
    end

    sessionDataTint = sessionData;
    sessionDataMclust = sessionData;
    if isAxonaCuts
        sessionDataTint = io.axona.detectAxonaCuts(sessionData);
        sessionDataTint = io.axona.calculateCutHashes(sessionDataTint);
    end
    if isMClustCuts
        sessionDataMclust = io.detectMClustCuts(sessionData);
    end
    
    if isAxonaCuts && isMClustCuts
        % support loading from only one system
        if isempty(sessionDataTint.units)
            sessionData = sessionDataMclust;
        elseif isempty(sessionDataMclust.units)
            sessionData = sessionDataTint;
        else
            % We are in bad situation
            % however
            if isequaln(sessionDataTint, sessionDataMclust)
                sessionData = sessionDataTint;
            else
                tetrodesOriginal = unique(sessionData.units(:, 1), 'stable');
                tetrodesAxona = unique(sessionDataTint.units(:, 1), 'stable');
                tetrodesMclust = unique(sessionDataMclust.units(:, 1), 'stable');
                if isequaln(tetrodesOriginal, tetrodesAxona) && isequaln(tetrodesOriginal, tetrodesMclust)
                    error('BNT:io:cutAmbiguity', ['Found cut files of Tint and MClust in %s', ...
                        ' which both seem to provide some information. I am not', ...
                        ' sure what to do now, so please fix it and leave ',...
                        'only cut files that you would like to use'], sessionData.sessions{1});
                elseif isequaln(tetrodesOriginal, tetrodesAxona)
                    sessionData = sessionDataTint;
                else
                    sessionData = sessionDataMclust;
                end
            end
        end
    elseif isAxonaCuts
        sessionData = sessionDataTint;
    elseif isMClustCuts
        sessionData = sessionDataMclust;
    end
   
    % Let's check if we calculated hashes for all the cells
    cellLinearIndex = helpers.tetrodeCellLinearIndex(sessionData.units(:, 1), sessionData.units(:, 2));
    for i = 1:length(cellLinearIndex)
        curCell = cellLinearIndex(i);
        if ~sessionData.cutHash.isKey(curCell)
            error('BNT:noCutFile', 'Session: %s\nFailed to find cut file for cell T%uC%u\nCheck your input file and data.', ...
                sessionData.sessions{1}, sessionData.units(i, 1), sessionData.units(i, 2));
        end
    end
end