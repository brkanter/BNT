% Get list of cell numbers for specified tetrode in current trial
%
%  USAGE
%   cells = data.getCells(tetrode)
%   tetrode         Optional, number. Provide a number in order to get list of cells for this tetrode.
%                   If -1, then all cells are returned.
%                   If omitted, then a Nx2 matrix is returnedm where N is the number of
%                   different cells. First row contains tetrode numbers, second row contains cell numbers.
%   cells           Vector of cells or matrix of tetrodes/cells.
%
%  EXAMPLE
%   Get vector of cells belonging to tetrode number 5:
%   data.getCells(5)
%
%   Get vector of all cells from all tetrodes:
%   data.getCells(-1)
%
%   Get matrix with all tetrodes and all cells
%   data.getCells()
%
function cells = getCells(tetrode)
    global gBntData;
    global gCurrentTrial;

    if gCurrentTrial <= 0
        error('No data have been loaded');
    end

    if nargin > 0 && ~isnumeric(tetrode)
        error('Parameter tetrode is not a number (type ''help <a href="matlab:help data.getCells">data.getCells</a>'' for details).');
    end

    if isempty(gBntData{gCurrentTrial}.units)
        cells = [];
        return
    end
    
    if nargin > 0
        tetrode = tetrode(1);

        if tetrode == -1
            cells = gBntData{gCurrentTrial}.units(:, 2);
        else
            selected = gBntData{gCurrentTrial}.units(:, 1) == tetrode;
            cells = gBntData{gCurrentTrial}.units(selected, 2);
        end
    else
        cells = gBntData{gCurrentTrial}.units;
    end
end
