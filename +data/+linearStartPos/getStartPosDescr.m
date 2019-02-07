% getStartPosDescr - Return character representation of starting position.
%
% There could be different starting positions that are represented by the same value/number.
% For example 200 and 200 meaning the beginning and the end of the track. To distinguish
% such starting positions, the starting position description is introduced. The description
% contains a unique character representation (string) of a start position. Description can
% be used to create file names or to display information on screen.
%
%  USAGE
%
%    descr = data.linearStartPos.getStartPosDesc(trial)
%
%    trial      Number. Trial number, which is used to provide start position description.
%    descr      String. Description of starting position.
%

% Copyright (C) 2013 by Vadim Frolov
%
function descr = getStartPosDescr(trial)
    global gBntData;
    global gCurrentTrial;

    if nargin < 1
        trial = gCurrentTrial;
    end
    if trial < 0
        error('Can not use negative trial number');
    end

    if trial > length(gBntData)
        error('Provided trial number is greater than number of loaded trials.');
    end

    if ~isfield(gBntData{trial}, 'startPosDescr')
        error('Failed to found start position description information in data. Check that your data really contains this information.');
    end

    descr = gBntData{trial}.startPosDescr;
end
