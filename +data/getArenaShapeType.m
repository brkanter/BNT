% Get recording arena shape type of a current trial
%
%  USAGE
%   shape = data.getArenaShapeType()
%   shape   Integer that denotes arena shape type or NaN if no information about arena shape type 
%           is known. Use bntConstants.ArenaShape.* to work with the return value.
%           Information about arena shape type is provided through input file.
%
%  SEE
%   See also bntConstants
%

%
function shape = getArenaShapeType()
    global gBntData;
    global gCurrentTrial;

    if exist('gBntData', 'var') == 0 || isempty(gBntData)
        error('You need to initialize BNT before calling this function.');
    end

    shape = nan;

    if isfield(gBntData{gCurrentTrial}.extraInfo, 'shape')
        shape = gBntData{gCurrentTrial}.extraInfo.shape.type;
    end
end