% gridnessScoreCBM10_3()
%
% This programm calculates gridness score on a test data. It is a an extracted 
% part of the original gridnessScore v10.3 used at CBM. 
%
% Created by Raymond Skjerpeng, KI/CBM, NTNU, 2009 - 2012.
% Compiled by Vadim Frolov, KI/CBM, NTNU, 2013.
%
function gridnessScoreCBM10_3()
%__________________________________________________________________________
%
%                       Program parameters
%__________________________________________________________________________
% Size in centimeters for the bins in the ratemap
p.binWidth = 2.5; % [cm]

% Minimum radius used in the auto-correlogram when finding the best
% gridness score
p.minRadius = 20; % [cm]

% Increment step of the radius when calculating what radius gives the best
% gridness score. 
p.radiusStep = p.binWidth; % [cm]

% When calculating gridness score based on the best radius, the program
% calculates the gridness score as an average over adjacent radii. This
% parameter sets the number of radii to use. The number must be odd. The
% middle radius will be set to be the best radius.
p.numGridnessRadii = 3;

% Threshold value used when defining the centre field. Border of centre
% field is defined as the place where the correlation falls under this
% threshold or the correlation start to increase again.
p.correlationThresholdForCentreField = 0.2;

% Sets how the gridness values are calculated.
% Mode = 0: Gridness is calculated as the mean correlation at 60 and 120
%           degrees minus the mean correlation at 30, 90 and 150 degrees.
% Mode = 1: Gridness is calculated as the minimum correlation at 60 and 120
%           degrees minus the maximum correlation at 30, 90 and 150
%           degrees.
p.gridnessCalculationMode = 1;

% Minimum allowed width of the correlogram disk. I.e the distance from the
% centre radius to the radius that gives the best gridness score. If the
% centre field radius is closer to the edge of the correlogram than the
% disk with, the gridness score will be NaN.
p.minDiskWidth = 10; % [cm]

% Minimum number of bins in a placefield. Fields with fewer bins than this
% treshold will not be considered as a placefield. Remember to adjust this
% value when you change the bin width
p.minNumBins = 5;

% Bins with rate at p.fieldTreshold * peak rate and higher will be considered as part
% of a place field
p.fieldTreshold = 0.2;

