% Get position samples
%
% This function returns internally-stored position data of a current trial.
%
%  USAGE
%
%    positions = data.getPositions(<options>)
%
%    <options>      optional list of property-value pairs (see table below)
%
%    =========================================================================
%     Properties    Values
%    -------------------------------------------------------------------------
%     'mode'        'all' gets all position samples, 'clean' discards bad position samples (lights
%                   undetected, out of boundaries, too close, etc.) (default 'clean')
%     'scale'       'on' scale positions if shape information is present.
%                   'off' do not scale. (default 'on')
%     'params'      Optional parameters structure. Fields are:
%                   distanceThreshold - Threshold of how far an animal can move from one position
%                                       to another. Integer value, units are cm. Default value is 150 cm.
%                   maxInterpolationGap
%                   posStdThreshold
%     'average'     'on' - if there are positions of 2 LEDs, then they are averaged. Returned matrix
%                   is of size Nx3.
%                   'off' - position data is returned as is. Returned matrix is of size Nx5.
%                   Default is 'on'.
%     'speedFilter' Vector with two elements. First element specifies lower bound of the speed
%                   threshold. Second element specifies upper bound of the speed threshold.
%                   See general.speedThreshold function for details. Default value is [0 0], which
%                   means no threshold.
%     'filter'      String specifying smoothing filter for position data. Possible values are:
%                   'off'   - no filtering is performed.
%                   'mean'  - median filter by Matlab function medfilt1. Default order is 15.
%                   'lowess'- local regression using weighted linear least squares and a 1st degree polynomial model.
%                             See Matlab's smooth function for details.
%                             Default span is 0.5 sec, which is 25 samples for Axona and 13 for NeuraLynx.
%                   Default is 'mean'.
%    =========================================================================
%
%    positions      Matrix with position samples. Data is organized column-based and general
%                   structure is [t x1 y1 x2 y2], where t timestamps, x1 y1 data of LED1, x2 y2 data
%                   of LED2. If 'average' is 'on', then the resulting matrix is in form [t x y].
%
%  EXAMPLES
%
%    p = data.getPositions;
%    p = data.getPositions('mode', 'all');
%
function positions = getPositions(varargin)
    global gBntData;
    global gCurrentTrial;

    if mod(length(varargin), 2) ~= 0
        error('Incorrect number of parameters (type ''help <a href="matlab:help data.getPositions">data.getPositions</a>'' for details).');
    end

    if nargout < 1
        return;
    end
    if isempty(gBntData)
        error('BNT:notLoaded', 'You should load some data first.');
    end

    % default parameters
    defaultMode = 'clean';
    defaultScale = 'on';
    % Treshold for how far a rat can move (150cm/s), in one sample
    defaultParams.distanceThreshold = 150;

    % Set the maximum time gap in the position data that should be
    % interpolated. If there is gaps with durtion longer than this the samples
    % will be left as NaN.
    defaultParams.maxInterpolationGap = 1; % [sec]

    % The could be outliers in tracked position samples. These are commonly several
    % values between longer list of NaNs. Thy lie far away from 'good' points, so
    % we discard everything that is further away than p.posStdThreshold*STD. If your
    % data is somehow truncated strangely, then try to increase this threshold.
    % Default value is 2.5
    defaultParams.posStdThreshold = 2.5;

    defaultAverage = 'on';
    defaultSpeedFilter = [0 0];
    defaultMeanFilterOrder = 15;
    meanFilterOrder = 15;  % 15 is just to make it a bit more smoother.
    defaultFilter = 'mean';

    checkMode = @(x) helpers.isstring(x, 'all', 'clean');
    checkFlag = @(x) helpers.isstring(x, 'on', 'off');
    checkSpeedFilter = @(x) length(x) == 2 && helpers.isdvector(x, '>=0');
    checkParams = @(x) isstruct(x) && isfield(x, 'distanceThreshold') && ...
            isfield(x, 'maxInterpolationGap') && isfield(x, 'posStdThreshold');
    checkFilter = @(x) helpers.isstring(x, 'mean', 'off', 'lowess');

    inp = inputParser;
    addParameter(inp, 'mode', defaultMode, checkMode);
    addParameter(inp, 'scale', defaultScale, checkFlag);
    addParameter(inp, 'average', defaultAverage, checkFlag);
    addParameter(inp, 'speedFilter', defaultSpeedFilter, checkSpeedFilter);
    addParameter(inp, 'params', defaultParams, checkParams);
    addParameter(inp, 'filter', defaultFilter, checkFilter);
    parse(inp, varargin{:});

    % get parsed results
    mode = inp.Results.mode;
    scale = inp.Results.scale;
    p = inp.Results.params;
    average = inp.Results.average;
    speedFilter = inp.Results.speedFilter;
    filterToUse = inp.Results.filter;
    % in some cases we should not allow scaling, because positions have
    % been scaled allready.
    allowScaling = true;

    if ~isfield(gBntData{gCurrentTrial}, 'positions') || isempty(gBntData{gCurrentTrial}.positions)
        % try to load data from disc, lazzy loading
        posDataFile = helpers.uniqueFilename(gBntData{gCurrentTrial}, 'pos');
        pos = load(posDataFile);
        gBntData{gCurrentTrial}.positions = pos.positions;

        clear pos;
    end
    positions = gBntData{gCurrentTrial}.positions;
    if isempty(positions), return; end

    % check for identical values
    badTime = find(diff(positions(:, 1)) == 0);
    if ~isempty(badTime)
        % Seems like Axona has this very often, do not issue the warning because it will show up too often.
        % And it is nothing to do about such Axona recordings.
        positions(badTime, :) = [];
    end

    originalThreshold = p.distanceThreshold;
    p.distanceThreshold = p.distanceThreshold / gBntData{gCurrentTrial}.videoSamplingRate;

    if isfield(gBntData{gCurrentTrial}, 'posCleanScale')
        gBntData{gCurrentTrial} = rmfield(gBntData{gCurrentTrial}, 'posCleanScale');
    end

    filterSpan = 0;
    if strcmpi(filterToUse, 'mean')
        % no adjucement for sampling rate due to historical reasons
        filterSpan = meanFilterOrder;
    elseif strcmpi(filterToUse, 'lowess')
        % 0.5 sec is the default lowess span
        filterSpan = round(gBntData{gCurrentTrial}.videoSamplingRate * 0.5);
    end

    decodeNeuralynx = strcmp(average, 'off') && strcmpi(gBntData{gCurrentTrial}.system, bntConstants.RecSystem.Neuralynx);

    if strcmp(mode, 'clean') && ~decodeNeuralynx
        if isfield(gBntData{gCurrentTrial}, 'posClean')
            % we already have cleaned data. Check it and return.
            checks(1) = gBntData{gCurrentTrial}.posCleanInfo.distanceThreshold == originalThreshold;
            checks(2) = gBntData{gCurrentTrial}.posCleanInfo.maxInterpolationGap == p.maxInterpolationGap;
            if isfield(gBntData{gCurrentTrial}.posCleanInfo, 'meanFilterOrder')
                checks(3) = (gBntData{gCurrentTrial}.posCleanInfo.meanFilterOrder == meanFilterOrder);
            end
            checks(end+1) = strcmpi(gBntData{gCurrentTrial}.posCleanInfo.filter, filterToUse);
            if isfield(gBntData{gCurrentTrial}.posCleanInfo, 'filterSpan')
                checks(end+1) = gBntData{gCurrentTrial}.posCleanInfo.filterSpan == filterSpan;
            end

            if all(checks)
                positions = gBntData{gCurrentTrial}.posClean;

                mode = 'all';
            end
        else
            posFile = helpers.uniqueFilename(gBntData{gCurrentTrial}, 'posClean');
            if exist(posFile, 'file')
                tmpPos = load(posFile);

                if isfield(tmpPos, 'info')
                    if isfield(tmpPos.info, 'distanceThreshold')
                        checks(1) = tmpPos.info.distanceThreshold == originalThreshold;
                    else
                        checks(1) = false;
                    end
                    checks(2) = tmpPos.info.maxInterpolationGap == p.maxInterpolationGap;
                    if isfield(tmpPos.info, 'meanFilterOrder')
                        checks(3) = (tmpPos.info.meanFilterOrder == meanFilterOrder);
                    else
                        % 15 was the default value from the very beginning
                        checks(3) = 15 == meanFilterOrder;
                    end
                    if isfield(tmpPos.info, 'filter')
                        checks(end+1) = strcmpi(tmpPos.info.filter, filterToUse);
                    else
                        checks(end+1) = false;
                    end
                    if isfield(tmpPos.info, 'filterSpan')
                        checks(end+1) = tmpPos.info.filterSpan == filterSpan;
                    else
                        checks(end+1) = false;
                    end
                else
                    checks = false(1, 3);
                end

                if all(checks)
                    % only proceceed if parameters used to generate data are the same

                    gBntData{gCurrentTrial}.posClean = tmpPos.positions;
                    gBntData{gCurrentTrial}.posCleanInfo = tmpPos.info;

                    positions = tmpPos.positions;
                    clear tmpPos;

                    mode = 'all';
                end
            end
        end
    end

    if isfield(gBntData{gCurrentTrial}, 'posCleanInfo') && isfield(gBntData{gCurrentTrial}.posCleanInfo, 'allowScaling')
        allowScaling = gBntData{gCurrentTrial}.posCleanInfo.allowScaling;
    end

    if decodeNeuralynx
        % no average and need 2 LED from NeuraLynx
        if isfield(gBntData{gCurrentTrial}.nlx, 'decodedPos')
            positions = gBntData{gCurrentTrial}.nlx.decodedPos;
        else
            numSessions = length(gBntData{gCurrentTrial}.sessions);
            for s = 1:numSessions
                startIndices = gBntData{gCurrentTrial}.startIndices;
                if isempty(startIndices)
                    startInd = 1;
                    endInd = length(positions(:, 2));
                else
                    startInd = startIndices(s);
                    if s == length(startIndices)
                        endInd = length(positions(:, 2));
                    else
                        endInd = startIndices(s + 1) - 1;
                    end
                end

                targets = gBntData{gCurrentTrial}.nlx.targets(:, startInd:endInd);
                [dTargets, trackingColour] = io.neuralynx.decodeTargets(targets);
                [frontX, frontY, backX, backY] = io.neuralynx.extractPosition(dTargets, trackingColour);
                if length(frontX) ~= 1
                    ind = find(frontX == 0 & frontY == 0);
                    frontX(ind) = NaN;
                    frontY(ind) = NaN;
                    ind = find(backX == 0 & backY == 0);
                    backX(ind) = NaN;
                    backY(ind) = NaN;

                    positions(startInd:endInd, bntConstants.PosX) = frontX;
                    positions(startInd:endInd, bntConstants.PosY) = frontY;
                    positions(startInd:endInd, bntConstants.PosX2) = backX;
                    positions(startInd:endInd, bntConstants.PosY2) = backY;

                    gBntData{gCurrentTrial}.nlx.decodedPos(startInd:endInd, :) = positions(startInd:endInd, :);
                end
            end % loop over sessions
        end
    end

    if isfield(gBntData{gCurrentTrial}.extraInfo, 'calibration')
        if ~isfield(gBntData{gCurrentTrial}.extraInfo.calibration, 'data')
            mytmp = load(gBntData{gCurrentTrial}.extraInfo.calibration.file);
            gBntData{gCurrentTrial}.extraInfo.calibration.data = mytmp.cameraParams;
            clear mytmp;
        end
    end

    if isfield(gBntData{gCurrentTrial}.extraInfo, 'outerSize')
        % process outer size (extract it), undistort it
        if ~isfield(gBntData{gCurrentTrial}.extraInfo.outerSize, 'points')
            outerBounds = io.extractShapeBounds(gBntData{gCurrentTrial}.extraInfo.outerSize.rec, ...
                gBntData{gCurrentTrial}.extraInfo.shape.type, gBntData{gCurrentTrial}.extraInfo.calibration.data);
            gBntData{gCurrentTrial}.extraInfo.outerSize.points = outerBounds;
        end
    end

    if isfield(gBntData{gCurrentTrial}.extraInfo, 'innerSize')
        % process outer size (extract it), undistort it
        if ~isfield(gBntData{gCurrentTrial}.extraInfo.innerSize, 'points')
            innerBounds = io.extractShapeBounds(gBntData{gCurrentTrial}.extraInfo.innerSize.rec, ...
                gBntData{gCurrentTrial}.extraInfo.shape.type, gBntData{gCurrentTrial}.extraInfo.calibration.data);
            gBntData{gCurrentTrial}.extraInfo.innerSize.points = innerBounds;
        end
    end

    if strcmp(mode, 'clean')
        % Preprocess positions and discard incorrect
        xIdx = bntConstants.PosX;
        yIdx = bntConstants.PosY;

        if isfield(gBntData{gCurrentTrial}.extraInfo, 'calibration')
            cameraParams = gBntData{gCurrentTrial}.extraInfo.calibration.data;

            positions(:, [xIdx yIdx]) = helpers.undistortPoints(positions(:, [xIdx yIdx]), cameraParams);
            if size(positions, 2) > 3
                positions(:, [bntConstants.PosX2 bntConstants.PosY2]) = helpers.undistortPoints(positions(:, [bntConstants.PosX2 bntConstants.PosY2]), cameraParams);
            end

            if isfield(gBntData{gCurrentTrial}.extraInfo, 'outerSize')
                outerBounds = gBntData{gCurrentTrial}.extraInfo.outerSize.points;

                minV = min(outerBounds);
                maxV = max(outerBounds);

                outliers = positions(:, xIdx) < minV(1) | positions(:, xIdx) > maxV(1);
                positions(outliers, xIdx) = nan;

                outliers = positions(:, yIdx) < minV(2) | positions(:, yIdx) > maxV(2);
                positions(outliers, yIdx) = nan;
                if size(positions, 2) > 3
                    outliers = positions(:, bntConstants.PosX2) < minV(1) | positions(:, bntConstants.PosX2) > maxV(1);
                    positions(outliers, bntConstants.PosX2) = nan;
                    outliers = positions(:, bntConstants.PosY2) < minV(2) | positions(:, bntConstants.PosY2) > maxV(2);
                    positions(outliers, bntConstants.PosY2) = nan;
                end
            end
        end

        % the following processing step could be affected by merged sessions, so process individually
        numSessions = length(gBntData{gCurrentTrial}.sessions);
        for s = 1:numSessions
            xIdx = bntConstants.PosX;
            yIdx = bntConstants.PosY;

            startIndices = gBntData{gCurrentTrial}.startIndices;
            if isempty(startIndices)
                startInd = 1;
                endInd = length(positions(:, xIdx));
            else
                startInd = startIndices(s);
                if s == length(startIndices)
                    endInd = length(positions(:, xIdx));
                else
                    endInd = startIndices(s + 1) - 1;
                end
            end

            sessionInd = startInd:endInd;
