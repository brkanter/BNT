function triangulation(dt, varargin)
    selected = false(nargin, 1);
    showIndex = true;

    for i = 1:length(varargin)
        if strcmpi(varargin{i}, 'index')
            indexStr = varargin{i+1};
            showIndex = strcmpi(indexStr, 'on');
            selected(i:i+1) = true;
        end
    end

    inpCopy = varargin;
    inpCopy(selected) = [];

    hold on;
    for i = 1:size(dt, 1)
        pts = general.trianglePoints(dt, i);
        cp = centroid(pts); % matgeom
        drawPolygon(pts, inpCopy{:});
        if showIndex
            text(cp(1), cp(2), num2str(i), 'Color', [1 1 1]);
        end
    end
    hold off;
end