% Plot a color map
%
% Plots a color map (e.g. the firing field of a place field)
%
%  USAGE
%   plot.colorMap(data, dimm, <options>)
%
%   data           data matrix MxN. M corresponds to rows(y), N to columns(x).
%   dimm           optional luminance map
%   <options>      optional list of property-value pairs (see table below)
%
%   =========================================================================
%    Properties    Values
%   -------------------------------------------------------------------------
%    'x'           abscissae
%    'y'           ordinates
%    'threshold'   dimm values below this limit are zeroed (default = 0.01)
%    'cutoffs'     lower and upper cutoff values ([] = autoscale, default)
%    'bar'         draw a color bar (default = 'on')
%    'ydir'        either 'normal' (default) or 'reverse' (useful when the
%                  x and y coordinates correspond to spatial positions,
%                  as video cameras measure y in reverse direction)
%    'bgColor'     Background color. Set to empty in order not to set background.
%                  Default background color is black. Background color will
%                  be visible plot limits are extended. For example, if you
%                  plot a map with x in range [0 50], and then change x
%                  limits to [0 100], then area under [50 100] will be
%                  visualized in bgColor.
%   'nanColor'     Color that is assigned to NaN values. Set to empty (omit)
%                  in order to use default color, which is white.
%                  Any NaN value presented on a map is going to be plotted
%                  using nanColor.
%   'axes'         Creates the plot in the axes specified by 'axes' instead of the
%                  current axes (gca).
%   =========================================================================
%
%  NOTE
%
%   The luminance map is used to dimm the color map. A single scalar value
%   is interpreted as a constant luminance map. If this parameter is not
%   provided, normal equiluminance is assumed (i.e. scalar value of 1).
%
%   NaN values in map are displayed with white color.
%
%  EXAMPLE
%
%   fm = analyses.map(positions, spikes);      % firing map for a place cell
%   figure; plot.colorMap(fm.z, fm.time);      % plot, dimming with occupancy map
%
%  SEE
%   See also analyses.map.

% Copyright (C) 2004-2011 by Michaël Zugaro
% (C) 2013 by Vadim Frolov
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
function colorMap(data, dimm, varargin)
    if isempty(data)
        cla;
        return;
    end
    % Default values
    cutoffs = [];
    threshold = 0.01;
    drawBar = 'on';
    [y, x] = size(data);
    x = 1:x; y = 1:y;
    ydir = 'normal';
    bgColor = [0 0 0];
    nanColor = [1 1 1];
    axesToUse = [];

    if nargin < 1,
        error('Incorrect number of parameters (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
    end
    if nargin == 1,
        dimm = 1;
    end
    if isa(dimm,'char')
        varargin = [{dimm} varargin];
        dimm = 1;
    end

    % Parse parameter list
    for i = 1:2:length(varargin)
        if ~ischar(varargin{i})
            error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).']);
        end
        switch (lower(varargin{i}))
            case 'threshold',
                threshold = varargin{i+1};
                if ~helpers.isdscalar(threshold, '>=0')
                    error('Incorrect value for property ''threshold'' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
                end

            case 'x',
                x = varargin{i+1};
                if ~helpers.isdvector(x)
                    error('Incorrect value for property ''x'' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
                end

            case 'y',
                y = varargin{i+1};
                if isempty(y)
                    y = 1:size(data, 1);
                end
                if ~helpers.isdvector(y)
                    error('Incorrect value for property ''y'' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
                end

            case 'cutoffs',
                cutoffs = varargin{i+1};
                numNans = length(find(isnan(cutoffs)));
                switch numNans
                    case 1
                        if ~helpers.isdvector(cutoffs, '#1')
                            error('Incorrect value for property ''cutoffs'' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
                        end
                    case 2
                        cutoffs = [];
                    otherwise
                        if ~isempty(cutoffs) && ~helpers.isdvector(cutoffs, '#2', '<')
                            error('Incorrect value for property ''cutoffs'' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
                        end
                end

            case 'bar',
                drawBar = lower(varargin{i+1});
                if ~helpers.isstring(drawBar, 'on', 'off')
                    error('Incorrect value for property ''bar'' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
                end

            case 'ydir',
                ydir = lower(varargin{i+1});
                if ~helpers.isstring(ydir,'normal','reverse')
                    error('Incorrect value for property ''ydir'' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).');
                end

            case 'bgcolor',
                bgColor = varargin{i+1};

            case 'nancolor',
                if ~isempty(varargin{i+1})
                    nanColor = varargin{i+1};
                end
                
            case 'axes'
                if ~isempty(varargin{i+1})
                    axesToUse = varargin{i+1};
                end

            otherwise
                error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help plot.colorMap">plot.colorMap</a>'' for details).']);
        end
    end

    if ~isempty(cutoffs),
        if ~isnan(cutoffs(1))
            m = cutoffs(1);
        else
            m = min(min(data));
        end
        if ~isnan(cutoffs(2))
            M = cutoffs(2);
        else
            M = max(max(data));
        end
    else
        m = min(min(data));
        M = max(max(data));
    end
    if m == M, M = m+1; end
    if isnan(m), m = 0; M = 1; end

    if length(dimm) == 1,
        dimm = dimm * ones(size(data));
    end
    
    if isempty(axesToUse) || ~ishandle(axesToUse)
        a = gca;
    else
        a = axesToUse;
    end
    colormap(a, 'jet');

    if ~isempty(find(isnan(data), 1))
        % we need to plot NaN values with white color. In order to do this:
        % 1. add white to the current color map
        % 2. assign nan values a new value, which is less than a minimum (m) by one step in the colour
        %    space.
        cmap = colormap(a);
        cStep = (M - m) / (size(cmap, 1) + 1); % step in the colour space
        m = m - cStep*1.1;
        data(isnan(data)) = m;

        if ~isequal(cmap(1, :), nanColor)
            cmap = [nanColor; cmap];
            %colormap(a, );
        end
    else
        cmap = colormap(a, 'jet');
    end

    clims = [m M];
    if islogical(clims)
        clims = double(clims);
    end
    p = imagesc(x, y, data, clims);
    if ~isempty(bgColor)
        set(a, 'color', bgColor);
    end
    if any(dimm~=1)
        alpha(p, 1 ./ (1 + threshold./(dimm+eps)));
    end

    set(a, 'ydir', ydir, 'tickdir', 'out', 'box', 'off');
    colormap(a, cmap);

    if strcmp(drawBar, 'on')
        b = colorbar('vert');
        if verLessThan('matlab', '8.4.0')
            % R2014a or earlier
            set(b, 'tickdir', 'out', 'box', 'off', 'ycolor', 'k');
            axes(a);
        else
            set(b, 'tickdir', 'out', 'box', 'off', 'color', 'k');
        end
    end
end
