function freqDistribution()
    %% =================================================
    % Parameters
    % =================================================

    % Data file. Full path to Excel file with data.
    p.excelFile = 'C:\home\workspace\anticipCoding\HeadDirectionPreference.xlsx';

    % Full path to directory where to store images. Leave empty to use current
    % directory.
    p.outputDir = 'C:\home\workspace\anticipCoding\bins';

    % Amount of cells that a direction bin should have in order to use it.
    % If there will be less than p.minCellsPerBin, than such bin depth will be
    % discradred.
    p.minCellsPerBin = 10;

    % Number of bins. Script plots p.numBins equally spaced bins in the 
    % range [0, 2*pi]. The default is 20.
    p.numBins = 20;

    % Format of the images made by the program.
    % format = 'bmp' (24 bit)
    % format = 'png'
    % format = 'eps'
    % format = 'jpg'
    % format = 'tiff' (24 bit)
    % format = 'fig' (Matlab figure)
    p.imageFormat = 'png';

    % DPI setting for stored images
    p.imageDpi = 300;
    
    % Percentage of a size of a mean vector arrow. The original size of the
    % arrow is multiplied by this factor.
    p.arrowScale = 0.6; % [0..1]
    %% =================================================


    %% Import the data
    [~, ~, raw] = xlsread(p.excelFile, 'Sheet1', 'A3:T1130');
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
    cellVectors = raw(:,[1,2,6,7]);
    raw = raw(:,[3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20]);

    % Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells

    % Create output variable
    data = reshape([raw{:}], size(raw));

    % Allocate imported array to column variable names
    RatNumber = cellVectors(:, 1);
    DepthBin = data(:, 2);
    PeakDirection = data(:, 12);

    % Clear temporary variables
    clearvars data raw cellVectors R;

    nanValues = isnan(PeakDirection);
    RatNumber(nanValues) = [];
    DepthBin(nanValues) = [];
    PeakDirection(nanValues) = [];

    if exist(p.outputDir, 'dir') == 0
        fprintf('Directory %s doesn''t exist. Will try to create it.\n', p.outputDir);
        mkdir(p.outputDir);
    end

    ratNames = containers.Map('KeyType', 'char', 'ValueType', 'single');
    realRatNumber = zeros(1, length(RatNumber));
    ratNameIndex = 0;

    for a = 1:length(RatNumber)
        name = RatNumber{a};
        if isnumeric(name)
            RatNumber{a} = num2str(name);
            name = num2str(name);
        end
        if ratNames.isKey(name)
            realRatNumber(a) = ratNames(name);
            continue;
        end
        ratNames(name) = ratNameIndex;
        realRatNumber(a) = ratNames(name);

        ratNameIndex = ratNameIndex + 1;
    end

    rats = unique(RatNumber);

    % edges_main = deg2rad(p.binWidthDegrees/2):deg2rad(p.binWidthDegrees):2*pi;
    % edges = [0 edges_main];
    % histEdges = 0:deg2rad(p.binWidthDegrees):2*pi;
    binWidth = 360 / p.numBins;
    histEdges = 0:deg2rad(binWidth):2*pi;

    % create figure for further usage
    h = figure();

    fid = fopen(fullfile(p.outputDir, 'meanVectors.xls'), 'w');
    if fid == -1
        error('Failed to open file %s', fullfile(p.outputDir, 'meanVectors.xls'));
    end

    fprintf(fid, 'Animal\tDepth Bin\tMean Vector\n');

    for a = 1:length(rats)
        fprintf('Processing rat ''%s'', %d / %d\n', rats{a}, a, length(rats));

        ratIndex = ratNames(rats{a});
        dataPerRat = find(realRatNumber == ratIndex);

        depthBinPerRat = DepthBin(dataPerRat);
        peakDirectionPerRat = PeakDirection(dataPerRat);

        uniqueDepthBins = unique(depthBinPerRat);

        fprintf('\tFound %u different bins\n', length(uniqueDepthBins));
        for db = 1:length(uniqueDepthBins)
            curDepthBin = uniqueDepthBins(db);

            fprintf('\tProcessing bin %u\n', curDepthBin);

            binIndices = find(depthBinPerRat == curDepthBin);

            lenData = length(binIndices);
            if lenData < p.minCellsPerBin
                fprintf('\tNot enough data, got only %d values. Will skip it.\n', lenData);
                continue;
            end

            directions = peakDirectionPerRat(binIndices);

            set(0, 'CurrentFigure', h); % set current figure, but do not display it
            cla;
            directionsRad = deg2rad(directions);
            [binnedValues, edges] = myrose(directionsRad, p.numBins);

            X = nansum(binnedValues .* cos(edges')) / length(directionsRad);
            Y = nansum(binnedValues .* sin(edges')) / length(directionsRad);
            meanVectLen = sqrt(X^2 + Y^2);

            meanAngle = rad2deg(circ_mean(directionsRad));
            rho = max(binnedValues) * meanVectLen;
            u = rho * cosd(meanAngle);
            v = rho * sind(meanAngle);
            hold on;
            compass(u, v, 'r');
            hold off;
            
            hline = findobj(gca, 'Type', 'line');
            set(hline, 'LineWidth', 1.5)
            
            %% modify arrow size
            ch = get(h, 'Children');
            if length(ch) > 1
                l = get(ch(2), 'Children'); % should have 2 elements in ch: histogram and line
            else
                l = get(ch(1), 'Children');
            end
            data(1, :) = get(l(1), 'XData');
            data(2, :) = get(l(1), 'YData');
            side = data(:, 3) - data(:, 2);
            data(:, 3) = data(:, 2) + (side * p.arrowScale); % make it 50 % shorter
            
            side = data(:, 5) - data(:, 4);
            data(:, 5) = data(:, 4) + (side * p.arrowScale);
            
            set(l(1), 'XData', data(1, :));
            set(l(1), 'YData', data(2, :));

            %%
            fprintf(fid, '%s\t%d\t%f\n', rats{a}, curDepthBin, meanVectLen);

            ttl = sprintf('Animal %s, depth bin %d, mean vector length %f', rats{a}, curDepthBin, meanVectLen);
            title(ttl);

            figName = sprintf('Animal_%s_bin%d', rats{a}, curDepthBin);
            figFile = fullfile(p.outputDir, figName);

            % Make the background of the figure white
            set(h, 'color', [1 1 1]);

            if strcmpi(p.imageFormat, 'fig')
                saveas(gcf, figFile, p.imageFormat);
            else
                dpi = sprintf('%s%u','-r', p.imageDpi);
                dfmt = sprintf('-d%s', p.imageFormat);
                print(h, dpi, dfmt, figFile);
            end
        end
        fprintf('\tDone\n');
    end

    fclose(fid);
    close(h);

    fprintf('Finished\n');
end

function [binnedValues, edges] = myrose(varargin)
    %ROSE   Angle histogram plot.
    %   ROSE(THETA) plots the angle histogram for the angles in THETA.  
    %   The angles in the vector THETA must be specified in radians.
    %
    %   ROSE(THETA,N) where N is a scalar, uses N equally spaced bins 
    %   from 0 to 2*PI.  The default value for N is 20.
    %
    %   ROSE(THETA,X) where X is a vector, draws the histogram using the
    %   bins specified in X.
    %
    %   ROSE(AX,...) plots into AX instead of GCA.
    %
    %   H = ROSE(...) returns a vector of line handles.
    %
    %   [T,R] = ROSE(...) returns the vectors T and R such that 
    %   POLAR(T,R) is the histogram.  No plot is drawn.
    %
    %   See also HIST, POLAR, COMPASS.

    %   Clay M. Thompson 7-9-91
    %   Copyright 1984-2005 The MathWorks, Inc.
    %   $Revision: 5.14.4.6 $  $Date: 2011/07/25 03:49:40 $

    [cax,args,nargs] = axescheck(varargin{:});
    error(nargchk(1,2,nargs,'struct'));

    theta = args{1};
    if nargs > 1, 
      x = args{2}; 
    end

    if ischar(theta)
      error(message('MATLAB:rose:NonNumericInput'));
    end
    theta = rem(rem(theta,2*pi)+2*pi,2*pi); % Make sure 0 <= theta <= 2*pi
    if nargs==1,
      x = (0:19)*pi/10+pi/20;

    elseif nargs==2,
      if ischar(x)
        error(message('MATLAB:rose:NonNumericInput'));
      end
      if length(x)==1,
        x = (0:x-1)*2*pi/x + pi/x;
      else
        x = sort(rem(x(:)',2*pi));
      end

    end
    if ischar(x) || ischar(theta)
      error(message('MATLAB:rose:NonNumericInput'));
    end

    % Determine bin edges and get histogram
    edges = sort(rem([(x(2:end)+x(1:end-1))/2 (x(end)+x(1)+2*pi)/2],2*pi));
    edges = [edges edges(1)+2*pi];
    nn = histc(rem(theta+2*pi-edges(1),2*pi),edges-edges(1));
    nn(end-1) = nn(end-1)+nn(end);
    nn(end) = [];
    
    binnedValues = nn;

    % Form radius values for histogram triangle
    if min(size(nn))==1, % Vector
      nn = nn(:); 
    end
    [m,n] = size(nn);
    mm = 4*m;
    r = zeros(mm,n);
    r(2:4:mm,:) = nn;
    r(3:4:mm,:) = nn;

    % Form theta values for histogram triangle from triangle centers (xx)
    zz = edges;
    
    edges(end) = [];

    t = zeros(mm,1);
    t(2:4:mm) = zz(1:m);
    t(3:4:mm) = zz(2:m+1);

    if ~isempty(cax)
        h = polar(cax,t,r);
    else
        h = polar(t,r);
    end
end

function mu = circ_mean(alpha)
%
% mu = circ_mean(alpha, w)
%   Computes the mean direction for circular data.
%
%   Input:
%     alpha	sample of angles in radians
%     [w		weightings in case of binned angle data]
%     [dim  compute along this dimension, default is 1]
%
%     If dim argument is specified, all other optional arguments can be
%     left empty: circ_mean(alpha, [], dim)
%
%   Output:
%     mu		mean direction
%     ul    upper 95% confidence limit
%     ll    lower 95% confidence limit 
%
% PHB 7/6/2008
%
% References:
%   Statistical analysis of circular data, N. I. Fisher
%   Topics in circular statistics, S. R. Jammalamadaka et al. 
%   Biostatistical Analysis, J. H. Zar
%
% Circular Statistics Toolbox for Matlab

% By Philipp Berens, 2009
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html

    dim = 1;

    % if no specific weighting has been specified
    % assume no binning has taken place
    w = ones(size(alpha));

    % compute weighted sum of cos and sin of angles
    r = sum(w.*exp(1i*alpha),dim);

    % obtain mean by
    mu = angle(r);
end