%---------------------------------------------------------------------------------------------------

    load('gridness_test_data');
    if (exist('map', 'var') == 0) || (exist('aMap', 'var') == 0)
        disp('Failed to load test data. Exiting.')
        return
    end
    p.maxRadius = maxRadius;
    
    h = figure(1);
    screenSize = get(0, 'screenSize');
    positionVector = [20, 80, screenSize(3)-40, screenSize(4)-170];
    set(h, 'position', positionVector)
    cmap = getCmap();
    
    figure(1)
    maxPlotRate = nanmax(nanmax(map));
    drawMap(map, xAxis, yAxis, cmap, maxPlotRate);
    
    maxPlotRate = nanmax(nanmax(aMap));
    figure(1), clf
    drawMap(aMap, aColAxis, aRowAxis, cmap, maxPlotRate);
    
    % There are some functions that are commented out. I left them so you can see the execution worflow.
    % Calculate rate map based on spike positions
    %[map, rawMap, xAxis, yAxis] = rateMap(x, y, spkx, spky, p.binWidth, p.binWidth, start, tLength, start, tLength, p.sampleTime, p);

    % Caclulate rate map with adaptive smoothing
    %[aMap, posPDF, aRowAxis, aColAxis]  = ratemapAdaptiveSmoothing(x, y, spkx, spky, xStart, xLength-(p.binWidth*2), yStart, yLength-(p.binWidth*2), p.sampleTime, p, shape);

    % Calculate correlograms
    corrMaps = rotatedCorrelationMaps(map);

    % define the axis for the correlation map
    corrAxisX = p.binWidth * linspace(-((size(corrMaps{1},1)-1)/2),((size(corrMaps{1},1)-1)/2),size(corrMaps{1},1));
    corrAxisY = fliplr(corrAxisX)'; % flip and transpose

    figure(1), clf
    drawMap(corrMaps{1}+1, corrAxisX, corrAxisY, cmap, nanmax(nanmax(corrMaps{1}+1)));
    
    % Calculate the radius that gives the best gridness score when removing the
    % centre field and the resulting gridness
    [gridnessCentreRemoved, radiusCentreRemoved, centreRadius] = gridnessRadiusCentreRemoved(corrMaps, p, corrAxisX);
    disp(['Gridness score based on radius increase ' num2str(gridnessCentreRemoved)]);
    
    figure(1), hold on
    % Plot the inner circle that mark the area of the centre field removed
    a = 0:pi/32:2*pi;
    b = centreRadius * sin(a);
    c = centreRadius * cos(a);
    plot(b, c, 'k');
    % Plot the outer radius
    b = radiusCentreRemoved * sin(a);
    c = radiusCentreRemoved * cos(a);
    plot(b, c, 'k');
    hold off
    
    % Draw a full range version of the correlogram
    figure(1)
    RxxFS = corrMaps{1};
    RxxFS = RxxFS * 100;
    RxxFS = RxxFS - nanmin(nanmin(RxxFS));
    drawMap(RxxFS, corrAxisX, corrAxisY, cmap, nanmax(nanmax(RxxFS)));    

    % Calculate gridness where the radius is based on the location of the peaks
    % in the correlogram
    [gridnessNoCentrePeakBased, radiusPeakBased, centreRadiusPeakBased, cpx, cpy, numCorrelogramFields, corrPeakDist] = gridnessPeakPositionBased(corrAxisX, corrAxisY, corrMaps, p);
    disp(['Gridness score based on peak locations ' num2str(gridnessNoCentrePeakBased)]);

    figure(1), clf
    drawMap(corrMaps{1}+1, corrAxisX, corrAxisY, cmap, nanmax(nanmax(corrMaps{1}+1)));
    hold on
    plot(cpx, cpy,'kx');
    a = 0:pi/32:2*pi;
    b = centreRadiusPeakBased * sin(a);
    c = centreRadiusPeakBased * cos(a);
    plot(b, c, 'k');
    % Plot the outer radius
    b = radiusPeakBased * sin(a);
    c = radiusPeakBased * cos(a);
    plot(b, c, 'k');
    hold off
    
 end % gridnessScoreCBM

% Calculates the auto-correlogram from the rate map and rotated versions of
% the correlogram.
function corrMaps = rotatedCorrelationMaps(map)
    Rxx = correlation(map);
    N = 6;
    corrMaps = cell(N,1);
    corrMaps{1} = Rxx;

    rotation = 30:30:150;

    for ii = 1:N-1
        corrMaps{ii+1} = imrotate(Rxx, rotation(ii), 'bilinear', 'crop');
    end
end

% Calculates the auto-correlation map for the rate map
%
% Author: Raymond Skjerpeng and Jan Christian Meyer.
function Rxy = correlation(map)
    bins = size(map,1);
    N = bins + round(0.8*bins);
    if ~mod(N,2)
        N = N - 1;
    end
    % Centre bin
    cb = (N+1)/2;
    Rxy = NaN(N);
    %'correlation-function'
    %tic
    for r = 1:(N+1)/2
        rowOff = r-cb;
        numRows = bins - abs(rowOff);
        rSt1 = max(0, rowOff);
        rSt2 = abs(min(0,rowOff));
        for c = 1:N
            colOff = c-cb;
            numCol = bins - abs(colOff);
            cSt1 = max(0,colOff);
            cSt2 = abs(min(0,colOff));
            map1_local = map((rSt1+1):(rSt1+numRows),(cSt1+1):(cSt1+numCol));
            map2_local = map((rSt2+1):(rSt2+numRows),(cSt2+1):(cSt2+numCol));

            nans = max(isnan(map1_local),isnan(map2_local));
            NB = numRows * numCol - sum(sum(nans));

            if NB >= 20
                map1_local(nans) = 0;
                sumX = sum(sum(map1_local));
                sumX2 = sum(sum(map1_local.^2));
                sumx2 = sumX2 - sumX^2/NB;

                map2_local(nans) = 0;
                sumY = sum(sum(map2_local));
                sumY2 = sum(sum(map2_local.^2));
                sumy2 = sumY2 - sumY^2/NB;
                if ~((sumx2<=0 && sumy2>=0) || (sumx2>=0 && sumy2<=0))
                    sumXY = sum(sum(map1_local .* map2_local));
                    sumxy = sumXY - sumX*sumY/NB;
                    Rxy(r,c) = sumxy/sqrt(sumx2*sumy2);
                end
            end
        end
    end
    
    % Fill the second half of the correlogram
    for r = (N+1)/2+1:N
        rInd = cb + (cb - r);
        for c = 1:N
            cInd = cb + (cb - c);
            Rxy(r,c) = Rxy(rInd,cInd);
        end
    end
