% Get spike timestamps
%
% This function returns internally-stored spike data of a current trial.
%
%  USAGE
%
%    spikes = data.getSpikeTimes(units, <options>)
%
%    units          optional list of units, i.e. [electrode group, cluster] pairs;
%                   special conventions:
%                     cluster = -1   all clusters
%                     cluster = -2   all clusters except artefacts (cluster 0)
%                     cluster = -3   all clusters except artefacts (cluster 0)
%                                    and MUA (cluster 1)
%    <options>      optional list of property-value pairs (see table below)
%
%    =========================================================================
%     Properties    Values
%    -------------------------------------------------------------------------
%     'output'      'time' returns only timestamps, 'full' lists electrode
%                   group and cluster for each spike (default = 'time'),
%                   'fullLinear' returns Nx3 matrix of spike timestamps,
%                   tetrode numbers and clusters (cluster indices are linear
%                   from 1 to number of clusters).
%    =========================================================================
%
%  EXAMPLES
%
%    % timestamps for all spikes
%    s = data.getSpikeTimes;
%
%    % timestamps for units [1 7] and [4 3]
%    s = data.getSpikeTimes([1 7; 4 3]);
%
%    % timestamps for all units on electrode group 5 and unit [6 3]
%    s = data.getSpikeTimes([5 -1; 6 3]);
%
%    % timestamps for all units on electrode group 5, except artefacts
%    s = data.getSpikeTimes([5 -2]);
%
%    % timestamps, electrode groups and clusters, for all spikes
%    s = data.getSpikeTimes('output', 'full');
%
%    Assume you have cells 6 1, 6 2, and 6 6. You want to get spikes for
%    all these cells. You type:
%     s = data.getSpikeTimes([6 -1], 'output', 'full');
%    The 3 column will contain values from a set [1 2 6].
%    If you call this function as
%     s = data.getSpikeTimes([6 -1], 'output', 'fullLinear');
%    then the 3 column will contain values from a set [1 2 3].
%   
%  NOTE
%
%    An electrode group is an ensemble of closely spaced electrodes that record from
%    the same neurons, e.g. a single wire electrode, or a wire tetrode, or a multisite
%    silicon probe, etc.
%
%  SEE
%
%    See also analyses.map

function spikes = getSpikeTimes(units, varargin)
    import helpers.isstring;
    import helpers.isimatrix;

    global gBntData;
    global gCurrentTrial;
    global gBntInit;

    if isempty(gBntInit) || gBntInit == false
        InitBNT;
    end
    
    if isempty(gBntData{gCurrentTrial}.spikes)
        spikes = [];
        return;
    end

    % Default values
    output = 'time';

    % Optional parameter
    if ischar(units)
        varargin = {units, varargin{:}};
        units = []; % all
    else
        if ~isempty(units) && (~isimatrix(units) || size(units, 2) ~= 2),
            error('Incorrect list of units (type ''help <a href="matlab:help data.getSpikeTimes">data.getSpikeTimes</a>'' for details).');
        end
    end

    % Parse parameter list
    for i = 1:2:length(varargin),
        if ~ischar(varargin{i}),
            error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help data.getSpikeTimes">data.getSpikeTimes</a>'' for details).']);
        end
        switch(lower(varargin{i})),
            case 'output',
                output = lower(varargin{i+1});
                if ~isstring(output, 'time', 'full', 'fulllinear'),
                    error('Incorrect value for property ''output'' (type ''help <a href="matlab:help data.getSpikeTimes">data.getSpikeTimes</a>'' for details).');
                end

            otherwise,
                error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help data.getSpikeTimes">data.getSpikeTimes</a>'' for details).']);
        end
    end

    spikes = gBntData{gCurrentTrial}.spikes;

    % Selected units only
    if ~isempty(units)
        nUnits = size(units, 1);
        selected = zeros(size(spikes(:, 1)));
        for i=1:nUnits
            tetrode = units(i, 1);
            cluster = units(i, 2);
            switch cluster
                case -1
                    selected = selected | spikes(:, 2) == tetrode;

                case -2
                    selected = selected | (spikes(:, 2) == tetrode & spikes(:, 3) ~= 0);

                case -3
                    selected = selected | (spikes(:, 2) == tetrode & spikes(:, 3) ~= 0 & spikes(:, 3) ~= 1);
                otherwise
                    selected = selected | (spikes(:, 2) == tetrode & spikes(:, 3) == cluster);
            end
        end
        spikes = spikes(selected, :);
    end

    if strcmpi(output, 'time'),
        spikes = spikes(:, 1);
    elseif strcmpi(output, 'fullLinear')
        [~, ia] = unique(spikes(:, 3), 'stable');
        lenSpikes = length(spikes(:, 3));
        lenIa = length(ia);
        for i = 1:lenIa
            startInd = ia(i);
            if i+1 <= lenIa
                endInd = ia(i+1) - 1;
            else
                endInd = lenSpikes;
            end
            spikes(startInd:endInd, 3) = i;
        end
    end

    if ~isempty(find(spikes(:, 1) == 0, 1))
        warning('BNT:spikeZeros', 'There are spike timestamps that have value of 0! This is very suspicious!');
    end
end
