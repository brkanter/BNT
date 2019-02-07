% Return data recording sample time of a current trial
%
%  USAGE
%   t = data.sampleTime(units)
%   units      Optional string that describes desirable units for t. Possible
%              values are 'sec' and 'hz'. Default is 'sec'.
%   t          sample time.
%
function t = sampleTime(units)
    global gBntData;
    global gCurrentTrial;

    if nargin < 1
        units = 'sec';
    end

    units = lower(units);
    if ~helpers.isstring(units, 'sec', 'hz')
        error('Unknown value for units');
    end

    if length(gBntData) < gCurrentTrial
        t = nan;
        return;
    end

    t = gBntData{gCurrentTrial}.sampleTime;

    if strcmp(units, 'hz')
        t = 1/t;
    end
end
