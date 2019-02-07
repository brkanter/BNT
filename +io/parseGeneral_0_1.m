% Parse general input file version 0.1
%
function trials = parseGeneral_0_1(fid)
    trials = cell(1000, 1);
    numTrials = 0;
    numCells = 0;
    units = nan(60, 2);

    while ~feof(fid)
        str = strtrim(fgets(fid));

        if ~isempty(regexpi(str, '^sessions')) % match sessions word in the beginning of the str
            % extract sessions
            numTrials = numTrials + 1;
            numCells = 0;

            trials{numTrials} = helpers.initTrial();

            session = strtrim(str(length('Sessions '):end));
            session = readMultipleValues(fid, session);

            sessionNames = textscan(session, '%s', 'Delimiter', ',');
            sessionNames = sessionNames{1};
            trials{numTrials}.sessions = sessionNames;

            if isempty(trials{numTrials}.sessions)
                error('Found no sessions in the input file. Check your input file.');
            end
        elseif ~isempty(regexpi(str, '^cuts'))
            % extract cut data
            cutString = strtrim(str(length('cuts '):end));
            cutString = readMultipleValues(fid, cutString);
            if isempty(cutString)
                error('BNT:badCuts', 'Found no cut information in the input file. Check your input file.');
            end
            allCuts = textscan(cutString, '%s', 'Delimiter', ';');
            allCuts = allCuts{1};

            for t = 1:length(allCuts)
                tetCutNames = textscan(allCuts{t}, '%s', 'Delimiter', ',');
                tetCutNames = tetCutNames{1}';

                trials{numTrials}.cuts(t, 1:length(tetCutNames)) = tetCutNames;
            end

            if isempty(trials{numTrials}.cuts)
                % this will most likely never happen
                error('BNT:badCuts', 'Found no cut information in the input file. Check your input file.');
            end
        elseif ~isempty(regexpi(str, '^units'))
            if ~isempty(trials{numTrials}.units)
                warning('BNT:multipleUnits', 'Your input file contains multiple Units key-word for a single trial (trial #%u). You should use only one. The very first is going to be used.', numTrials);
                continue;
            end
            unitsStr = strtrim(str(length('units '):end));
            unitsStr = readMultipleValues(fid, unitsStr);

            allUnits = textscan(unitsStr, '%s', 'Delimiter', ';');
            allUnits = allUnits{1};
            for i = 1:length(allUnits)
                tmpUnits = textscan(allUnits{i}, '%u');
                tmpUnits = tmpUnits{1};

                % numCells+1 because we use zero-based index;
                % length(tmpUnits)-1, because we do not use the first element (tetrode);
                startIdx = numCells+1;
                endIdx = (startIdx-1) + length(tmpUnits)-1;
                units(startIdx:endIdx, 1) = tmpUnits(1);
                units(startIdx:endIdx, 2) = tmpUnits(2:end);

                numCells = numCells + length(tmpUnits)-1;
            end

            trials{numTrials}.units = units(1:numCells, :);
            trials{numTrials}.tetrode = unique(trials{numTrials}.units(:, 1));
            trials{numTrials}.tetrode = trials{numTrials}.tetrode(1);
        elseif ~isempty(regexpi(str, '^room'))
            trials{numTrials}.extraInfo.room = str;
        elseif ~isempty(regexpi(str, '^shape'))
            if isfield(trials{numTrials}.extraInfo, 'shape')
                warning('BNT:multipleShape', 'Your input file contains multiple Shape key-word for a single trial (trial #%u). You should use only one. The very first is going to be used.', numTrials);
                continue;
            end

            trials{numTrials}.extraInfo.shape.descr = str; % shape is used to scale position data
            shapeInfo = strtrim(str(7:end));
            wp = strfind(shapeInfo, ' '); % ' ' is a delimeter between shape name and dimensions
            if isempty(wp)
                error('BNT:badShape', 'Failed to parse shape information (trial #%u). Must be box, cylinder, circle or track', numTrials);
            end

            arenaType = shapeInfo(1:wp-1);

            if strcmpi(arenaType, 'box')
                trials{numTrials}.extraInfo.shape.type = bntConstants.ArenaShape.Box;
                trials{numTrials}.extraInfo.shape.value = sscanf(shapeInfo(5:end), '%f');
            elseif strcmpi(arenaType, 'track')
                trials{numTrials}.extraInfo.shape.type = bntConstants.ArenaShape.Track;
                trials{numTrials}.extraInfo.shape.value = sscanf(shapeInfo(7:end), '%f');
            elseif strcmpi(arenaType, 'circle')
                trials{numTrials}.extraInfo.shape.type = bntConstants.ArenaShape.Circle;
                trials{numTrials}.extraInfo.shape.value = sscanf(shapeInfo(8:end), '%f');
            elseif strcmpi(arenaType, 'cylinder')
                trials{numTrials}.extraInfo.shape.type = bntConstants.ArenaShape.Cylinder;
                trials{numTrials}.extraInfo.shape.value = sscanf(shapeInfo(10:end), '%f');
            else
                error('BNT:badShape', 'Failed to parse shape information (trial #%u). Must be box, cylinder, circle or track', numTrials);
            end
        end
    end

    trials = trials(1:numTrials)';
end

% Read multiple values from input file. Used to read values in format:
% Name Value1;
%  Value2;
%  Value..N;
%
% Outputs a string 'Value1; Value2; Value..N;'
%
% If the input file contains only single value (or value on the same line),
% then initialValue is returned. Consider the case:
% Name Value1;
% AnotherName Value;
%
function values = readMultipleValues(fid, initialValue)
    values = initialValue;

    while ~feof(fid)
        pos = ftell(fid);
        str = deblank(fgets(fid));
        if str(1) ~= ' '
            fseek(fid, pos, 'bof');
            break;
        end
        if isempty(strfind(str, ';'))
            if ~isempty(str)
                values = strcat(values, [',' str]); % cat with , in case we have paths with space in them
            end
        else
            if isempty(strfind(values(end-1:end), ';'))
                values = strcat(values, [',' str]); % if initial value doesn't contain ;, then most likely we are parsing joint cut files
            else
                values = strcat(values, str);
            end
        end
    end
end
