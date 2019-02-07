% Check existance of data in Matlab format and try to load it
%
% To speed-up loading data is saved in Matlab format. This function checks existance of
% such saved data and if there are corresponding files, then it tries to load them.
%
%  USAGE
%
%    [loaded, sessionData] = io.checkAndLoad(data)
%
%    data           Structure that describes the current trial. Normally gBntData{i}.
%    loaded         Boolean flag. If TRUE then data have been fully loaded. If FALSE
%                   some data is missing.
%    sessionData    Structure with loaded data. If loaded is TRUE this should
%                   replace data of input argument.
%

% Copyright (c) 2013 Vadim Frolov
function [loaded, sessionData] = checkAndLoad(data)
    doNormalLoad = true;
    sessionData = [];
    unitsAreDifferent = false;

    dataFile = helpers.uniqueFilename(data, 'data');
    if exist(dataFile, 'file')
        fprintf('Found data in Matlab format, will try to load it\n');
        load(dataFile); % contains sessionData

        if exist('cacheCreation', 'var') == 0 || ~helpers.isCacheValid(cacheCreation)
            % no variable 'cacheCreation' in dataFile. This is an old cache file, which
            % should be deleted
            deleteCache(data);

            loaded = false;
            return;
        end

        % check that it is the same session
        if strcmp(data.basename, sessionData.basename) == false
            loaded = false;
            return;
        end

        if ~isequal(data.units, sessionData.units)
            unitsAreDifferent = true;

            % check that tetrodes match
            dataTetrodes = sort(unique(data.units(:, 1)));
            sessionTetrodes = sort(unique(sessionData.units(:, 1)));
            if ~isequal(dataTetrodes, sessionTetrodes)
                loaded = false;
                return;
            end
        end

        % check that extra info is the same
        if isfield(sessionData.extraInfo, 'shape')
            if ~isequaln(data.extraInfo.shape, sessionData.extraInfo.shape)
                deleteCache(data);

                loaded = false;
                return;
            end
        end

        % correct path if data files are now in a new place
        if strcmp(data.path, sessionData.path) == 0
            sessionData.path = data.path;

            [cutRows, cutCols] = size(sessionData.cuts);
            for r = 1:cutRows
                for c = 1:cutCols
                    [cutFolder, cutName, cutExt] = fileparts(sessionData.cuts{r, c});
                    if isempty(cutExt)
                        newCutName = cutName;
                    else
                        newCutName = sprintf('%s.%s', cutName, cutExt);
                    end
                    
                    if isempty(cutFolder)
                        sessionData.cuts{r, c} = newCutName;
                    else
                        sessionData.cuts{r, c} = fullfile(data.path, newCutName);
                    end
                end
            end
            
            if strcmpi(sessionData.system, bntConstants.RecSystem.Neuralynx)
                sessionData.sessions = data.sessions;
            else
                for s = 1:length(sessionData.sessions)
                    [~, sesName] = helpers.fileparts(sessionData.sessions{s});
                    sessionData.sessions{s} = fullfile(data.path, sesName);
                end
            end

            % use cacheChreation from original file.
            save(dataFile, 'sessionData', 'cacheCreation');
        end

        if unitsAreDifferent
            % correct units
            sessionData.units = data.units;
        end

        % If set to TRUE, then will continue to load files normally. This means that
        % not all data have been previously converted to Matlab format.
        doNormalLoad = false;

        % get spikes
        spkOffset = 1;
        allSpikes = 0;
        sessionData.spikes = nan(10000, 3);
        if isempty(sessionData.tetrode)
            numCells = size(sessionData.units, 1);
        else
            numCells = size(sessionData.units, 2);
        end

        cellLinearInd = helpers.tetrodeCellLinearIndex(sessionData.units(:, 1), sessionData.units(:, 2));
        for u = 1:numCells
            unit = sessionData.units(u, :);
            cutDataFile = helpers.uniqueFilename(sessionData, 'cut', unit);
            if ~exist(cutDataFile, 'file')
                doNormalLoad = true;
                break;
            end
            load(cutDataFile); % loads cellTS, cutFileHash variables

            if exist('cutFileHash', 'var') == 0
                loaded = false;
                return;
            end

            passedHashes = data.cutHash(cellLinearInd(u));
            if ~isequal(cutFileHash(:, 2), passedHashes(:, 2)) %#ok<NODEF>
                loaded = false;
                return;
            end

            if ~isempty(cellTS)
                sessionData.spikes(spkOffset:spkOffset+length(cellTS) - 1, 1) = cellTS;
                if ~isempty(sessionData.tetrode)
                    sessionData.spikes(spkOffset:spkOffset+length(cellTS) - 1, 3) = unit;
                    sessionData.spikes(spkOffset:spkOffset+length(cellTS) - 1, 2) = sessionData.tetrode;
                else
                    sessionData.spikes(spkOffset:spkOffset+length(cellTS) - 1, 2) = unit(1);
                    sessionData.spikes(spkOffset:spkOffset+length(cellTS) - 1, 3) = unit(2);
                end
                spkOffset = spkOffset + length(cellTS);
                allSpikes = allSpikes + length(cellTS);
            end
        end

        if allSpikes > 0
            sessionData.spikes = sessionData.spikes(1:allSpikes, :);
        else
            % if there were no units, then it's weird, so do the normal load
            doNormalLoad = true;
        end
        
        if ~isfield(sessionData, 'lfpChannels') || isempty(sessionData.lfpChannels)
            sessionData.lfpChannels = data.lfpChannels;
            if ~isfield(sessionData, 'lfpInfo')
                loaded = false;
                return;
            end
            if isfield(data, 'lfpInfo')
                sessionData.lfpInfo = data.lfpInfo;
            end
        end
    end

    loaded = ~doNormalLoad;
end

function deleteCache(data)
    key = helpers.uniqueKey(data.basename, data.cuts);
    filePattern = fullfile(data.path, sprintf('%s_*_%s.mat', data.basename, key));
    if ~isempty(dir(filePattern))
        delete(filePattern); % delete _data, cells
    end
    
    processPosFile(helpers.uniqueFilename(data, 'pos'));
    processPosFile(helpers.uniqueFilename(data, 'posClean'));
end

% Check if position file was modified manually . If it was, then do not
% delete it.
function processPosFile(posFile)
    if exist(posFile, 'file')
        tt = load(posFile);
        if isfield(tt, 'info') && isfield(tt.info, 'manual') && tt.info.manual
            % do not delete
            warning('BNT:manualPos', 'BNT wanted to delete file %s, but it was created manually. Will not delete. Check that everything looks as it should be.', posFile);
        else
            delete(posFile);
        end
    end
end