%             positions(sessionInd, xIdx) = medfilt1(positions(sessionInd, xIdx), 9);
%             positions(sessionInd, yIdx) = medfilt1(positions(sessionInd, yIdx), 9);
            [positions(sessionInd, xIdx), positions(sessionInd, yIdx)] = general.removePosJumps(positions(sessionInd, xIdx), positions(sessionInd, yIdx), p.distanceThreshold, p.posStdThreshold);

            positions(sessionInd, xIdx) = helpers.fixIsolatedData(positions(sessionInd, xIdx));
            positions(sessionInd, yIdx) = helpers.fixIsolatedData(positions(sessionInd, yIdx));

            [tmpPosx, tmpPosy] = general.interpolatePositions(positions(sessionInd, 1), [positions(sessionInd, xIdx) positions(sessionInd, yIdx)]);

            if helpers.isstring(gBntData{gCurrentTrial}.system, bntConstants.RecSystem.Virmen) ...
                    && gBntData{gCurrentTrial}.extraInfo.shape.type == bntConstants.ArenaShape.Track
                % do nothing for linear track recorded in virtual reality. Median filter changes the limits
                % of the data which can be crucial for left/right runs detection.
            else
                % NOTE! Combined sessions could be a problem if they are not perfectly aligned.
                if strcmpi(filterToUse, 'mean')
                    tmpPosx = medfilt1(tmpPosx, meanFilterOrder); % there should be no NaNs in input for medfilt1.
                    tmpPosy = medfilt1(tmpPosy, meanFilterOrder);
                elseif strcmpi(filterToUse, 'lowess')
                    tmpPosx = smooth(tmpPosx, filterSpan, 'lowess');
                    tmpPosy = smooth(tmpPosy, filterSpan, 'lowess');
                end
            end

            maxDiff = abs(nanmax(tmpPosx) - nanmax(tmpPosy));
            maxDiff_prev = abs(nanmax(positions(sessionInd, xIdx)) - nanmax(positions(sessionInd, yIdx)));
            diffPercentage = round(maxDiff / maxDiff_prev * 100);
            if maxDiff > 1000 || ((maxDiff > maxDiff_prev) && diffPercentage > 200)
                warning('BNT:positionInQuestion', 'Seems that the interpolation of position samples have failed. Will remove suspicious values.');
                minx = min(positions(sessionInd, xIdx));
                maxx = max(positions(sessionInd, xIdx));
                miny = min(positions(sessionInd, yIdx));
                maxy = max(positions(sessionInd, yIdx));
                badIndX = tmpPosx > maxx | tmpPosx < minx;
                badIndY = tmpPosy > maxy | tmpPosy < miny;
                tmpPosx(badIndX) = nan;
                tmpPosy(badIndY) = nan;
            end
            positions(sessionInd, xIdx) = tmpPosx;
            positions(sessionInd, yIdx) = tmpPosy;
            clear tmpPosx tmpPosy;

            if size(positions, 2) > 3
                xIdx = bntConstants.PosX2;
                yIdx = bntConstants.PosY2;

