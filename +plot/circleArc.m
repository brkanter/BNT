% Plot a circle arc on the current axis
%
function varargout = circleArc(x0, y0, r, start, extent, varargin)
    ax = gca;
    
    holdStatus = ishold(ax);
    hold on;

    % convert angles in radians
    t0  = deg2rad(start);
    t1  = t0 + deg2rad(extent);

    % number of line segments
    N = 60;

    % initialize handles vector
    h = gobjects(length(x0), 1);

    % draw each circle arc individually
    for i = 1:length(x0)
        % compute basis
        t = linspace(t0(i), t1(i), N+1)';

        % compute vertices coordinates
        xt = x0(i) + r(i)*cos(t);
        yt = y0(i) + r(i)*sin(t);
        
        % draw the circle arc
        h(i) = plot(ax, xt, yt, varargin{:});
    end
    
    if holdStatus == false
        hold off;
    end

    if nargout > 0
        varargout = {h};
    end
end