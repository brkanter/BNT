% Plot all rate maps in stack individually
%
% Plots individual rate maps of a population vector as a single figure.
% Might be useful to visualize population vectors created based on linear track.
%
%  USAGE
%   h = plot.population(stack, <options>)
%   stack       Population vector
%   <options>   optional list of property-value pairs (see table below)
%
%   =========================================================================
%    Properties    Values
%   -------------------------------------------------------------------------
%    'x'                abscissae. If not empty, specifies xtick values.
%    'stackName'        Name of the population vector. Will be added as plot title
%                       if specified.
%    'normalization'   'on' or 'off'. If set to 'on' then the resulting figure is
%                       normalized to population min/max firing rate. If set to
%                       'off', then each cell has it's own color space.
%                       Default value is 'on'.
%   =========================================================================
%
%   h           handle to the resulting figure.
%
function h = population(stack, varargin)
    inp = inputParser;
    defaultNormalization = 'on';

    checkOnOff = @(x) helpers.isstring(x, 'on', 'off');

    % fill input parser object
    addRequired(inp, 'stack');
    addParameter(inp, 'x', '');
    addParameter(inp, 'stackName', '', @ischar);
    addParameter(inp, 'normalization', defaultNormalization, checkOnOff);

    parse(inp, stack, varargin{:});
    stackName = inp.Results.stackName;
    x = inp.Results.x;
    normalize = strcmpi(inp.Results.normalization, 'on');

    [~, ~, numCells] = size(stack);
    h = figure();
    set(0, 'CurrentFigure', h); % set current figure, but do not display it
    ax = get(gca, 'Position');
    
    if normalize
        % find out rate range
        maxR = 0;
        minR = 999;
        for i = 1:numCells
            maxR = nanmax([maxR nanmax(stack(:, :, i))]);
            minR = nanmin([minR nanmin(stack(:, :, i))]);
        end
        cutoffs = [minR maxR];

        if size(stack, 1) == 1 || size(stack, 2) == 1
            sizes = size(stack);
            newSize = sizes(sizes > 1);
            stack = reshape(stack, newSize)';
            if ~isempty(x)
                plot.colorMap(stack, 'x', x);
            else
                plot.colorMap(stack);
            end
            if isempty(stackName)
                title(sprintf('Population vector. Rate: %.2f - %.2f Hz', minR, maxR));
            else
                title(sprintf('Population vector for ''%s''. Rate: %.2f - %.2f Hz', stackName, minR, maxR));
            end
            if isempty(x)
                xlabel('Bins');
            else
                xlabel('Units of position, notmally cm');
            end
            ylabel('Cells');
            return;
        end
    end

    for i = 1:numCells
        subplot(numCells, 1, i);
        if ~normalize
            cutoffs = [nanmin(nanmin(stack(:, :, i))) nanmax(nanmax(stack(:, :, i)))];
        end
        dC = diff(cutoffs);
        if dC <= 0            
            cutoffs(2) = cutoffs(1) + dC + 0.1;
        end
        if i == numCells && ~isempty(x)
            if isempty(x)
                plot.colorMap(stack(:, :, i), 'cutoffs', cutoffs, 'bar', 'off', 'bgColor', []);
            else
                plot.colorMap(stack(:, :, i), 'cutoffs', cutoffs, 'bar', 'off', 'x', x, 'bgColor', []);
            end
            set(gca, 'ytick', [], 'ycolor', [1 1 1]);
        else
            if isempty(x)
                plot.colorMap(stack(:, :, i), 'cutoffs', cutoffs, 'bar', 'off', 'bgColor', []);
            else
                plot.colorMap(stack(:, :, i), 'cutoffs', cutoffs, 'bar', 'off', 'x', x, 'bgColor', []);
            end
            set(gca, 'visible', 'off');
        end
    end
    % make tight axis by expanding them, so there is no space between them
    % also make sure that title won't be displayed on top of any axis
    allAxis = findobj(h, 'type', 'axes');
    axisHeight = ax(4);
    newHeight = axisHeight / numCells;
    newY = (0:newHeight:(numCells-1)*newHeight) + allAxis(1).Position(2);
    for b = 1:numCells
        allAxis(b).Position(2) = newY(b);
    end
    arrayfun(@(x) adjustHeight(x, newHeight), allAxis);
    
    if isempty(stackName)
        if normalize
            plot.suplabel(sprintf('Population vector. Rate: %.2f - %.2f Hz', minR, maxR), 't', ax);
        else
            plot.suplabel('Population vector', 't', ax);
        end
    else
        if normalize
            plot.suplabel(sprintf('Population vector for ''%s''. Rate: %.2f - %.2f Hz', stackName, minR, maxR), 't', ax);
        else
            plot.suplabel(sprintf('Population vector for ''%s''', stackName), 't', ax);
        end
    end
    if isempty(x)
        plot.suplabel('Bins', 'x', ax);
    else
        plot.suplabel('Units of position, normally cm', 'x', ax);
    end
    plot.suplabel('Cells', 'y', ax);
end

function adjustHeight(ax, newHeight)
    ax.Position(4) = newHeight;
end
