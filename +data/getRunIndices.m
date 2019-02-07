% Get indices of a run in trial that consists of combined sessions
%
% If the current trial consists of combined sessions, then this function
% can be used to extract run indices of a particular run.
%
%  USAGE
%   [startInd, endInd] = data.getRunIndices(runNum)
%   runNum      Integer, run number.
%   startInd    Index of the run initial position.
%   endInd      Index of the run end position.
%
function [startInd, endInd] = getRunIndices(runNum)
    global gBntData;
    global gCurrentTrial;

    if ~isfield(gBntData{gCurrentTrial}, 'startIndices') && runNum > 1
        error('There is no run information for this trial');
    end

    startIndices = gBntData{gCurrentTrial}.startIndices;
    if isempty(startIndices)
        startInd = 1;
        pos = data.getPositions();
        endInd = length(pos(:, 2));
        return;
    end
    
    startInd = startIndices(runNum);
    if runNum == length(startIndices)
        pos = data.getPositions();
        endInd = length(pos(:, 2));
    else
        endInd = startIndices(runNum + 1) - 1;
    end
end