%                 positions(sessionInd, xIdx) = medfilt1(positions(sessionInd, xIdx), 9);
%                 positions(sessionInd, yIdx) = medfilt1(positions(sessionInd, yIdx), 9);
                [positions(sessionInd, xIdx), positions(sessionInd, yIdx)] = general.removePosJumps(positions(sessionInd, xIdx), positions(sessionInd, yIdx), p.distanceThreshold, p.posStdThreshold);

                positions(sessionInd, xIdx) = helpers.fixIsolatedData(positions(sessionInd, xIdx));
                positions(sessionInd, yIdx) = helpers.fixIsolatedData(positions(sessionInd, yIdx));

                [tmpPosx, tmpPosy] = general.interpolatePositions(positions(sessionInd, 1), [positions(sessionInd, xIdx) positions(sessionInd, yIdx)]);
                if strcmpi(filterToUse, 'mean')
                    % NOTE! Combined sessions could be a problem if they are not perfectly aligned.
                    tmpPosx = medfilt1(tmpPosx, meanFilterOrder); % no check for Virmen, because it is only used for linear track recordings
                    tmpPosy = medfilt1(tmpPosy, meanFilterOrder);
                elseif strcmpi(filterToUse, 'lowess')
                    tmpPosx = smooth(tmpPosx, filterSpan, 'lowess');
                    tmpPosy = smooth(tmpPosy, filterSpan, 'lowess');
                end

                maxDiff = abs(nanmax(tmpPosx) - nanmax(tmpPosy));
                maxDiff_prev = abs(nanmax(positions(sessionInd, xIdx)) - nanmax(positions(sessionInd, yIdx)));
                diffPercentage = round(maxDiff / maxDiff_prev * 100);
                if maxDiff > 1000 || ((maxDiff > maxDiff_prev) && diffPercentage > 200)
                    warning('BNT:positionInQuestion', 'Seems that the interpolation of position samples have failed. Will remove suspicious values.');
                    minx = min(positions(sessionInd, xIdx));
                    maxx = max(positions(sessionInd, xIdx));
                    miny = min(positions(sessionInd, yIdx));
                    maxy = max(positions(sessionInd, yIdx));
                    badIndX = tmpPosx > maxx | tmpPosx < minx;
                    badIndY = tmpPosy > maxy | tmpPosy < miny;
                    tmpPosx(badIndX) = nan;
                    tmpPosy(badIndY) = nan;
                end
                positions(sessionInd, xIdx) = tmpPosx;
                positions(sessionInd, yIdx) = tmpPosy;
                clear tmpPosx tmpPosy;
            end
        end

        % remove samples with negative timestamps
        negIdx = positions(:, 1) < 0;
        positions(negIdx, :) = [];

        % save cleaned positions
        doNotSave = false;

        % do not save decoded positions for NeuraLynx
        if strcmpi(gBntData{gCurrentTrial}.system, bntConstants.RecSystem.Neuralynx) && size(positions, 2) > 3
            doNotSave = true;
        end

        info.distanceThreshold = p.distanceThreshold * gBntData{gCurrentTrial}.videoSamplingRate;
        info.maxInterpolationGap = p.maxInterpolationGap;
        if ~(helpers.isstring(gBntData{gCurrentTrial}.system, bntConstants.RecSystem.Virmen) ...
                && gBntData{gCurrentTrial}.extraInfo.shape.type == bntConstants.ArenaShape.Track) ...
                && strcmpi(filterToUse, 'mean')
            info.meanFilterOrder = meanFilterOrder;
        end
        info.filter = filterToUse;
        info.filterSpan = filterSpan;
        % flag that indicates if positions were altered manually
        info.manual = false;
        creationTime = now; %#ok<NASGU>

        gBntData{gCurrentTrial}.posClean = positions;
        gBntData{gCurrentTrial}.posCleanInfo = info;

        if ~doNotSave
            posFile = helpers.uniqueFilename(gBntData{gCurrentTrial}, 'posClean');
            if exist(posFile, 'file')
                tt = load(posFile);
                if isfield(tt, 'info') && isfield(tt.info, 'manual') && tt.info.manual
                    [fPath, fName, fExt] = helpers.fileparts(posFile);
                    backupName = fullfile(fPath, sprintf('%s_backup%s', fName, fExt));
                    warning('BNT:manualPos', 'BNT wanted to overwrite file %s, but it was created manually. Will not overwrite, but make a backup:\n%s', posFile, backupName);
                    try
                        copyfile(posFile, backupName);
                    catch
                        warning('BNT:manualPos', 'Failed to copy file. Perhaps you do not have write permission to that directory');
                    end
                end
            end
            try
                save(posFile, 'positions', 'info', 'creationTime');
            catch
                % do not save if we can not. Perhaps we work with archive data.
            end
        end
    end

    % average before the scaling. Otherwise we scale both LEDs to the arena size, which is
    % incorrect. In reaity both LEDs do not cover the full arena.
    if strcmp(average, 'on') && size(positions, 2) > 3
        positions(:, bntConstants.PosX) = mean([positions(:, bntConstants.PosX) positions(:, bntConstants.PosX2)], 2);
        positions(:, bntConstants.PosY) = mean([positions(:, bntConstants.PosY) positions(:, bntConstants.PosY2)], 2);
        positions(:, bntConstants.PosY2) = [];
        positions(:, bntConstants.PosX2) = [];
    end

    % scale the coordinates using the shape information
    if strcmp(scale, 'on') && isfield(gBntData{gCurrentTrial}.extraInfo, 'shape')
        minX = nanmin(positions(:, bntConstants.PosX));
        maxX = nanmax(positions(:, bntConstants.PosX));
        minY = nanmin(positions(:, bntConstants.PosY));
        maxY = nanmax(positions(:, bntConstants.PosY));
        xLength = maxX - minX;
        yLength = maxY - minY;
        firstLedArenaIsBigger = true;
        if size(positions, 2) > 3
            minX2 = nanmin(positions(:, bntConstants.PosX2));
            maxX2 = nanmax(positions(:, bntConstants.PosX2));
            minY2 = nanmin(positions(:, bntConstants.PosY2));
            maxY2 = nanmax(positions(:, bntConstants.PosY2));
            xLength2 = maxX2 - minX2;
            yLength2 = maxY2 - minY2;

            % decide which LED to use for scalling based on their 'covered area'.
            % Use the one with bigger area. This should result in no values being outside
            % of the box.
            squareLed1 = xLength * yLength;
            squareLed2 = xLength2 * yLength2;
            [~, ledToUse] = max([squareLed1 squareLed2]);
            if ledToUse == 2
                firstLedArenaIsBigger = false;
                xLength = xLength2;
                yLength = yLength2;
            end
        end

        if allowScaling
            if length(gBntData{gCurrentTrial}.extraInfo.shape.value) == 1
                scaleCoefX = gBntData{gCurrentTrial}.extraInfo.shape.value / xLength;
                scaleCoefY = gBntData{gCurrentTrial}.extraInfo.shape.value / yLength;
            else
                scaleCoefX = gBntData{gCurrentTrial}.extraInfo.shape.value(1) / xLength;
                scaleCoefY = gBntData{gCurrentTrial}.extraInfo.shape.value(2) / yLength;
            end
            if yLength == 1 || isinf(scaleCoefY)
                % the data is probably from a VR linear track, thus all values along y-axis are the same.
                scaleCoefY = 1;
            end

            % use single factor to scale positions in order to preserve distances between LEDs
            positions(:, bntConstants.PosX) = positions(:, bntConstants.PosX) * scaleCoefX;
            positions(:, bntConstants.PosY) = positions(:, bntConstants.PosY) * scaleCoefY;
            if size(positions, 2) > 3
                positions(:, bntConstants.PosX2) = positions(:, bntConstants.PosX2) * scaleCoefX;
                positions(:, bntConstants.PosY2) = positions(:, bntConstants.PosY2) * scaleCoefY;
            end

            % This is more a hack. So far, scaling is disabled just for one
            % project where positions of different trials should be aligned
            % to a common value. Scaling and centring messes-up this allignment.

            % Centre the box in the coordinate system
            if firstLedArenaIsBigger
                centre = general.centreBox(positions(:, bntConstants.PosX), positions(:, bntConstants.PosY));
            else
                centre = general.centreBox(positions(:, bntConstants.PosX2), positions(:, bntConstants.PosY2));
            end
            positions(:, bntConstants.PosX) = positions(:, bntConstants.PosX) - centre(1);
            positions(:, bntConstants.PosY) = positions(:, bntConstants.PosY) - centre(2);

            if size(positions, 2) > 3
                positions(:, bntConstants.PosX2) = positions(:, bntConstants.PosX2) - centre(1);
                positions(:, bntConstants.PosY2) = positions(:, bntConstants.PosY2) - centre(2);
            end
        end
    end

    if ~isequal(speedFilter, [0 0])
        numSessions = length(gBntData{gCurrentTrial}.sessions);
        for s = 1:numSessions
            xIdx = bntConstants.PosX;
            yIdx = bntConstants.PosY;
            [startInd, endInd] = data.getRunIndices(s);
            validInd = startInd:endInd;

            sessionPos = positions(validInd, [bntConstants.PosT xIdx yIdx]);

            % Indices of positions from LED1 that should be filtered
            led1ToFilter = general.speedThreshold(sessionPos, speedFilter(1), speedFilter(2));
            gBntData{gCurrentTrial}.numGoodSamplesFiltered(1) = length(led1ToFilter);

            % Since we have only exact indices, make complete logical indices that can be used in
            % logical operations (combination)
            selected = false(1, size(sessionPos, 1));
            selected(led1ToFilter) = true;

            % NB! Time stays without NaNs since it should be continuous.
            sessionPos(selected, 2:end) = nan;
            positions(validInd, [xIdx yIdx]) = sessionPos(:, 2:end);

            if size(positions, 2) > 3
                xIdx = bntConstants.PosX2;
                yIdx = bntConstants.PosY2;

                sessionPos = positions(validInd, [bntConstants.PosT xIdx yIdx]);

                led2ToFilter = general.speedThreshold(sessionPos, speedFilter(1), speedFilter(2));
                gBntData{gCurrentTrial}.numGoodSamplesFiltered(2) = length(led2ToFilter);

                selected = false(1, size(sessionPos, 1));
                selected(led2ToFilter) = true;

                % NB! Time stays without NaNs since it should be continuous.
                sessionPos(selected, 2:end) = nan;
                positions(validInd, [xIdx yIdx]) = sessionPos(:, 2:end);
            end
        end
    end
end
