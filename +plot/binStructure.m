% Overlay path plot with lines indicating bins of a firing map
%
%  USAGE
%   plot.binStructure(binWidth, direction)
%   pos             Position samples, [t x y]
%   binWidth        Width of a bin
%   direction       Optional direction Values could be 'v', 'h'.
%                   If omitted both vertical and horizontal lines
%                   are plotted.
%
function binStructure(pos, binWidth, direction)

    if nargin < 3
        direction = 'vh';
    end

    x = pos(:, 2);
    y = pos(:, 3);

    maxX = nanmax(x);
    maxY = nanmax(y);
    xStart = nanmin(x);
    yStart = nanmin(y);
    xLength = maxX - xStart;
    yLength = maxY - yStart;
    start = min([xStart, yStart]);
    tLength = max([xLength, yLength]);

    nBinsX = ceil(tLength / binWidth);
    nBinsY = ceil(tLength / binWidth);

    xLines = xStart:binWidth:xStart + binWidth*nBinsX;
    yLines = yStart:binWidth:yStart + binWidth*nBinsY;

    if strcmpi(direction, 'v')
        plot.lines(xLines, 'v', '--r');
    elseif strcmpi(direction, 'h')
        plot.lines(yLines, 'h', '--r');
    elseif strcmpi(direction, 'vh')
        plot.lines(xLines, 'v', '--r');
        plot.lines(yLines, 'h', '--r');
    end
end