% Plot spike density for linear track (1 dimension)
%
% Spike density is represented by a line with vertical ticks, where each vertical tick
% indicates one spike. The data is arranged to start from 0.
%
%  USAGE
%   p = plot.spikeDensity(spikes, positions, y, options)
%   spikes          Matrix with spike positions. Could be an output of <a href="matlab:help data.getSpikePositions">data.getSpikePositions</a>.
%   positions       Matrix with position data. Positions can be in form [X], [X Y] or [T X Y],
%                   where X - x-coordinates, Y - y-coordinates, and T - timestamps.
%   <options>       options for function <a href="matlab:help plot">plot</a>.
%                   Additional value 'y', 1x2 vector. Defines the y-coordinate value limits at which
%                   the spike density is plotted. Allows to plot several spike densities
%                   on one figure. Default value is 0.
%   p               Handles to line objects.
%
%  SEE
%   See also data.getSpikePositions, data.getPositions, plot.lines
%
function p = spikeDensity(spikes, positions, varargin)

    if nargin < 2
        error('Incorrect number of parameters (type ''help <a href="matlab:help plot.spikeDensity">plot.spikeDensity</a>'' for details).');
    end
    
    y = [-1 -1];
    for i = 1:length(varargin)
        if strcmpi(varargin{i}, 'y')
            y = varargin{i+1};
            varargin(i:i+1) = [];
            if length(y) ~= 2
                error('Incorrect value for property ''y'' (type ''help <a href="matlab:help plot.spikeDensity">plot.spikeDensity</a>'' for details).');
            end
            break;
        end
    end

    if size(positions, 2) <= 2
        % assume positions == [X Y] or positions == [X]
        posx = positions(:, 1);
    elseif size(positions, 2) >= 3
        % assume positions == [T X Y]
        posx = positions(:, 2);
    end

    minx = 0;
    maxx = max(posx) - min(posx);
    
    axisLimits = axis();
    if maxx < axisLimits(2)
        maxx = axisLimits(2);
    end

    spkx = spikes(:, 2);
    spkx = spkx - nanmin(posx);

    limits = y;
    if y(1) == -1
        axis([minx, maxx, 0, 1]);
        limits = [0 1];
        y = 0;
    end
    
    line([minx maxx], [y(1) y(1)], varargin{:}); % base line
    p = plot.lines(spkx, 'v', 'limits', limits, varargin{:});
end