end

% Calculates the radius that gives the best gridness score
function [gridness, radius, centreRadius] = gridnessRadiusCentreRemoved(corrMaps, p, corrAxis)
    numRotations = floor(180/30);

    % Calculate the centre field radius
    centreRadius = centreFieldRadius(corrAxis, corrMaps{1}, p);

    if p.maxRadius - centreRadius < p.minDiskWidth
        % Centre field is to large to do the gridness calculation
        disp('The centre field is to large to calculate the gridness score for this cell')
        gridness = NaN;
        radius = NaN;
        return
    end

    % Set the start radius to test
    radius = max([p.minRadius, centreRadius + p.minDiskWidth]);

    numRadius = ceil((p.maxRadius-radius)/p.radiusStep);

    % Array to hold the gridness scores for the different radii
    gridnessArray = zeros(numRadius,2);
    corrValues = zeros(numRotations,numRadius);

    % Size, in number of bins, of the map
    [N,M] = size(corrMaps{1});

    % Calculate the distance from origo for each bin in the map
    oDist = zeros(N,M);
    for ii = 1:N
        for jj = 1:M
            oDist(ii,jj) = sqrt(corrAxis(ii)^2 + corrAxis(jj)^2);
        end
    end

    for ii = 1:numRadius
        Rxx = corrMaps{1};
        % Set the part of the map outside the radius to NaN
        Rxx = adjustMap(Rxx,radius,centreRadius,oDist);
        
        for jj = 2:numRotations
            RxxR = corrMaps{jj};
            
            % Set the part of the map outside the radius to NaN
            RxxR = adjustMap(RxxR,radius,centreRadius,oDist);
            
            corrValues(jj,ii) = pointCorr(Rxx,RxxR,0,0,size(Rxx,1));

        end
        
        % Calculate the degree of "gridness"
        if p.gridnessCalculationMode == 0
            sTop = mean([corrValues(3,ii),corrValues(5,ii)]);
            sTrough = mean([corrValues(2,ii),corrValues(4,ii),corrValues(6,ii)]);
        else
            sTop = min([corrValues(3,ii),corrValues(5,ii)]);
            sTrough = max([corrValues(2,ii),corrValues(4,ii),corrValues(6,ii)]);
        end
        gridnessArray(ii,1) = sTop - sTrough;
        gridnessArray(ii,2) = radius;

        
        % Increment the radius
        radius = radius + p.radiusStep;
    end

    if p.numGridnessRadii > 1
        numStep = numRadius - p.numGridnessRadii;
        if numStep < 1
            numStep = 1;
        end

        if numStep == 1
            gridness = nanmean(gridnessArray(:,1));
            radius = nanmean(gridnessArray(:,2));
        else
            meanGridnessArray = zeros(numStep,1);
            for ii = 1:numStep
                meanGridnessArray(ii) = nanmean(gridnessArray(ii:ii+p.numGridnessRadii-1,1));
            end

            [gridness, gInd] = max(meanGridnessArray);
            radius = gridnessArray(gInd+(p.numGridnessRadii-1)/2, 2);
        end
    else
        % Maximum gridness
        [gridness,gInd] = max(gridnessArray(:,1));
        radius = gridnessArray(gInd,2);
    end
