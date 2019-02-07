% Return number of loaded trials/sessions
%
% Each trial/session can contain single or combined session(s) with one tetrode and several cells.
%
%  SEE
%   See also data.getCurrentTrialNum, data.setNexttrial, data.setTrial
%
function n = numTrials()
    global gBntData;

    n = length(gBntData);
end
