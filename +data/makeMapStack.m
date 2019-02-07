% Make population stack of rate maps for a trial
%
% Calculates rate maps for all cells in given trial and
% returns it in 3D matrix.
%
%  USAGE
%   stack = data.makeMapStack(ind, nBins, <options>)
%   ind         Index of a trial that is used to calculate the stack. Could be
%               a single number or a vector. If vector is provided, then output
%               will be a combined stack.
%   nBins       Single value or a vector of two elements. Specifies
%               number of bins for the rate map. If single values is
%               provided, then rate map will be squared.
%   <options>   optional list of property-value pairs. Some options are used by
%               makeMapStack function itself, all other are passed to underlying
%               function that calculates the rate map. There are two possible
%               underlying functions. Which one to use is determined by option
%               'adaptive'. Options that are used by makeMapStake are:
%
%   =========================================================================
%    Property      Value
%   -------------------------------------------------------------------------
%    'type'         '1d' if map should be calculated for 1D case. '2d' or any
%                   other value for 2D case. Default is 2D.
%    'adaptive'     'on' will use adaptive smoothed rate maps. 'off' will use
%                   regular rate maps. Default is 'off'. If adaptive smoothing is used,
%                   then type can not be '1d'. If adaptive is used you should pass
%                   value for bin width (via varargin) along with number of bins (via nBins).
%    'pos'          Cell array, arguments for underlying call of data.getPositions
%                   function. Default is no arguments. Example: 'pos', {'speedFilter', [12.5 0]}
%   =========================================================================
%
%   stack       3D matrix. First and second dimensions correspond to the
%               dimensions of a rate map. Volume of the third dimension equals
%               number of cells, i.e. stack(:, :, 2) - rate map for second cell.
%
%  EXAMPLES
%
%   Make stack for 1D case with speed filtered positions:
%   data.makeMapStack(1, 30, 'type', '1d', 'pos', {'speedFilter', [12.5 0]});

% Copyright (c) Vadim Frolov, 2013. vadim.frolov@ntnu.no
function stack = makeMapStack(ind, nBins, varargin)

    if nargin < 2 || mod(length(varargin), 2) ~= 0,
      error('Incorrect number of parameters (type ''help <a href="matlab:help data.makeMapStack">data.makeMapStack</a>'' for details).');
    end

    % default parameters
    type = '2d';
    posArgs = {};
    adaptive = false;
    
    deleteIndices = [];
    for i = 1:2:length(varargin)
        if ~ischar(varargin{i})
            error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help data.makeMapStack">data.makeMapStack</a>'' for details).']);
        end

        switch(lower(varargin{i}))
            case 'type'
                type = lower(varargin{i+1});
                deleteIndices(end+1) = i;
                deleteIndices(end+1) = i+1;
                %varargin(i:i+1) = [];

            case 'adaptive'
                adp = varargin{i+1};
                adaptive = strcmpi(adp, 'on');
                deleteIndices(end+1) = i;
                deleteIndices(end+1) = i + 1;

            case 'pos'
                posArgs = varargin{i+1};
                deleteIndices(end+1) = i;
                deleteIndices(end+1) = i+1;
%                 varargin(i:i+1) = [];
        end
    end
    varargin(deleteIndices) = [];

    oneDim = strcmp(type, '1d');
    if length(nBins) > 1
        if oneDim
            warning('Should calculate the rate map for 1D data, but 2D bin size is provided. Will reduce the bin size to one dimension.');
            stackSize = [1 nBins(1)];
        else
            stackSize = [nBins(2) nBins(1)]; % in Matlab size is (y, x)
        end
    else
        if oneDim
            stackSize = [1 nBins];
        else
            stackSize = [nBins nBins];
        end
    end

    if adaptive && oneDim
        error('Adaptive smoothing can not be calculated for 1D position samples');
    end

    originalTrial = data.getCurrentTrialNum();
    
    % calculate final stack size
    numCells = 0;
    for i = 1:length(ind)
        data.setTrial(ind(i));
        numCells = numCells + size(data.getCells(), 1);
    end
    stack = zeros([stackSize, numCells]);
    
    numEntries = 1;
    for i = 1:length(ind)
        curInd = ind(i);

        data.setTrial(curInd);
        units = data.getCells();
        numCells = size(units, 1);

        pos = data.getPositions(posArgs{:});
        for c = 1:numCells
            unit = units(c, :);
            spikes = data.getSpikeTimes(unit);
            if ~isempty(spikes)
                if oneDim
                    map = analyses.map(pos(:, 1:2), spikes, 'nBins', nBins, varargin{:});
                else
                    if adaptive
                        spkPos = data.getSpikePositions(spikes, pos);
                        map = analyses.mapAdaptiveSmoothing(pos, spkPos, varargin{:});
                    else
                        map = analyses.map(pos, spikes, 'nBins', nBins, varargin{:});
                    end
                end
            else
                map.z = zeros(stackSize);
            end
            stack(:, :, numEntries) = map.z;
            numEntries = numEntries + 1;
        end
    end
    
    data.setTrial(originalTrial);
end
