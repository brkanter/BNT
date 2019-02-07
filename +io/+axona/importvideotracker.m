% Import position samples from Axona position file
%
% This function reads position samples from Axona .pos file.
%
% From Jim Donnett:
% You can basically ignore timestamps in the .pos files.  The timestamps reflect 
% the vertical sync pulses from the camera, which is free-running relative 
% to the system, so they may drift relative to the system's timing, which 
% is dictated by the electrophysiological signals.
% The repeated ones at the end of files are there because recordings get 
% padded at the end of trial so they end on a whole number of seconds, 
% and for .pos files this is done by repeating the last position point 
% as many times as necessary to stretch the trial to the next second.
% However, there shouldn't be large discontinuities. That would most likely 
% indicate data loss. If people do raw recordings on a PC that isn't fast
% enough, it's possible that data packets will be lost. The program reports
% this at the end of a trial, but some people ignore the message.  There is
% still synchronicity between the electrophysiological and position data,
% because these are packaged together in the DSP hardware, so there isn't any
% chance of spurious spatial relationships, but there may be periods when
% both the electrophysiological and position data are dropped.
% Tint also ignores them -- just assumes they are evenly spaced at the sample
% rate from the beginning of the trial.  
%
%  USAGE
%   [timestamps, coordinates, fileHeader] = io.axona.importvideotracker(filename)
%   filename        Path to .pos data file.
%   timestamps      Nx1 array of position timestamps in seconds.
%   coordinates     NxM matrix of X/Y coordinates. Axona supports two modes of tracking:
%                   4-spot and 2-spot. Different colours are tracked in the 4-spot mode.
%                   Big and little areas(LEDs) are tracked in the 2-spot mode. Value of M
%                   is different for different modes. M == 8 for 4-spot mode and columns
%                   represent [redX redY greenX greenY blueX blueY whiteX whiteY].
%                   M == 4 for 2-spot mode and columns represent [bigX bigY littleX littleY].
%   fileHeader      A structure with information from .pos file header. Values that can be
%                   converted to numbers are converted (for example, sampling rate is given as
%                   a number). Values that can not be converted, are given as strings (this
%                   includes pure text fields like experimentator name, but also time and date info).

function [timestamps, coordinates, fileHeader] = importvideotracker(filename)
    [fileHeader, dataStart] = io.axona.readTrackerHeader(filename);
    % default window size is PAL
    neededHeader = {'timebase', 50; 'duration', inf; 'sample_rate', 50; 'num_pos_samples', inf; ...
        'num_colours', 4; 'bytes_per_coord', 1; 'bytes_per_timestamp', 4; ...
        'window_min_x', 0; 'window_min_y', 0; 'window_max_x', 767; 'window_max_y', 575};

    fileHeader = adjustHeader(fileHeader, neededHeader);
    fileHeader = structfun(@digitize, fileHeader, 'uniformOutput', false);

    numColours = fileHeader.num_colours;
    numSamplesFromHeader = (fileHeader.num_pos_samples);
    bytesPerTimestamp = (fileHeader.bytes_per_timestamp);
    bytesPerCoordinate = (fileHeader.bytes_per_coord);

    if bytesPerTimestamp ~= 4
        error('BNT:io:axonaPosFormat', 'Unsupported format of Axona position file. Only files with 4 byte timestamps are supported. File %s has %u bytes', filename, bytesPerTimestamp);
    end
    if bytesPerCoordinate ~= 2
        error('BNT:io:axonaPosFormat', 'Unsupported format of Axona position file. Only files with 2 bytes per coordinate are supported. File %s has %u bytes', filename, bytesPerCoordinate);
    end

    % check position format
    pformat = '^t';
    for i = 1:numColours
        pformat = strcat(pformat, sprintf(',x%u,y%u', i, i));
    end

    if ~isempty(regexp(fileHeader.pos_format, pformat, 'once'))
        twospot = 0;
    elseif ~isempty(regexp(fileHeader.pos_format, '^t,x1,y1,x2,y2,numpix1,numpix2', 'once'))
        twospot = 1;
    else
       error('BNT:io:axonaPosFormat', 'Unexpected position format, cannot read positions from %s', filename);
    end

    fid = data.safefopen(filename, 'r');
    endMarker = sprintf('\r\ndata_end\r\n');
    fseek(fid, -length(endMarker), 'eof');
    dataEnd = ftell(fid);
    fileEndMarker = fread(fid, length(endMarker), '*char')';
    if ~strcmpi(fileEndMarker, endMarker)
        dataEnd = ftell(fid);
        warning('BNT:io:axonaPosFormat', '<CR><LF>data_end<CR><LF> not found at the end of file %s, did Dacq crash?', filename);
    end

    if twospot
        poslen = bytesPerTimestamp + (4*bytesPerCoordinate + 8); % 4*bytes_per_coord + 8 == 8*bytes_per_coord
    else
        poslen = bytesPerTimestamp + (numColours * 2 * bytesPerCoordinate);
    end

    num_samples_in_file = floor((dataEnd - dataStart)/poslen);
    if isfinite(numSamplesFromHeader)
        if num_samples_in_file > numSamplesFromHeader
            warning('BNT:io:axonaPosFormat', '%u samples reported in header, but %s seems to contains %u positions.', numSamplesFromHeader, filename, num_samples_in_file);
        elseif num_samples_in_file < numSamplesFromHeader
            warning('BNT:io:axonaPosFormat', '%u samples reported in header, but %s can contains %u positions.', numSamplesFromHeader, filename, num_samples_in_file);
            numSamplesFromHeader = num_samples_in_file;
        end
    else
        numSamplesFromHeader = num_samples_in_file;
    end

    numSamples = numSamplesFromHeader;

    % Do not read timestamps from file, but recreate it with a given timebase.
    % See description in function help for information.
    %fseek(fid, dataStart, 'bof');
    %timestamps = fread(fid, numSamples, 'uint32', poslen - bytesPerTimestamp, 'b');
    %timestamps = timestamps / timebase;
    dt = 1/fileHeader.timebase;
    endTime = numSamples * dt;
    timestamps = (0:dt:endTime)';
    timestamps(end) = [];

    fseek(fid, dataStart + bytesPerTimestamp, 'bof');
    if twospot
        skipBytes = poslen - 4*bytesPerCoordinate;
        coordinates = fread(fid, 4*numSamples, '4*int16', skipBytes, 'b'); % [x1 y1 x2 y2]
        coordinates = reshape(coordinates, [4 numSamples])';
    else
        % 8 words are redx, redy, greenx, greeny, bluex, bluey, whitex, whitey
        coordinates = fread(fid, 8*numSamples, '8*int16', bytesPerTimestamp, 'b');
        coordinates = reshape(coordinates, [8 numSamples])';
    end
    coordinates(coordinates == 1023) = nan;

    if ~isfinite(fileHeader.duration)
        fileHeader.duration = ceil(timestamps);
    end
end

% header - structure that we read from the file
% needHeader - Nx2 cell array. First column contains header field names,
%              second column contains default values.
% The function assigns default values for missing header field names.
function header = adjustHeader(header, neededHeader)
    for i = 1:size(neededHeader, 1)
        curParam = neededHeader(i, :);
        if ~isfield(header, curParam{1})
            header.(curParam{1}) = curParam{2};
        end
    end
end

function val = digitize(strVal)
    try
        if ~isempty(strfind(strVal, ':'))
            % this is time, do nothing
            val = strVal;
            return;
        end
        val = sscanf(strVal, '%f');
        if isempty(val)
            val = strVal;
        end
    catch
        val = strVal;
    end
end