end

% Calculates the radius of the centre field in the correlogram
function centreRadius = centreFieldRadius(corrAxis, Rxx, p)
    threshold = p.correlationThresholdForCentreField;

    % Size of the auto-correlogram
    [N,M] = size(Rxx);

    % Bin width
    binWidth = corrAxis(2) - corrAxis(1);

    % Centre bin
    cRow = (N+1) / 2;
    cCol = (M+1) / 2;

    radiusArray = zeros(8,1);

    % Calculate border of field to the right of the centre
    col = cCol;
    while 1
        col = col + 1;
        if col == M
            break;
        end
        if Rxx(cRow, col) < threshold || Rxx(cRow,col) > Rxx(cRow, col-1)
            break;
        end
    end
    radiusArray(1) = (col - cCol) * binWidth;

    % Calculate border of field up from the centre
    row = cRow;
    while 1
        row = row - 1;
        if row == 1
            break;
        end
        if Rxx(row, cCol) < threshold || Rxx(row,cCol) > Rxx(row+1, cCol)
            break;
        end
    end
    radiusArray(2) = (cRow - row) * binWidth;

    % Calculate border of field down to the right from the centre
    col = cCol;
    row = cRow;
    while 1
        row = row + 1;
        col = col + 1;
        if row >= N
            break;
        end
        if col >= M
            break;
        end
        
        if Rxx(row, col) < threshold || Rxx(row, col) > Rxx(row-1, col-1)
            break;
        end
        
    end
    radiusArray(3) = sqrt(((row - cRow) * binWidth)^2 + ((col - cCol) * binWidth)^2);

    % Calculate border of field up to the right from the centre
    col = cCol;
    row = cRow;
    while 1
        row = row - 1;
        col = col + 1;
        if row <= 1
            break;
        end
        if col >= M
            break;
        end
        
        if Rxx(row, col) < threshold || Rxx(row, col) > Rxx(row+1, col-1)
            break;
        end
        
    end
    radiusArray(4) = sqrt((abs(row - cRow) * binWidth)^2 + (abs(cCol - col) * binWidth)^2);

    % Calculate border of field up 67.5
    col = cCol;
    row = cRow;
    while 1
        row = row - 2;
        col = col + 1;
        if row <= 1
            break;
        end
        if col >= M
            break;
        end
        
        if Rxx(row, col) < threshold || Rxx(row, col) > Rxx(row+2, col-1)
            break;
        end
        
    end
    radiusArray(5) = sqrt((abs(row - cRow) * binWidth)^2 + (abs(cCol - col) * binWidth)^2);

    % Calculate border of field up 22.5
    col = cCol;
    row = cRow;
    while 1
        row = row - 1;
        col = col + 2;
        if row <= 1
            break;
        end
        if col >= M
            break;
        end
        
        if Rxx(row, col) < threshold || Rxx(row, col) > Rxx(row+1, col-2)
            break;
        end
        
    end
    radiusArray(6) = sqrt((abs(row - cRow) * binWidth)^2 + (abs(cCol - col) * binWidth)^2);

    % Calculate border of field down 67.5
    col = cCol;
    row = cRow;
    while 1
        row = row + 2;
        col = col + 1;
        if row >= N
            break;
        end
        if col >= M
            break;
        end
        
        if Rxx(row, col) < threshold || Rxx(row, col) > Rxx(row-2, col-1)
            break;
        end
        
    end
    radiusArray(7) = sqrt(((row - cRow) * binWidth)^2 + ((col - cCol) * binWidth)^2);

    % Calculate border of field down 22.5
    col = cCol;
    row = cRow;
    while 1
        row = row + 1;
        col = col + 2;
        if row >= N
            break;
        end
        if col >= M
            break;
        end
        
        if Rxx(row, col) < threshold || Rxx(row, col) > Rxx(row-1, col-2)
            break;
        end
        
    end
    radiusArray(8) = sqrt((abs(row - cRow) * binWidth)^2 + (abs(col - cCol) * binWidth)^2);

    centreRadius = mean(radiusArray);
