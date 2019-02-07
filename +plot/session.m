% Plot animal's run path for one session from a trial with combined sessions
%
% A trial may consist of combined sessions, i.e. several runs "merged" together.
% This function is used to plot only a single run in a trial.
%
% Use data.getNumSessions to get total number of sessions in the current trial.
%
%  USAGE
%   plot.sessions(trialNum, sessNum)
%   trialNum        trial number
%   sessNum         session number
%
function session(trialNum, sessNum)
    global gBntData;

    curTrial = data.getCurrentTrialNum();
    data.setTrial(trialNum);
    pos = data.getPositions();
    if ~isfield(gBntData{trialNum}, 'startIndices')
        warning('There is no run information for this trial');
        data.setTrial(curTrial);

        return;
    end

    startIndices = gBntData{trialNum}.startIndices;

    data.setTrial(curTrial);

    if length(startIndices) < sessNum
        error('There is no sesion number #%d in trial #%d', sessNum, trialNum);
    end

    startPos = startIndices(sessNum);
    if sessNum == length(startIndices)
        endPos = length(pos(:, 2));
    else
        endPos = startIndices(sessNum + 1) - 1;
    end

    plot(pos(startPos:endPos, 2), pos(startPos:endPos, 3));
end
