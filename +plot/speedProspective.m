% Population prospective plot for speed data
%
% This function plots two things on a single plot:
% 1. Histogram of maximum time shifts/prospectiveness across cells within range [-1.05 1.05] sec.
%    This means that if maximum shift of some cell was outside of that range, then data from
%    this cell is not used on the histogram plot.
% 2. Mean prospective curve. This is a mean of shifted correlations over all cells. The curve
%    is showed on the same time interval as the histogram.
%
%  USAGE
%   plot.speedProspective(maxTimeShifts, shiftBins_sec, meanProspectiveCurve, plotXLimits)
%   maxTimeShifts           Nx1 vector, values of maximum time shifts per cell. Must be given in seconds!
%   shiftBins_sec           Mx1 vector, x-values for mean prospective curve. Must be given in seconds!
%   meanProspectiveCurve    Mx1 vector, mean prospective curve.
%   plotXLimits             [l1 l2], limits in seconds for the final plot. Determines the visible range of the
%                           plot. For example, [-0.6 0.6] if you want to see the data with offsets of 600 ms.
%
%  NOTE!
%   Although all values should be provided in seconds, the x-axis of the final plot is in ms.
%
function speedProspective(maxTimeShifts, shiftBins_sec, meanProspectiveCurve, plotXLimits)
    gl = 2; % aspect ratio of plots (see golden)
    if isempty(maxTimeShifts) || all(isnan(maxTimeShifts))
        text(0.4, 0.5, 'no cells', 'fontsize', 20);
        axis([0 1 0 1]);
        return;
    end
    edges = -1.05:0.1:1.05; % taken from original code.
    edges = edges * 1e3; % make it in ms
    plotXLimits = plotXLimits * 1e3;

    histogram(maxTimeShifts*1e3, edges, 'edgecolor', 'none', 'facecolor', [0.8 0.8 0.5], 'faceAlpha', 1);
    hold on;
    plot.lines(0, 'v', 'color', 0.4 * ones(1, 3));
    curYLim = ylim;
    plotMaxY = curYLim(2);
    axis([plotXLimits 0 plotMaxY]);
    plot.golden(gca, gl);
    set(gca, 'Box', 'off');
    hold off;

    % average curve
    % plot it using another axis, so that we will have axis y-labels on the right
    ax2 = axes('yaxislocation', 'right', 'ycolor', [0.7 0 0.7], 'xtick', [], 'color', 'none');
    hold(ax2, 'on');
    plot(ax2, shiftBins_sec*1e3, meanProspectiveCurve, 'Linewidth', 3, 'color', [0.7 0 0.7]); % time is in ms
    ax2.XLim = plotXLimits;
    plot.golden(ax2, gl);
    hold(ax2, 'off');
end