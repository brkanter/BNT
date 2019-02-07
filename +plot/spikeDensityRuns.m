% Plot spike density for several runs (same direction) on a linear track
%
% This function makes an overview plot of spikes on a linear track for several runs.
% Each run/lap is represented by it's own line. Spikes are plotted as short vertical lines (ticks).
% Note that linear track line can be shorter than a real linear track. This happens because
% runs a detected on a linear track using threshold(s). Nothing is plotted for areas
% filtered out by threshold(s).
%
%  USAGE
%   plot.spikeDensityRuns(pos, runSpikes, runIndices, <options>)
%   pos             Nx3 or Nx5 position matrix in form [t x y] or [t x y x1 y1].
%                   The matrix should contain all animal positions on a linear track,
%                   but only time and first x column are used.
%   runSpikes       Mx3 matrix of spikes ([t x y]), output of function data.getSpikePositions.
%   runIndices      Nx1 vector, output of function analyses.findRunsByThreshold. Vector that indicates
%                   run/lap belonging of position sample. All zero values are for no-run periods, all 1 values
%                   indicate belongingness to the first lap, all 2 values indicate belongingness to the second
%                   lap. And so on. The number of rows is the same as the number of rows in pos.
%   <options>       Optional list of property-value pairs (see table below)
%
%   ==============================================================================================
%    Properties    Values
%   ----------------------------------------------------------------------------------------------
%    'spikeHeight'  Normalized line height of spike ticks. Defines the
%                   length of a spike tick between two runs. Possible range 0..1.
%                   Default is 0.2.
%    'limits'       [xMin xMax] If provided, then data is plotted within given limits.
%                   Default [min(pos(:, 2)) max(pos(:, 2))].
%    'lapLabels'    'on' or 'off'. If 'on', then lap labels will be added
%                   along y-axis. Default is 'on'.
%    'lineStyle'    Cell array of Lineseries Properties. It is used to plot both runs and spikes.
%                   Default value is:
%                   {'Color', [0 0 0.8], 'LineWidth', 1};
%   ==============================================================================================
%
% See also data.getPositions, data.getSpikePositions
%
function spikeDensityRuns(pos, runSpikes, runIndices, varargin)
    inp = inputParser;
    defaultSpikeHeight = 0.2;
    defaultLimits = [];
    defaultLapLabels = 'on';
    defaultLineStyle = {'color', [0 0 0.8], 'linewidth', 1};

    addRequired(inp, 'pos', @(x) size(x, 2) == 3 || size(x, 2) == 5);
    addRequired(inp, 'runSpikes', @(x) size(x, 2) == 3);
    addRequired(inp, 'runIndices');
    addParameter(inp, 'spikeHeight', defaultSpikeHeight, @(x) x > 0 && x < 1);
    addParameter(inp, 'limits', defaultLimits, @(x) length(x) == 2);
    addParameter(inp, 'lapLabels', defaultLapLabels, @(x) helpers.isstring(x, 'on', 'off'));
    addParameter(inp, 'lineStyle', defaultLineStyle, @(x) iscell(x));

    parse(inp, pos, runSpikes, runIndices, varargin{:});

    lineSpacing = 1;
    spikeHeight = inp.Results.spikeHeight;
    trackLimits = inp.Results.limits;
    showLapLabels = strcmpi(inp.Results.lapLabels, 'on');
    lineStyle = inp.Results.lineStyle;
    
    if isempty(trackLimits)
        trackLimits = [nanmin(pos(:, bntConstants.PosX)) nanmax(pos(:, bntConstants.PosX))];
    end
    
    numLaps = max(runIndices);
    if isempty(numLaps) || numLaps == 0
        xlim(trackLimits);
        h = text(nanmean(trackLimits), nanmean(ylim), 'no runs!');
        % center text
        halfWidth = h.Extent(3) / 2;
        h.Position(1) = h.Position(1) - halfWidth;
        return;
    end
    
    if spikeHeight >= lineSpacing
        tenPercent = 0.1 * lineSpacing;
        spikeHeight = lineSpacing - tenPercent;
    end

    axis([trackLimits(1) trackLimits(2) 0 numLaps*lineSpacing]);
    for k = 1:numLaps
        % lapStartInd = runIndices(k, 1);
        % lapEndInd = runIndices(k, 2);
        lapStartInd = find(runIndices == k, 1, 'first');
        lapEndInd = find(runIndices == k, 1, 'last');

        validSpikes = runSpikes(:, 1) >= pos(lapStartInd, bntConstants.PosT) & ...
                runSpikes(:, 1) <= pos(lapEndInd, bntConstants.PosT);
        lapSpikePos = runSpikes(validSpikes, :);

        lapMinX = nanmin(pos(lapStartInd:lapEndInd, bntConstants.PosX));
        lapMaxX = nanmax(pos(lapStartInd:lapEndInd, bntConstants.PosX));

        lowerBound = (k-1) * lineSpacing;
        upperBound = lowerBound + spikeHeight;
        plot.lines(lowerBound, 'h', 'limits', [lapMinX lapMaxX], lineStyle{:});
        plot.lines(lapSpikePos(:, 2), 'v', 'limits', [lowerBound upperBound], lineStyle{:});
    end
    xlabel('Length [cm]');
    ylabel('Lap');
    if showLapLabels
        ticks = 0:lineSpacing:numLaps*lineSpacing; ticks(end) = [];
        tickLabels = cellstr(num2str((1:numLaps)'));
        if numLaps > 10
            ticks = ticks(1:2:end);
            tickLabels = cellstr(num2str((1:2:numLaps)'));
        end
        set(gca, 'YTick', ticks);
        set(gca, 'YTickLabel', tickLabels); % change tick labels to laps
    else
        set(gca, 'YTickLabel', []);
    end
    set(gca, 'TickLength', [0 0.025]);
end