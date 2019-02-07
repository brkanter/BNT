function readGeneralInput(filename)
    global gBntData;

    trials = io.parseGeneralFile(filename);

    gBntData = cell(1, 1);

    for i = 1:length(trials)
        trial = trials{i};

        oldMatFiles = false;

        fprintf('Reading trial #%u out of %u\n', i, length(trials));

        gBntData{i} = trial;

        gBntData{i}.extraInfo = trial.extraInfo;
        gBntData{i}.sessions = trial.sessions;
        gBntData{i}.cuts = trial.cuts;
        gBntData{i}.units = trial.units;
        gBntData{i}.lfpChannels = trial.lfpChannels;
        
        doTetrodeDetection = false;

        %% do the inheritance check
        % units
        if isempty(trial.units)
            if trial.inheritUnits
                if i > 1
                    gBntData{i}.units = gBntData{i-1}.units;
                end
            else
                doTetrodeDetection = true;
            end
        end        
        % shape info
        if ~isfield(gBntData{i}.extraInfo, 'shape')
            if i > 1 && isfield(gBntData{i-1}.extraInfo, 'shape')
                gBntData{i}.extraInfo.shape = gBntData{i-1}.extraInfo.shape;
            end
        end
        if ~isfield(gBntData{i}.extraInfo, 'subjectId')
            if i > 1 && isfield(gBntData{i-1}.extraInfo, 'subjectId')
                gBntData{i}.extraInfo.subjectId = gBntData{i-1}.extraInfo.subjectId;
            end
        end

        gBntData{i}.sessions = cellfun(@normalizePath, gBntData{i}.sessions, 'uniformOutput', false);

        %% continue loading
        [baseFolder, firstName] = helpers.fileparts(gBntData{i}.sessions{1});
        gBntData{i}.basename = firstName;
        gBntData{i}.path = baseFolder;

        if length(gBntData{i}.sessions) > 1
            if length(gBntData{i}.sessions) >= size(gBntData{i}.cuts, 2)
                [~, lastName] = helpers.fileparts(gBntData{i}.sessions{end});
                gBntData{i}.basename = strcat(firstName, '+', lastName(end-1:end));
            end
        end
        gBntData{i} = io.detectRecordingSystem(gBntData{i});
        if isnan(gBntData{i}.system(1)) || strcmpi(gBntData{i}.system, bntConstants.RecSystem.Neuralynx)
            gBntData{i}.path = gBntData{i}.sessions{1};
            baseFolder = gBntData{i}.path;
        end
        
        if exist(baseFolder, 'dir') == 0
            error('BNT:noDataFolder', 'Can not find specified data folder. Check that it is written correctly. Your input:\n\t%s', baseFolder);
        end
        
        if isnan(gBntData{i}.system(1))
            % handle already converted data
            matFile = fullfile(baseFolder, sprintf('%s_pos.mat', gBntData{i}.basename));
            if exist(matFile, 'file') ~= 0
                tmp = load(matFile);
                if isfield(tmp, 'recSystem')
                    oldMatFiles = true;
                    switch lower(tmp.recSystem)
                        case 'axona'
                            gBntData{i}.system = bntConstants.RecSystem.Axona;
                            gBntData{i}.sampleTime = 0.02; % 50 Hz
                            gBntData{i}.videoSamplingRate = 50;

                        case 'neuralynx'
                            gBntData{i}.system = bntConstants.RecSystem.Neuralynx;
                            gBntData{i}.sampleTime = 0.04; % 25 Hz
                            gBntData{i}.videoSamplingRate = 25;
                            gBntData{i}.path = gBntData{i}.sessions{1};
                    end
                end
            end

            if isnan(gBntData{i}.system)
                error('Failed to identify recording system. Please fix your input file.\nFirst session of that trial: %s', gBntData{i}.sessions{1});
            end
        else
            if doTetrodeDetection
                detectTetrodes(i);
            end
            gBntData{i} = io.initCuts(gBntData{i});
        end
        
        %%
        [loaded, sessionData] = io.checkAndLoad(gBntData{i});
        if loaded
            fprintf('Yes, have successfully loaded data from cache\n');
            gBntData{i} = sessionData;
            continue;
        end

        if helpers.isstring(gBntData{i}.system, bntConstants.RecSystem.Axona, bntConstants.RecSystem.Virmen)
            io.axona.loadData(i);
        elseif strcmpi(gBntData{i}.system, bntConstants.RecSystem.Neuralynx)
            io.neuralynx.loadData(i);
        else
            error('Unknown recording system %s. Not implemented.\nFirst sesion of that trial: %s', gBntData{i}.system, gBntData{i}.sessions{1});
        end

        if ~oldMatFiles
            try
                data.saveTrial(i);
            catch ME
                % do not save if can not. Perhaps we are working with archive data.
                fprintf('Failed to save Matlab files. Perhaps you do not have write permissions to that directory.\nNot much to worry about\n');
            end
        end
    end
end

% normalize path by removing file separators at the end
function x = normalizePath(x)
    if x(end) == '\' || x(end) == '/'
        x(end) = [];
    end
end

function detectSystem(baseFolder, baseName, i)
    global gBntData;
    
    % Find out if this is Axona or NeuraLynx data
    % In case of multiple sessions, assume that combined sessions have been recorded using the same system.
    % Thus, check only the first session.
    setCandidate = fullfile(baseFolder, sprintf('%s.set', baseName));
    if ~isempty(dir(setCandidate))
        % check if this is a Virmen virtual reality, which comes alongside of Axona
        virmenCandidate = fullfile(baseFolder, sprintf('%s*.vr', baseName));
        isVirmen = ~isempty(dir(virmenCandidate));
        if isVirmen
            gBntData{i}.system = bntConstants.RecSystem.Virmen;
            gBntData{i}.sampleTime = 0.0167;
            gBntData{i}.videoSamplingRate = 60; % Hz
        else
            gBntData{i}.system = bntConstants.RecSystem.Axona;
            gBntData{i}.sampleTime = 0.02; % 50 Hz
            gBntData{i}.videoSamplingRate = 50;
        end
    end

    if ~isempty(dir(fullfile(baseFolder, '*.nev'))) || size(dir(fullfile(baseFolder, '*.nvt')), 1) > 0 ...
        || size(dir(fullfile(gBntData{i}.sessions{1}, '*.nev')), 1) > 0 || size(dir(fullfile(gBntData{i}.sessions{1}, '*.nvt')), 1) > 0

        gBntData{i}.system = bntConstants.RecSystem.Neuralynx;
        gBntData{i}.sampleTime = 0.04; % 25 Hz
        gBntData{i}.videoSamplingRate = 25;
    end
end

function detectTetrodes(i)
    global gBntData;
    
    if helpers.isstring(gBntData{i}.system, bntConstants.RecSystem.Axona, bntConstants.RecSystem.Virmen)
        gBntData{i} = io.axona.detectTetrodes(gBntData{i});
    elseif strcmpi(gBntData{i}.system, bntConstants.RecSystem.Neuralynx)
        gBntData{i} = io.neuralynx.detectTetrodes(gBntData{i});
    end
end
