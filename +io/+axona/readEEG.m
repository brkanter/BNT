% [EEG,Fs] = readEEG(datafile)
%
% Reads low sampled eeg data and returns it in the array EEG together with
% the sampling rate Fs.
%
%
% Raymond Skjerpeng, CBM, NTNU, 2011.
function [status, EEG, Fs, bytesPerSample] = readEEG(datafile)

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
    % Skip one more line of the header
    textstring = strtrim(fgets(fid));
    % Read out the number of bytes per sample
    textstring = strtrim(fgets(fid));
    bytesPerSample = sscanf(textstring(18:end),'%f');
    % Read out the number of samples in the file
    textstring = strtrim(fgets(fid));
    nosamples = sscanf(textstring(17:end),'%u');
    % Go to the start of data (first byte after the data_start marker)
    fseek(fid,10,0);
catch
    fclose(fid);
    % File is corrupted
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
