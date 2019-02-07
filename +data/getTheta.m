% Get Theta band LFP signal
%
% This function provides theta signal for desired LFP channels
% of a current trial.
%
%  USAGE
%   theta = data.getTheta(channels, frequency)
%   channels    1xN or Nx1, vector of channel IDs. If -1 is provided, then
%               data of all available channels is returned.
%   frequency   Optional. [Fp Fs] low pass and high pass theta frequency in Hz. Or
%               in other words a pass band and a stop band frequencies.
%               Default is [6 10].
%
%   theta       MxN theta signal, where M is number of samples
%               and N is number of channels + 1. First column contains
%               timestamps. The rest - theta signal.
%
function theta = getTheta(channels, thetaFrequency)
    global gBntData;
    global gCurrentTrial;

    theta = [];

    if isempty(gBntData)
        error('BNT:notLoaded', 'You should load some data first.');
    end
    if ~isfield(gBntData{gCurrentTrial}, 'lfpInfo') || isempty(gBntData{gCurrentTrial}.lfpInfo)
        error('Seems like you are trying to load some really old data. This is currently unsupported. Contact current code maintaner for help.');
    end

    if nargin < 2
        thetaFrequency = [6 10];
    end

    theta = gBntData{gCurrentTrial}.lfpInfo.getTheta(channels, thetaFrequency);
end