% Plot spikes on top of animal's path
%
% Visualize animals run path for current trial and spikes of particular unit.
%
%  USAGE
%   plot.spikes(unit)
%   unit    2-element vector that contains tetrode and cell number.
%
%   plot.spikes(pos, spikes)
%   pos     position samples matrix, size should be Nx3 or Nx5.
%   spikes  vector of spike timestamps.
%
%  EXAMPLE
%   data.loadSessions('inputfile.txt')
%   units = data.getCells();
%   plot.spikes(units(1, :));
%
%   data.loadSessions('inputfile.txt');
%   units = data.getCells();
%   spikes = data.getSpikeTimes(units(1, :));
%   pos = data.getPositions();
%   plot.spikes(pos, spikes)
%
function spikes(varargin)
    if nargin < 1 || nargin > 2
        error('BNT:numArgs', 'Incorrect number of parameters (type ''help <a href="matlab:help plot.spike">plot.spike</a>'' for details).');
    end

    if nargin == 1
        unit = varargin{1};

        if length(unit) < 2
            error('Parameter ''unit'' should have 2 values (type ''help <a href="matlab:help plot.spikes">plot.spikes</a>'' for details).');
        end

        plot.pathTrial();
        pos = data.getPositions();
        spikes = data.getSpikeTimes(unit);
    else
        pos = varargin{1};
        spikes = varargin{2};
        if size(pos, 2) < 3
            error('Parameter ''pos'' should have at least 3 columns (type ''help <a href="matlab:help plot.spikes">plot.spikes</a>'' for details).');
        end
        if ~isvector(spikes)
            error('Parameter ''spikes'' should be a vector (type ''help <a href="matlab:help plot.spikes">plot.spikes</a>'' for details).');
        end
        plot(pos(:, 2), pos(:, 3), 'Color', [0.7 0.7 0.7]);
        xlim([nanmin(pos(:, 2)) nanmax(pos(:, 2))]);
        ylim([nanmin(pos(:, 3)) nanmax(pos(:, 3))]);
    end

    spkPos = data.getSpikePositions(spikes, pos);

    holded = ishold();
    hold on;
    plot(spkPos(:, 2), spkPos(:, 3), '.r', 'MarkerSize', 15);

    if holded ~= 1
        hold off;
    end
end