% plot 1D fields
function fields1D(map, fields, mapPlotOpt)
    if nargin < 3
        mapPlotOpt = {};
    end
    cla;
    plot(map.x(1:end-1), map.z, mapPlotOpt{:});
    h = gcf;
    hold on;
    axesYLim = h.CurrentAxes.YLim;

    for f = 1:length(fields)
        fStart = fields(f).col(1);
        fEnd = fields(f).col(end);
        width = map.x(fEnd) - map.x(fStart);
        height = axesYLim(2) - axesYLim(1);
        fieldPoly = rectToPolygon([map.x(fStart) axesYLim(1) width height]);
        hRect = patch(fieldPoly(:, 1), fieldPoly(:, 2), 'r');
        set(hRect, 'faceAlpha', 0.3);
    end
    hold off;
    ylim(axesYLim);
    xlabel('Track position, cm');
    ylabel('Firing rate, Hz');
end