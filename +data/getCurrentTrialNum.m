% Return current trial number
%
% Use this function to get the number of a currently selected/active trial.
%
% SEE
%   See also data.numTrials, data.setNextTrial, data.setTrial
%
function trial = getCurrentTrialNum()
    global gCurrentTrial;

    trial = gCurrentTrial;
end