end

% Sets the bins of the map outside the radius to NaN
function Rxx = adjustMap(Rxx, radius, centreRadius, oDist)
    Rxx(oDist > radius) = NaN;
    Rxx(oDist <= centreRadius) = NaN;
end

% Calculates the correlation for a point in the autocorrelogram. It is
% using the Pearsons correlation method.
function Rxy = pointCorr(map1,map2,rowOff,colOff,N)
    % Number of rows in the correlation for this lag
    numRows = N - abs(rowOff);
    % Number of columns in the correlation for this lag
    numCol = N - abs(colOff);

    % Set the start and the stop indexes for the maps
    if rowOff > 0
        rSt1 = 1+abs(rowOff)-1;
        rSt2 = 0;
    else
        rSt1 = 0;
        rSt2 = abs(rowOff);
    end
    if colOff > 0
        cSt1 = abs(colOff);
        cSt2 = 0;
    else
        cSt1 = 0;
        cSt2 = abs(colOff);
    end

    sumXY = 0;
    sumX = 0;
    sumY = 0;
    sumX2 = 0;
    sumY2 = 0;
    NB = 0;
    for ii = 1:numRows
        for jj = 1:numCol
            if ~isnan(map1(rSt1+ii,cSt1+jj)) && ~isnan(map2(rSt2+ii,cSt2+jj))
                NB = NB + 1;
                sumX = sumX + map1(rSt1+ii,cSt1+jj);
                sumY = sumY + map2(rSt2+ii,cSt2+jj);
                sumXY = sumXY + map1(rSt1+ii,cSt1+jj) * map2(rSt2+ii,cSt2+jj);
                sumX2 = sumX2 + map1(rSt1+ii,cSt1+jj)^2;
                sumY2 = sumY2 + map2(rSt2+ii,cSt2+jj)^2;
            end
        end
    end

    if NB >= 20
        sumx2 = sumX2 - sumX^2/NB;
        sumy2 = sumY2 - sumY^2/NB;
        sumxy = sumXY - sumX*sumY/NB;
        if (sumx2<=0 && sumy2>=0) || (sumx2>=0 && sumy2<=0)
            Rxy = NaN;
        else
            Rxy = sumxy/sqrt(sumx2*sumy2);
        end
    else
        Rxy = NaN;
    end
end

