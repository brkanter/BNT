% Read metadata from an input file in old format (created by Raymond).
%
% Read metadata from an input file in old format. The input file describes session data.
% This function also combines entries with same session names and cut files, but different cell
% numbers into one trial.
%
%  USAGE
%
%    trials = io.readRaymondInputFileMeta(source)
%    source       String or integer. Integer represents file identifier of openned file,
%                 string contains full path to the file.
%    trials       Vector of structs, where each structure represents one trial.
%                 For details about struct fields see also helpers.initTrial function.
%
%  SEE ALSO
%
%    See also helpers.initTrial, data.loadSessions
%
function trials = readRaymondInputFileMeta(source)
    if ischar(source)
        fid = data.safefopen(source, 'r');
    else
        fid = source;
    end

    fseek(fid, 0, 'bof');

    % Keep track of the line number the programs reads from in the input file
    currentLine = 0;

    trials = containers.Map('KeyType', 'char', 'ValueType', 'any');
    % original order of keys
    keyOrder = {};

    dataCounter = 0;

    while ~feof(fid)
        % Flag indicating if we are combining sessions into one big session. 0 =
        % single session, 1 = combined sessions with joint cut file, 2 =
        % combined session with separate cut files.
        combined = 0;

        % Read a line from the input file
        str = strtrim(fgets(fid));
        currentLine = currentLine + 1;

        % Check that line is not empty
        if isempty(str)
            error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
        end

        % Check that the line is the "session" line
        if length(str) < 7 || ~strcmpi(str(1:7), 'Session')
            error('Line %d: Expected keyword ''Session'' in the input file', currentLine);
        end

        dataCounter = dataCounter + 1;
        sessionCounter = 1;

        % Initialization ==>
        trial = helpers.initTrial();

        trial.tetrode = nan;
        trial.units = [];

        % Session base name. I.e. for single session '2103201101'. For combined sessions
        % it will be '2103201101+02'. More than two combined sessions are not supported.
        basename = '';

        % Session path
        path = '';

        % Extra information, structure. Could contain fields
        % room - string with information about recording room;
        % shape - struct with information about recording box shape, fields:
        %         descr - raw string from file
        %         type - integer. See helpers.ArenaShape
        %         value - double. Side length or diameter of the arena.
        % startTime - string
        trial.extraInfo = [];

        trial.sessions{sessionCounter} = str(9:end);

        fprintf('Reading information about session #%d\n', dataCounter);
        str = strtrim(fgets(fid));
        currentLine = currentLine + 1;
        if isempty(str)
            error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
        end

        if length(str) > 3 && strcmpi(str(1:3), 'cut')
            % Combined session with separate cut files
            combined = 2;

            trial.cuts{1} = str(5:end);

            str = fgets(fid);
            currentLine = currentLine + 1;
            str = strtrim(str);
            if isempty(str)
                error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
            end

            % Read session and cut info as long as there are more in the input
            % file
            getSess = 1;
            while 1
                if getSess % Session or room info expected next
                    if length(str) > 7 && strcmpi(str(1:7), 'Session')
                        sessionCounter = sessionCounter + 1;
                        trial.sessions(sessionCounter, 1) = {str(9:end)};
                        getSess = 0;
                        str = fgets(fid);
                    else
                        % No more sessions, continue
                        break;
                    end
                else % Cut info expected next
                    if length(str) > 3 && strcmpi(str(1:3), 'cut')
                        trial.cuts{sessionCounter} = str(5:end);
                        str = fgets(fid);
                        currentLine = currentLine + 1;
                        str = strtrim(str);
                        if isempty(str)
                            error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
                        end

                        getSess = 1;
                    else
                        error('Expected the ''cut'' keyword at line %u. Got line ''%s''', currentLine, str);
                    end
                end % if gestSess
            end % while
        end

        while length(str) > 7 && strcmpi(str(1:7), 'Session')
            % Sessions will be combined
            combined = 1;

            sessionCounter = sessionCounter + 1;
            trial.sessions(sessionCounter, 1) = {str(9:end)};

            % Read next line
            str = fgets(fid);
            currentLine = currentLine + 1;

            % Remove space at end of line
            str = strtrim(str);

            % Check that line is not empty
            if isempty(str)
                error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
            end
        end

        % some files could have 'Start' string afterwards. Support 'Start BL', 'Start AF', 'Start hh.mm.ss'
        if length(str) > 5 && strcmpi(str(1:5), 'Start')
            trial.extraInfo.startTime = str;

            % read next line
            str = strtrim(fgets(fid));
            currentLine = currentLine + 1;

            % Check that line is not empty
            if isempty(str)
                error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
            end
        end

        if combined == 1
            %Combined sessions with joint cut file detected

            % Get shared cut file for the combined sessions
            if length(str) > 3 && strcmpi(str(1:3), 'cut')
                trial.cuts{1} = str(5:end);

                % Read next line
                str = fgets(fid);
                currentLine = currentLine + 1;

                 % Remove space at end of line
                str = strtrim(str);

                % Check that line is not empty
                if isempty(str)
                    error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
                end
            else
                error('Expected the ''Cut'' keyword at line %d. Got line ''%s''', currentLine, str);
            end
        end

        trial.sessions = trial.sessions(1:sessionCounter);
        [path, name] = helpers.fileparts(trial.sessions{1});

        if combined > 0
            if combined == 1
                trial.cuts = trial.cuts(1);
            end
            [~, lastSesName] = helpers.fileparts(trial.sessions{sessionCounter});
            basename = strcat(name, '+', lastSesName(end-1:end));
        else
            if ~isempty(trial.cuts)
                trial.cuts = trial.cuts(1:sessionCounter);
            end
            basename = name;
        end

        trial.path = path;
        trial.basename = basename;

        if strcmpi(str(1:4), 'Room')
            % Found room information
            trial.extraInfo.room = str;
            str = strtrim(fgets(fid));
            currentLine = currentLine + 1;

            % Check that line is not empty
            if isempty(str)
                error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
            end
        end

        if strcmpi(str(1:5), 'Shape')
            % Found shape information
            trial.extraInfo.shape.descr = str;
            shapeInfo = str(7:end);
            if strcmpi(shapeInfo(1:3), 'box')
                trial.extraInfo.shape.type = bntConstants.ArenaShape.Box;
                trial.extraInfo.shape.value = str2double(shapeInfo(5:end));
            elseif strcmpi(shapeInfo(1:5), 'track')
                trial.extraInfo.shape.type = bntConstants.ArenaShape.Track;
                trial.extraInfo.shape.value = str2double(shapeInfo(7:end));
            elseif strcmpi(shapeInfo(1:6), 'circle')
                trial.extraInfo.shape.type = bntConstants.ArenaShape.Circle;
                trial.extraInfo.shape.value = str2double(shapeInfo(8:end));
            elseif strcmpi(shapeInfo(1:8), 'Cylinder')
                trial.extraInfo.shape.type = bntConstants.ArenaShape.Cylinder;
                trial.extraInfo.shape.value = str2double(shapeInfo(10:end));
            else
                error('Failed to parse shape information. Must be box, cylinder or track');
            end

            % Read next line
            str = strtrim(fgets(fid));
            currentLine = currentLine + 1;

            % Check that line is not empty
            if isempty(str)
                error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
            end
        end

        tetrode = nan;
        units = [];

        while ~feof(fid)
            if strcmp(str, '---') % End of this block of data, start over.
                break
            end
            if length(str) > 7
                if strcmpi(str(1:7), 'tetrode')
                    tetrode = sscanf(str, '%*s %u');

                    str = strtrim(fgets(fid));
                    currentLine = currentLine + 1;

                    if isempty(str)
                        error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
                    end

                    while length(str) > 4 && strcmpi(str(1:4), 'Unit')
                        unit = sscanf(str, '%*s %u');

                        units(end+1, 1) = tetrode;
                        units(end, 2) = unit;

                        str = fgets(fid);
                        if str == -1
                            % catch eof condition
                            break;
                        end
                        str = strtrim(str);
                        currentLine = currentLine + 1;

                        if isempty(str)
                            error('Empty line was found at line number %d. Input file can not have empty lines.', currentLine);
                        end
                    end
                else
                    error('Expected the ''Tetrode'' keyword at line %u. Got line ''%s''', currentLine, str);
                end
            else
                error('Expected the ''Tetrode'' keyword at line %u. Got line ''%s''', currentLine, str);
            end
        end % while ~feof(fid)

        allSessions = '';
        for i = 1:length(trial.sessions)
            [sessPath, sess2] = helpers.fileparts(trial.sessions{i});
            [~, sess1] = helpers.fileparts(sessPath);
            % Assume that data is always stored under directory structure
            % like <mouse_name>\<session>.
            allSessions = strcat(allSessions, [sess1 sess2]);
        end

        % Find out if this is Axona or NeuraLynx data
        % In case of multiple sessions, assume that combined sessions have been recorded using the same system.
        % Thus, check only the first session.
        if size(dir(fullfile(trial.path, '*.set')), 1) > 0 || size(dir(fullfile(trial.path, '*.pos')), 1) > 0
            trial.system = bntConstants.RecSystem.Axona;
            trial.sampleTime = 0.02; % 50 Hz
            trial.videoSamplingRate = 50;
        end

        if size(dir(fullfile(trial.path, '*.nev')), 1) > 0 || size(dir(fullfile(trial.path, '*.nvt')), 1) > 0 ...
            || size(dir(fullfile(trial.sessions{1}, '*.nev')), 1) > 0 || size(dir(fullfile(trial.sessions{1}, '*.nvt')), 1) > 0

            trial.system = bntConstants.RecSystem.Neuralynx;
            trial.sampleTime = 0.04; % 25 Hz
            trial.videoSamplingRate = 25;

            trial.path = trial.sessions{1};
        end

        if ~isfield(trial, 'system')
            posFile = sprintf('%s_pos.mat', trial.sessions{1});
            if exist(posFile, 'file') ~= 0
                posData = load(posFile);
                if strcmpi(posData.recSystem, 'axona')
                    trial.system = bntConstants.RecSystem.Axona;
                    trial.sampleTime = 0.02;
                    trial.videoSamplingRate = 50;
                else
                    trial.system = bntConstants.RecSystem.Neuralynx;
                    trial.sampleTime = 0.04; % 25 Hz
                    trial.videoSamplingRate = 25;

                    trial.path = trial.sessions{1};
                end
            else
                error('Failed to determine recording system for session located at %s', trial.path);
            end
        end

        % get a unique key from all session names
        key = helpers.uniqueKey(allSessions, []);

        % check the existance of a trial with such a key
        if trials.isKey(key)
            savedTrial = trials(key);

            % NB! we do not handle situation when one cut file describes several tetrodes.

            [~, indInSavedTrial, indInCurTrial] = intersect(savedTrial.units, units, 'rows');
            if ~isempty(indInSavedTrial)
                warning('BNT:warn:identicalUnits', 'You are trying to load identical tetrodes with different cut files. This is not supported! Will skip current trial.');

                units(indInCurTrial, :) = [];
                trial.cuts(indInCurTrial, :) = [];
            end

            trialTetrodes = unique(units(:, 1), 'stable');
            savedTrialTetrodes = unique(savedTrial.units(:, 1), 'stable');
            for i = 1:length(trialTetrodes)
                ind = find(savedTrialTetrodes == trialTetrodes(i), 1);
                if ~isempty(ind)
                    if ind(1) > size(savedTrial.cuts, 1)
                        continue;
                    end
                    if i > size(trial.cuts, 1)
                        continue;
                    end

                    tmpCuts = savedTrial.cuts(ind(1), :);
                    numCuts = 0; % find first non-empty index in a current row of cuts
                                 % This is for case, when another tetrode
                                 % has more cut files than this one, i.e. if 'end' is used, then
                                 % we would create gaps in data.
                    for tt = 1:length(tmpCuts)
                        if ~isempty(tmpCuts{tt})
                            numCuts = numCuts + 1;
                        else
                            break;
                        end
                    end

                    noTmpCuts = true;
                    for tt = 1:length(tmpCuts)
                        noTmpCuts = noTmpCuts & isempty(tmpCuts{tt});
                    end
                    noTrialCuts = true;
                    for tt = 1:length(trial.cuts(i, :))
                        noTrialCuts = noTrialCuts & isempty(trial.cuts{i, tt});
                    end
                    if noTrialCuts || noTmpCuts
                    else
                        [~, ~, indCuts] = intersect(tmpCuts, trial.cuts(i, :)); % there could be several tetrodes in trial
                        for tt = 1:length(trial.cuts(i, :))
                            if ~isempty(find(indCuts == tt, 1))
                                continue;
                            end

                            savedTrial.cuts{ind(1), numCuts + 1} = trial.cuts{tt};
                            numCuts = numCuts + 1;
                        end
                    end
                else
                    % there are no such tetrode in savedTrial

                    numTetrodes = size(savedTrial.cuts, 1);
                    for c = 1:length(trial.cuts(i, :))
                        savedTrial.cuts{numTetrodes + 1, c} = trial.cuts{i, c};
                    end
                end
            end

            % add new units
            savedTrial.units = [savedTrial.units; units];

            % actually, we shouldn't use field tetrode at all.
            % TODO: try to get rid of tetrode, use units instead.
            if length(unique(savedTrial.units(:, 1))) > 1
                savedTrial.tetrode = [];
            end

            % remove duplicates
            trials(key) = savedTrial;
        else
            trial.tetrode = tetrode;
            trial.units = units;

            trials(key) = trial;
            keyOrder{end+1} = key;
        end
    end % while ~feof(fid)

    trials = values(trials, keyOrder);
end
