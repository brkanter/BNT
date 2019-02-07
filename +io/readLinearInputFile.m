% Read input file describing linear track data and load the data.
%
% Read an input file describing a particular setup of linear track
% recordings. The setup includes different started positions and was
% originally performed by Tale Litleré Bjerknes <talelitl@stud.ntnu.no>.
% An example input file is 'examples/linearInputFile.txt'.
% Extensive description of fields could be found in Wiki. Here is summary:
%  Name, version    Header used to define this file.
%  DataFolder       Folder with data recordings. Must be the first in a group!
%  TrackInfo        Path to the folder that contains recordings used to
%                   estimate track dimensions.
%  Units            List of units you are interested in. The list consist
%                   of groups, where each group define a tetrode and number
%                   of cells. The first value in a group corresponds to
%                   tetrode and the rest are for cells. Values are
%                   delimited by a space. Groups are delimited by a ';'.
%                   For example, string '7 1 2;8 3' defines two groups.
%                   The first one is for tetrode 7 and cells 1, 2. Second
%                   is for tetrode 8 and cell 3.
% Other lines are optional.
%
function readLinearInputFile(source, versionStr) %#ok<INUSD>
    global gBntData;

    if ischar(source)
        fid = data.safefopen(source, 'r');
        %lineCounter = 0;
    else
        fid = source;
    end

    curTrial = 0; % current trial in gBntData
    lastTrial = 0; % index of last trial in gBntData before we added new trials. Needed when we have DataFolder
    startPositions = zeros(1, 30); % vector that contains all the different start positions
    numExperiments = 0; % number of experiments. Experiment is a group of recording with different track length,
                        % but the same cells, i.e. cell 2 1 on track 200, 160, 110, 200.

    readMultipleValues = io.parseGeneralFile('getReadMultipleValues');
    % supported keywords in form of regexp
    exprKeywords = '^(trackinfo|units|datafolder)';
    % nLine = lineCounter; % current line in the input file, used for error indicators

    experimentData = struct('dataFolder', '', 'trackInfo', [], 'units', []);
    nextKeyword = '';

    while ~feof(fid)
        str = strtrim(fgets(fid));
        %nLine = nLine + 1;

        commentPos = strfind(str, '#');
        str(commentPos:end) = [];
        if isempty(str)
            continue;
        end

        if isempty(regexpi(str, exprKeywords))
            % skip lines with unknown format
            continue;
        end
        if ~isempty(nextKeyword) && isempty(regexpi(str, ['^' nextKeyword]))
            error('Next keyword must be %s, but ''%s'' is given.', nextKeyword, str);
        end

        if ~isempty(regexpi(str, '^DataFolder'))
            if numExperiments == 0
                numExperiments = numExperiments + 1;
            else
                if ~isempty(experimentData(numExperiments).dataFolder)
                    if numExperiments > 1 && isempty(experimentData(numExperiments).trackInfo)
                        % this is because we can skip TrackInfo
                        experimentData(numExperiments).trackInfo = experimentData(numExperiments-1).trackInfo;
                    end
                    numExperiments = numExperiments + 1;
                end
            end
            experimentData(numExperiments).dataFolder = strtrim(str(length('DataFolder '):end));
            nextKeyword = 'Units';

        elseif ~isempty(strfind(lower(str), lower('Units')))
            unitsStr = strtrim(str(length('Units '):end));
            allUnits = textscan(unitsStr, '%s', 'Delimiter', ';');
            allUnits = allUnits{1};
            numCells = 0;

            for i = 1:length(allUnits)
                tmpUnits = textscan(allUnits{i}, '%u');
                tmpUnits = double(tmpUnits{1});

                % numCells+1 because we use zero-based index;
                % length(tmpUnits)-1, because we do not use the first element (tetrode);
                startIdx = numCells+1;
                endIdx = (startIdx-1) + length(tmpUnits)-1;
                units(startIdx:endIdx, 1) = tmpUnits(1);
                units(startIdx:endIdx, 2) = tmpUnits(2:end);

                numCells = numCells + length(tmpUnits)-1;
            end
            units = units(1:numCells, :);

            if numExperiments == 0
                numExperiments = numExperiments + 1;
            else
                if ~isempty(experimentData(numExperiments).units)
                    if numExperiments > 1 && isempty(experimentData(numExperiments).trackInfo)
                        % this is because we can skip TrackInfo
                        experimentData(numExperiments).trackInfo = experimentData(numExperiments-1).trackInfo;
                    end
                    numExperiments = numExperiments + 1;
                end
            end
            experimentData(numExperiments).units = units;
            nextKeyword = '(TrackInfo|DataFolder)';

        elseif ~isempty(regexpi(str, '^TrackInfo'))
            if numExperiments == 0
                numExperiments = numExperiments + 1;
            else
                if isempty(experimentData(numExperiments).trackInfo)
                    if numExperiments > 1
                        experimentData(numExperiments).trackInfo = experimentData(numExperiments-1).trackInfo;
                    end
                end
                numExperiments = numExperiments + 1;
            end
            trackInfoFolder = strtrim(str(length('TrackInfo '):end));
            linearTrackPos = trackPosFolderAnalyzer(trackInfoFolder);
            experimentData(numExperiments).trackInfo = linearTrackPos;
            nextKeyword = 'DataFolder';
        end
    end % feof(fid)

    if numExperiments > 1 && isempty(experimentData(numExperiments).trackInfo)
        % this is because we can skip TrackInfo
        experimentData(numExperiments).trackInfo = experimentData(numExperiments-1).trackInfo;
    end

    for e = 1:length(experimentData)
        fprintf('Gathering information about experiment %u/%u...\n', e, length(experimentData));

        % we need to analyze the data folder and extract session information:
        % find out sessions with different starting positions
        sessionNames = cell(1, 50);
        numSessions = 0;
        lastStartPosition = 0;

        dataFolder = experimentData(e).dataFolder;
        linearTrackPos = experimentData(e).trackInfo;
        units = experimentData(e).units;

        % find out map <starting position> -> <session names>
        dirInfoSet = dir(fullfile(dataFolder, '*.set'));

        if isempty(dirInfoSet)
            error('BNT:noData', 'Failed to find any .set files in folder ''%s''', dataFolder);
        end

        lastTrial = curTrial;

        for i = 1:length(dirInfoSet)
            curName = dirInfoSet(i).name;
            underscopeInd = strfind(curName, '_');
            if isempty(underscopeInd)
                error('Failed to extract starting position from file name %s', curName);
            end
            [~, ~, ~, matches] = regexp(curName(underscopeInd+1:end), '\d*');
            if isempty(matches)
                error('Failed to extract starting position from file name %s', curName);
            end

            startPos = str2double(matches{1});
            if lastStartPosition == 0
                lastStartPosition = startPos;
            end

            if lastStartPosition ~= startPos
                curTrial = curTrial + 1;
                gBntData{curTrial} = helpers.initTrial();
                gBntData{curTrial}.system = bntConstants.RecSystem.Axona;
                gBntData{curTrial}.path = dataFolder;

                % Sort the arrays in alphabetical order, just to be sure
                gBntData{curTrial}.sessions = sort(sessionNames(1:numSessions));
                gBntData{curTrial}.startPos = lastStartPosition;
                gBntData{curTrial}.extraInfo.shape.type = bntConstants.ArenaShape.Track;
                gBntData{curTrial}.extraInfo.shape.value = gBntData{curTrial}.startPos;

                startPositions(curTrial) = lastStartPosition;

                lastStartPosition = startPos;
                numSessions = 0;
            end
            numSessions = numSessions + 1;
            sessionNames{numSessions} = strtok(curName, '.');

            if i == length(dirInfoSet)
                curTrial = curTrial + 1;
                gBntData{curTrial} = helpers.initTrial();
                gBntData{curTrial}.system = bntConstants.RecSystem.Axona;
                gBntData{curTrial}.path = dataFolder;

                % Sort the arrays in alphabetical order, just to be sure
                gBntData{curTrial}.sessions = sort(sessionNames(1:numSessions));
                gBntData{curTrial}.startPos = lastStartPosition;
                gBntData{curTrial}.extraInfo.shape.type = bntConstants.ArenaShape.Track;
                gBntData{curTrial}.extraInfo.shape.value = gBntData{curTrial}.startPos;

                startPositions(curTrial) = lastStartPosition;

                lastStartPosition = startPos;
                numSessions = 0;
            end
        end
        clear sessionNames;

        for i = lastTrial+1:curTrial
            gBntData{i}.units = units;
        end

        gatherExperiment(lastTrial+1, curTrial, linearTrackPos);
    end
