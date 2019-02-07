% [EEG,Fs] = readEGF(datafile)
%
% Reads high sampled eeg data and returns it in the array EEG together with the
% sampling rate Fs.
%
% Version 1.0. May 2006.
%
% Raymond Skjerpeng, CBM, NTNU, 2006.
function [status, EEG, Fs, bytesPerSample] = readEGF(datafile)

% Open the file for reading
status = 0;
EEG = [];
Fs = [];
bytesPerSample = [];
try
    fid = fopen(datafile,'r');
    if fid == -1
        return
    else
        status = 1;
    end
catch
    return
end
% Skip some lines of the header
for ii = 1:8
   textstring = strtrim(fgets(fid));
end

try
    % Read out the sampling rate
    Fs = sscanf(textstring(13:end-3),'%f');
    % Read out the number of bytes per sample
    textstring = strtrim(fgets(fid));
    bytesPerSample = sscanf(textstring(18:end),'%f');
    % Skip some more lines of the header
    textstring = strtrim(fgets(fid));
    % Read out the number of samples in the file
    nosamples = sscanf(textstring(17:end),'%u');
    % Go to the start of data (first byte after the data_start marker)
    fseek(fid,10,0);
catch
    % File is corrupted
    fclose(fid);
    return;
end

% Read data according to the number of bytes used per sample
if bytesPerSample == 1
    EEG = fread(fid,nosamples,'int8');
else
    EEG = fread(fid,nosamples,'int16');
end
% Close the file
fclose(fid);
