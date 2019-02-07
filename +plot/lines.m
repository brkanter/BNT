% Plot vertical (resp. horizontal) lines at listed x (resp. y).
%
%  USAGE
%
%    p = plot.lines(positions, direction, options)
%
%    positions      list of abscissae/ordinates
%    direction      optional direction: 'h' or 'v' (default = 'v')
%    <options>      options for function <a href="matlab:help plot">plot</a>.
%                   Additional option is 'limits', that defines line on an
%                   opposite axis. It should be a vector of two values that
%                   define begin and end of line.
%    p              handle to the line. See NOTES.
%
%  EXAMPLE
%
%  Plot two vertical lines at positions 3 and 5. The lines will stretch 
%  from 0 to 10 on y-axis:
%   axis([0 10 0 10]);
%   plot.lines([3 5], 'v');
%
%  Plot two vertical lines at positions 3 and 5. The lines will stretch
%  from 2 to 5 on y-axis:
%   axis([0 10 0 10]);
%   plot.lines([3 5], 'v', 'limits', [2 5]);
%
%  NOTES
%   The HandleVisibility property of the line object is set to "off", so it does not appear
%   on legends, and it is not findable by findobj. Specifying an output argument causes the 
%   function to return a handle to the line, so it can be manipulated or deleted.

% Copyright (C) 2008-2011 by Michael Zugaro
%           (C) 2013 by Vadim Frolov
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
function p = lines(positions, direction, varargin)

    if nargin < 1
        error('Incorrect number of parameters (type ''help <a href="matlab:help plot.lines">plot.lines</a>'' for details).');
    end
    if nargin < 2
        direction = 'v';
    else
        direction = lower(direction);
    end
    if min(size(positions)) > 2
        error('List of abscissae/ordinates is not a vector (type ''help <a href="matlab:help plot.lines">plot.lines</a>'' for details).');
    else
        positions = positions(:);
    end
    
    values = [];
    for i = 1:length(varargin)
        if strcmpi(varargin{i}, 'limits')
            values = varargin{i+1};
            varargin(i:i+1) = []; % remove it
            break
        end
    end

    g = ishold(gca);
    hold on;
    p = gobjects(size(positions, 1), 1);
    if strcmpi(direction,'v')
        yLim = ylim;
        if ~isempty(values)
            yLim = values;
        end
        for i = 1:size(positions, 1)
            p(i) = plot([positions(i, 1) positions(i, 1)], yLim, varargin{:});
            set(p(i), 'handlevisibility', 'off');
        end
    else
        xLim = xlim;
        if ~isempty(values)
            xLim = values;
        end
        for i = 1:size(positions, 1)
            p(i) = plot(xLim,[positions(i, 1) positions(i, 1)], varargin{:});
            set(p(i), 'handlevisibility', 'off');
        end
    end

    if g == false
        hold off;
    end
end