end

% Analyzes the linear track position folder. This folder should contain
% tracked coordinates with the position of the linear track relative to the
% camera. These coordinates will be used to align the different session
% before the population vector analysis.
function linearTrackPos = trackPosFolderAnalyzer(trackPosFolder)

    % Locate position files in the folder
    searchStr = fullfile(trackPosFolder, '*.pos');
    dirInfo = dir(searchStr);

    % Array with the position values for the track
    % 1 row: Start position of track
    % 2 row: Start position of box at the end of the track
    % 3 row: End position of the box at the end of the track
    % 1 col: x-coordinate
    % 2 col: y-coordinate
    linearTrackPos = zeros(3, 2);

    % Number of files and directories in the data folder
    N = size(dirInfo, 1);

    if N < 3
        error('The linear track position folder doesn''t contain enough tracked data');
    end

    loaded = zeros(1,3);
    for f = 1:N
        if sum(loaded) == 3
            % All done
            break
        end

        if loaded(1) == 0
            if strcmpi(dirInfo(f).name,'start (200 cm).pos')
                % Load the data
                fName = fullfile(trackPosFolder, dirInfo(f).name);
                pos = io.axona.getPos(fName);
                posx = pos(:, bntConstants.PosX);
                posy = pos(:, bntConstants.PosY);

                % Use the median position as the position for the start of the
                % track
                linearTrackPos(1, 1) = nanmedian(posx);
                linearTrackPos(1, 2) = nanmedian(posy);

                loaded(1) = 1;
            end
        end

        if loaded(2) == 0
            if strcmpi(dirInfo(f).name, 'start of box (0 cm).pos')
                % Load the data
                fName = fullfile(trackPosFolder, dirInfo(f).name);
                pos = io.axona.getPos(fName);
                posx = pos(:, bntConstants.PosX);
                posy = pos(:, bntConstants.PosY);

                % Use the median position as the position for the start of the
                % box at the end of the track
                linearTrackPos(2, 1) = nanmedian(posx);
                linearTrackPos(2, 2) = nanmedian(posy);

                loaded(2) = 1;
            end
        end

        if loaded(3) == 0
            if strcmpi(dirInfo(f).name, 'end of box.pos')
                % Load the data
                fName = fullfile(trackPosFolder, dirInfo(f).name);
                pos = io.axona.getPos(fName);
                posx = pos(:, bntConstants.PosX);
                posy = pos(:, bntConstants.PosY);

                % Use the median position as the position for the start of the
                % track
                linearTrackPos(3, 1) = nanmedian(posx);
                linearTrackPos(3, 2) = nanmedian(posy);

                loaded(3) = 1;
            end
        end
    end