function [gridnessNoCentre, radius, centreRadius, cpx, cpy, numFields, dist2] = gridnessPeakPositionBased(corrAxisX,corrAxisY, corrMaps, p)
    N = 6;

    gridnessNoCentre = NaN;
    radius = NaN;

    corrValuesNC = zeros(N,1);

    Rxx = corrMaps{1};

    % Calculate the centre field radius
    centreRadius = centreFieldRadius(corrAxisX, Rxx, p);

    peakPoints = correlationPeakDetection(corrAxisX,corrAxisY, Rxx, p);
    peakPointsX = peakPoints(:, 1);
    peakPointsY = peakPoints(:, 2);

    % Number of fields detected including the centre field
    numFields = size(peakPoints,1);

    if numFields <= 1
        % To few peaks found to do this analysis
        cpx = [];
        cpy = [];
        dist2 = NaN(6,1);
        return
    end

    % Make a copy of the array
    peakPointsXt = peakPointsX;
    peakPointsYt = peakPointsY;

    % Locate the centre field
    dist = sqrt(peakPointsX.^2 + peakPointsY.^2);
    [~,ind] = min(dist);
    cx = peakPointsX(ind(1));
    cy = peakPointsY(ind(1));
    peakPointsXt(ind(1)) = inf;
    peakPointsYt(ind(1)) = inf;

    % Distance from centre field to the rest of the fields
    dist = sqrt((peakPointsXt-cx).^2 + (peakPointsYt-cy).^2);
    dist2 = dist;

    % Locate the 6 fields that are closest to the centre
    nPeaks = length(dist) - 1;
    if nPeaks < 6
        fieldInd = zeros(nPeaks,1);
        
        for ii = 1:nPeaks
            [~, ind] = min(dist);
            fieldInd(ii) = ind(1);
            dist(ind(1)) = inf;
        end
        
    else
        fieldInd = zeros(6,1);
        
        for ii = 1:6
            [~, ind] = min(dist);
            fieldInd(ii) = ind(1);
            dist(ind(1)) = inf;
        end
    end

    dist2 = dist2(fieldInd);
    if nPeaks < 6
        dist3 = zeros(6,1);
        for ii = 1:nPeaks
            dist3(ii) = dist2(ii);
        end
        for ii = nPeaks+1:6
            dist3(ii) = NaN;
        end
        dist2 = dist3;
    end

    if numFields < 4
        % To few peaks found to do this analysis
        cpx = [];
        cpy = [];
        return
    end

    % Correlation peaks
    cpx = peakPointsX(fieldInd);
    cpy = peakPointsY(fieldInd);

    % Median distance to the peaks
    dist = sqrt((cpx-cx).^2 + (cpy-cy).^2);
    medianDist = mean(dist);

    radius = 1.25 * medianDist;

    % Set the part of the map outside the radius to NaN
    Rxx = adjustMap(Rxx,radius,-1,corrAxisX);
    RxxNC = adjustMap(Rxx,radius,centreRadius,corrAxisX);

    for jj = 2:N
        RxxR = corrMaps{jj};

        RxxRNC = adjustMap(RxxR,radius,centreRadius,corrAxisX);

        corrValuesNC(jj,ii) = pointCorr(RxxNC,RxxRNC,0,0,size(RxxNC,1));
    end

    % Calculate the degree of "gridness"
    if p.gridnessCalculationMode == 0
        
        sTopNC = mean([corrValuesNC(3,ii),corrValuesNC(5,ii)]);
        sTroughNC = mean([corrValuesNC(2,ii), corrValuesNC(4,ii), corrValuesNC(6,ii)]);
    else
        
        sTopNC = min([corrValuesNC(3,ii),corrValuesNC(5,ii)]);
        sTroughNC = max([corrValuesNC(2,ii),corrValuesNC(4,ii),corrValuesNC(6,ii)]);
    end

    gridnessNoCentre = sTopNC - sTroughNC;

    % Add the centre field to the peak arrays
    cpx = [cpx; cx];
    cpy = [cpy; cy];
end

% Correlogram peak detection
function peakPoints = correlationPeakDetection(corrAxisX,corrAxisY, Rxx, p)
    minBins = round(100 / p.binWidth^2);

    peakPoints = zeros(1000, 2);
    peakCounter = 0;
    [numRows,numCols] = size(Rxx);
    visited = ones(numRows, numCols);

    visited(isnan(Rxx)) = 0;

    % Remove low correlation
    ind = find(Rxx <= 0);
    Rxx(ind) = NaN;
    visited(ind) = 0;

    while sum(sum(visited)) > 0
        % Array that will contain the bin positions to the current placefield
        rowBins = [];
        colBins = [];

        % Find the current maximum
        [m, ind] = nanmax(Rxx);
        [~, cols] = nanmax(m);
        cols = cols(1);
        rows = ind(cols);
        peakRow = rows;
        peakCol = cols;
        visited(peakRow, peakCol) = 0;

        while 1
            rowBins = [rowBins; rows(1)];
            colBins = [colBins; cols(1)];

            [rows, cols, visited] = checkNeighbours(Rxx, rows, cols, visited);

            rows(1) = [];
            cols(1) = [];
            if isempty(rows)
                break;
            end
        end

        if length(rowBins) >= minBins
            peakCounter = peakCounter + 1;
            % Calculate the peak position based on centre of mass
            comX = 0;
            comY = 0;
            R = 0;
            for ii = 1:length(rowBins)
                R = R + Rxx(rowBins(ii),colBins(ii));
                comX = comX + Rxx(rowBins(ii), colBins(ii)) * corrAxisX(colBins(ii));
                comY = comY + Rxx(rowBins(ii), colBins(ii)) * corrAxisY(rowBins(ii));
            end
            peakPoints(peakCounter, 1) = comX/R;
            peakPoints(peakCounter, 2) = comY/R;
        end

        Rxx(rowBins, colBins) = NaN;
        visited(rowBins, colBins) = 0;

    end

    peakPoints = peakPoints(1:peakCounter, :);
