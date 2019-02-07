% Read Axona stimulation pulse timestamps (.STM) file
%
% This function reads Axona .stm file and returns stimulation
% timestamps in seconds.
%
%  USAGE
%   stimuli = io.axona.readStm(filename)
%   filename    - path to the file to read.
%   stimuli     - stimulus timestamps in seconds.
%
function stimuli = readStm(filename)
    if exist(filename, 'file') == 0
        error('BNT:noFile', 'Failed to find specified file ''%s''.\nPlease check that the name/path is correct.', filename);
    end

    [header, dataStart] = io.axona.readTrackerHeader(filename);

    % extract data
    numStimuli = str2double(header.num_stm_samples);
    % timebase should have format: '<number> hz'.
    timeBase = str2double(regexpi(header.timebase, '\d*', 'match'));

    fid = data.safefopen(filename, 'r', 'ieee-be'); % file is in big-endian format
    fseek(fid, dataStart, 'bof');

    stimuli = fread(fid, [numStimuli 1], 'uint32=>double');
    stimuli = stimuli ./ timeBase;
end