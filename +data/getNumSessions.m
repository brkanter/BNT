% Get number of sessions in the current trial
%
% This function returns the number of sessions for the current trial. The number of sessions
% is bigger than one when current trial consists of combined sessions.
%
%  USAGE
%   sessNum = data.getNumSessions()
%   sessNum     Number of sessions
%
function sessNum = getNumSessions()
    global gBntData;
    global gCurrentTrial;

    
    sessNum = length(gBntData{gCurrentTrial}.sessions);
end