end

function [rows, cols, visited] = checkNeighbours(map, rows, cols, visited)
    row = rows(1);
    col = cols(1);

    visited(row, col) = 0;

    % Set indexes to the surounding bins
    leftRow = row;
    rightRow = row;
    upRow = row-1;
    downRow = row+1;

    leftCol = col-1;
    rightCol = col+1;
    upCol = col;
    downCol = col;

    % Check left
    if leftCol >= 1 % Inside map
        if visited(leftRow,leftCol) && map(leftRow,leftCol) <= map(row,col)
            % Add bin as part of the field
            rows = [rows; leftRow;];
            cols = [cols; leftCol];
            visited(leftRow, leftCol) = 0;
        end
    end
    % Check rigth
    if rightCol <= size(map,2) % Inside map
        if visited(rightRow,rightCol) && map(rightRow,rightCol) <= map(row,col)
            % Add bin as part of the field
            rows = [rows; rightRow];
            cols = [cols; rightCol];
            visited(rightRow, rightCol) = 0;
        end
    end
    % Check up
    if upRow >= 1 % Inside map
        if visited(upRow,upCol) && map(upRow,upCol) <= map(row,col)
            % Add bin as part of the field
            rows = [rows; upRow];
            cols = [cols; upCol];
            visited(upRow, upCol) = 0;
        end
    end
    % Check down
    if downRow <= size(map,1) % Inside map
        if visited(downRow,downCol) && map(downRow,downCol) <= map(row,col)
            % Add bin as part of the field

            rows = [rows; downRow];
            cols = [cols; downCol];
            visited(downRow, downCol) = 0;
        end
    end
end

% drawMap(map, xAxis, yAxis)
%
% drawMap draws the rate map in a color coded image, using the jet color
% map. The number of color used for the scaling can be changed in the
% variable numLevels.
%
% map       Rate map that is to be displayed as image
% xAxis     The x-axis values (values for each column in the map)
% yAxis     The y-axis values (values for each row in the map)
%
% (c) Raymond Skjerpeng, KI/CBM, NTNU, 2012.
function drawMap(map, xAxis, yAxis, cmap, maxRate)
    map(map>maxRate) = maxRate;

    % Set the number of colors to scale the image with. This value must be the
    % same as the number of levels set in the getCmap function.
    numLevels = 256;

    % Size of rate map
    [numRows,numCols] = size(map);

    % Allocate memory for the image
    plotMap = ones(numRows,numCols,3);

    % Peak rate of the map
    peakRate = nanmax(nanmax(map));

    if peakRate > 0
        % set color of each bin scaled according to the peak rate, bins with NaN
        % will be plotted as white RGB = [1,1,1].
        for r = 1:numRows
            for c = 1:numCols
                if ~isnan(map(r,c))
                    % Set the color level for this bin
                    level = round((map(r,c) / peakRate) * (numLevels-1)) + 1;
                    if isnan(level)
                        plotMap(r,c,:) = cmap(1,:);
                    else
                        plotMap(r,c,:) = cmap(level,:);
                    end
                end
            end
        end
    else
        for r = 1:numRows
            for c = 1:numCols
                if ~isnan(map(r,c))
                    % Set the color level for this bin
                    level = 1;
                    plotMap(r,c,:) = cmap(level,:);
                end
            end
        end
    end

    % Display the image in the current figure window. (window must be created
    % before calling this function
    image(xAxis,yAxis,plotMap);
    % Adjust axis to the image format
    axis('image')
end

function cmap = getCmap()
    % Set the number of colors to scale the image with
    numLevels = 256;

    % set the colormap using the jet color map (The jet colormap is associated 
    % with an astrophysical fluid jet simulation from the National Center for 
    % Supercomputer Applications.)
    cmap = colormap(jet(numLevels));
end