end

function gatherExperiment(trialsOffset, curTrial, linearTrackPos)
    global gBntData;

    startPositions = cellfun(@(x) x.startPos, gBntData(trialsOffset:curTrial));
    trackLengths = cellfun(@(x) x.extraInfo.shape.value, gBntData(trialsOffset:curTrial));

    % Calculate the conversion value for the position data
    % this is scale factor along X axis.
    trackLengthInPixels = linearTrackPos(2, 1) - linearTrackPos(1, 1);
    scale = max(trackLengths) / trackLengthInPixels;

    % find indices of repeated values. Assume, that there is only ONE
    % repeated value, which is repeated only ONCE.
    % An example of startPositions is [200 150 100 200]
    [n, bin] = histc(startPositions, unique(startPositions));
    multiple = find(n > 1);
    sameIndices = find(ismember(bin, multiple));
    if ~isempty(sameIndices) && length(sameIndices) ~= 2
        warning('Found strange things related to same value of starting positions, please check it.');
    end

    if length(sameIndices) == 2
        gBntData{trialsOffset + sameIndices(2) - 1}.startPosDescr = sprintf('%u''', gBntData{trialsOffset+sameIndices(2) - 1}.startPos);
    end

    gBntData{trialsOffset}.maxStartPos = nanmax(startPositions);
    gBntData{trialsOffset}.minStartPos = nanmin(startPositions);

    for i = trialsOffset:curTrial
        gBntData{i}.useHd = false;
        gBntData{i}.eegData = [];

        if ~isfield(gBntData{i}, 'startPosDescr')
            gBntData{i}.startPosDescr = sprintf('%u', gBntData{i}.startPos);
        end
        sp = gBntData{i}.startPos;

        if length(gBntData{i}.sessions) < 2
            error('Not enough session files for start position %u', sp);
        end

        [~, firstName] = fileparts(gBntData{i}.sessions{1});
        [~, lastName] = fileparts(gBntData{i}.sessions{end});
        underscopeInd = strfind(firstName, '_');
        underscopeLastnameInd = strfind(lastName, '_');
        gBntData{i}.basename = sprintf('%s-%s_%s', firstName(1:underscopeInd-1), lastName(underscopeLastnameInd-2:underscopeLastnameInd-1), ...
            firstName(underscopeInd+1:end));

        gBntData{i} = io.axona.detectAxonaCuts(gBntData{i});
        tetrodes = unique(gBntData{i}.units(:, 1), 'stable');

        [loaded, sessionData] = io.checkAndLoad(gBntData{i});
        if loaded
            gBntData{i} = sessionData;
            continue;
        end

        [gBntData{i}.positions, gBntData{i}.startIndices, gBntData{i}.spikes] = io.axona.loadPositionsAndSpikes(gBntData{i}.sessions, gBntData{i}.path, tetrodes);

        % filter positions. We need to leave only the positions that are on the
        % linear track. Remove everything which is before and after (in the box).
        % This is setup specific!
        for s = 1:length(gBntData{i}.startIndices)
            curStartIdx = gBntData{i}.startIndices(s);
            if s + 1 <= length(gBntData{i}.startIndices)
                curEndIdx = gBntData{i}.startIndices(s+1) - 1;
            else
                curEndIdx = size(gBntData{i}.positions, 1);
            end
            curPos = gBntData{i}.positions(curStartIdx:curEndIdx, :);

            % search for the last sample before the animal is constantly on the track.
            % This allows to remove jitter before animal starts to run on the track.
            validStartIdx = find(curPos(:, bntConstants.PosX) <= linearTrackPos(1, 1), 1, 'last');
            % first entrance in the box
            validEndIdx = find(curPos(:, bntConstants.PosX) >= linearTrackPos(2, 1), 1, 'first');
            if isempty(validStartIdx)
                validStartIdx = 0;
            end
            if isempty(validEndIdx)
                validEndIdx = size(curPos, 1) + 1;
            end
            curPos(1:validStartIdx, 2:end) = nan;
            curPos(validEndIdx:end, 2:end) = nan;

            validInterval = validStartIdx+1:validEndIdx-1;
            curPos(validInterval, bntConstants.PosX) = helpers.fixIsolatedData(curPos(validInterval, bntConstants.PosX));
            curPos(validInterval, bntConstants.PosY) = helpers.fixIsolatedData(curPos(validInterval, bntConstants.PosY));

            % interpolate valid positions
            xIdx = bntConstants.PosX;
            yIdx = bntConstants.PosY;
            [tmpPosx, tmpPosy] = general.interpolatePositions(curPos(validInterval, 1), ...
                [curPos(validInterval, xIdx) curPos(validInterval, yIdx)]);

            maxDiff = abs(nanmax(tmpPosx) - nanmax(tmpPosy));
            maxDiff_prev = abs(nanmax(curPos(validInterval, xIdx)) - nanmax(curPos(validInterval, yIdx)));
            diffPercentage = round(maxDiff / maxDiff_prev * 100);
            if maxDiff > 1000 || ((maxDiff > maxDiff_prev) && diffPercentage > 200)
                warning('BNT:positionInQuestion', 'Seems that the interpolation of position samples have failed. Will remove suspicious values.');
                minx = min(curPos(validInterval, xIdx));
                maxx = max(curPos(validInterval, xIdx));
                miny = min(curPos(validInterval, yIdx));
                maxy = max(curPos(validInterval, yIdx));
                badIndX = tmpPosx > maxx | tmpPosx < minx;
                badIndY = tmpPosy > maxy | tmpPosy < miny;
                tmpPosx(badIndX) = nan;
                tmpPosy(badIndY) = nan;
            end
            curPos(validInterval, xIdx) = tmpPosx;
            curPos(validInterval, yIdx) = tmpPosy;
            clear tmpPosx tmpPosy;

            if size(curPos, 2) > 3
                xIdx = bntConstants.PosX2;
                yIdx = bntConstants.PosY2;
                curPos(validInterval, xIdx) = helpers.fixIsolatedData(curPos(validInterval, xIdx));
                curPos(validInterval, yIdx) = helpers.fixIsolatedData(curPos(validInterval, yIdx));

                [tmpPosx, tmpPosy] = general.interpolatePositions(curPos(validInterval, 1), ...
                    [curPos(validInterval, xIdx) curPos(validInterval, yIdx)]);

                maxDiff = abs(nanmax(tmpPosx) - nanmax(tmpPosy));
                maxDiff_prev = abs(nanmax(curPos(validInterval, xIdx)) - nanmax(curPos(validInterval, yIdx)));
                diffPercentage = round(maxDiff / maxDiff_prev * 100);
                if maxDiff > 1000 || ((maxDiff > maxDiff_prev) && diffPercentage > 200)
                    warning('BNT:positionInQuestion', 'Seems that the interpolation of position samples have failed. Will remove suspicious values.');
                    minx = min(curPos(validInterval, xIdx));
                    maxx = max(curPos(validInterval, xIdx));
                    miny = min(curPos(validInterval, yIdx));
                    maxy = max(curPos(validInterval, yIdx));
                    badIndX = tmpPosx > maxx | tmpPosx < minx;
                    badIndY = tmpPosy > maxy | tmpPosy < miny;
                    tmpPosx(badIndX) = nan;
                    tmpPosy(badIndY) = nan;
                end
                curPos(validInterval, xIdx) = tmpPosx;
                curPos(validInterval, yIdx) = tmpPosy;
                clear tmpPosx tmpPosy;
            end

            gBntData{i}.positions(curStartIdx:curEndIdx, :) = curPos;
        end

        % let's load cluster data according to the tetrodes
        numCutData = 0;
        cutFiles = gBntData{i}.cuts;
        for t = 1:length(tetrodes)
            numCuts = sum(~cellfun('isempty', cutFiles(t, :)));
            tetrodeCutData = [];

            for cc = 1:numCuts
                fprintf('Loading cut file "%s"...', cutFiles{t, cc});
                tmpCutData = io.axona.getCut(cutFiles{t, cc});
                fprintf('done\n');

                % in case of combined sessions and a single cut file for them,
                % indices in tmpCutData are linear, but they are not linear in gBntData.spikes.
                % so accumulate all the spikes and put it into .spikes later
                tetrodeCutData = cat(1, tetrodeCutData, tmpCutData);

                numCutData = numCutData + length(tmpCutData);
            end
            if ~isempty(tetrodeCutData)
                tetrodeIndices = gBntData{i}.spikes(:, 2) == tetrodes(t);
                gBntData{i}.spikes(tetrodeIndices, 3) = tetrodeCutData;
            end
        end

        if numCutData ~= length(gBntData{i}.spikes(:, 2))
            msg = 'Length of the loaded cut data doesn''t match length of the loaded spike data';
            warning('BNT:cutLengthInvalid', msg);
            fprintf('%s\n', msg);
        end

        % For this particular project let's sort spikes according to tetrode number
        [~, sortedSpkIndices] = sort(gBntData{i}.spikes(:, 2));
        gBntData{i}.spikes = gBntData{i}.spikes(sortedSpkIndices, :);

        data.saveTrial(i);

        % scale positions
        gBntData{i}.positions(:, bntConstants.PosX) = (gBntData{i}.positions(:, bntConstants.PosX) - linearTrackPos(2, 1)) * scale;
        if size(gBntData{i}.positions, 1) > 3
            coveredLed1 = abs(nanmax(gBntData{i}.positions(:, bntConstants.PosY)) - nanmin(gBntData{i}.positions(:, bntConstants.PosY)));
            coveredLed2 = abs(nanmax(gBntData{i}.positions(:, bntConstants.PosY2)) - nanmin(gBntData{i}.positions(:, bntConstants.PosY2)));
            % use LED with greater 'coverage'
            if coveredLed1 > coveredLed2
                minY = nanmin(gBntData{i}.positions(:, bntConstants.PosY));
            else
                minY = nanmin(gBntData{i}.positions(:, bntConstants.PosY2));
            end
        else
            minY = min(gBntData{i}.positions(:, bntConstants.PosY));
        end

%         minY = min(gBntData{i}.positions(:, bntConstants.PosY));
        gBntData{i}.positions(:, bntConstants.PosY) = (gBntData{i}.positions(:, bntConstants.PosY) - minY) * scale;
        if size(gBntData{i}.positions, 1) > 3
            gBntData{i}.positions(:, bntConstants.PosX2) = (gBntData{i}.positions(:, bntConstants.PosX2) - linearTrackPos(2, 1)) * scale;
%             minY = nanmin(gBntData{i}.positions(:, bntConstants.PosY2));
            gBntData{i}.positions(:, bntConstants.PosY2) = (gBntData{i}.positions(:, bntConstants.PosY2) - minY) * scale;
        end

        % also save scaled positions
        posFile = helpers.uniqueFilename(gBntData{i}, 'posClean');
        p.distanceThreshold = 150; % default value
        p.maxInterpolationGap = 1; % [sec]
        info.distanceThreshold = p.distanceThreshold;
        info.maxInterpolationGap = p.maxInterpolationGap;
        info.allowScaling = false;
        info.filter = 'mean';
        info.meanFilterOrder = 15;
        info.filterSpan = 15;
        positions = gBntData{i}.positions; %#ok<NASGU>
        save(posFile, 'positions', 'info');
    end
end