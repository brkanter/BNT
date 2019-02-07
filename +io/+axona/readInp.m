% Read Axona .INP file
%
% This function reads Axona .INP file and returns it's data.
%  USAGE
%   [inp, inpparam] = readInp(filename)
%   filename        Path to the file
%

%   Copyright (C) 2005 Sturla Molden
%   Centre for the Biology of Memory
%   NTNU
%
function [inp, inpparam] = readInp(filename)

    fid = data.safefopen(filename, 'r', 'ieee-be');

    % read all bytes, look for 'data_start'
    fseek(fid, 0, -1);
    sresult = 0;
    [bytebuffer, bytecount] = fread(fid, inf, 'uint8');
    for i = 10:length(bytebuffer)
        if strcmp( char(bytebuffer((i-9):i))', 'data_start' )
            sresult = 1;
            headeroffset = i;
            break;
        end
    end

    if ~sresult
        clear fid;
        error('%s does not have a data_start marker', filename);
    end

    % count header lines
    fseek(fid, 0, -1);
    headerlines = 0;
    headerData = {};
    while ~feof(fid)
        txt = fgetl(fid);
        tmp = min(length(txt), 10);
        if isempty(txt)
            headerlines = headerlines + 1;
        else
            if (strcmp(txt(1:tmp), 'data_start'))
                break;
            else
                headerData{end+1} = strtrim(txt); %#ok<AGROW>
                headerlines = headerlines + 1;
            end
        end
    end

    % check data format
    idx = regexp(headerData, '^data_format.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        if ~strcmpi(headerData{idx}, 'data_format t,type,value')
            clear fid;
            error('Unknown data format, cannot read data from %s', filename);
        end
    else
        clear fid;
        error('No data format reported, cannot read data from %s.\nAre you sure this is an inp file?', filename);
    end

    % find timebase
    idx = regexp(headerData, '^timebase.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        timebaseStr = headerData{idx};
        timebase = sscanf(timebaseStr, '%*s %d %*s');
    else
        warning('Timebase not reported, defaulting to 96 kHz');
        timebase = 96000;
    end

    % find duration
    idx = regexp(headerData, '^duration.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        txt = headerData{idx};
        duration = sscanf(txt, '%*s %d');
    else
        warning('Duration not reported, defaulting to last time stamp');
        duration = inf;
    end

    % find number of inp samples
    idx = regexp(headerData, '^num_inp_samples.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        txt = headerData{idx};
        num_inp_samples = sscanf(txt, '%*s %d');
    else
        warning('Number of inp samples not reported, using all that can be found');
        num_inp_samples = inf;
    end

    % find bytes per sample
    idx = regexp(headerData, '^bytes_per_sample.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        txt = headerData{idx};
        bytes_per_sample = sscanf(txt, '%*s %d');
    else
        warning('Bytes per sample not reported, defaulting to 7');
        bytes_per_sample = 7;
    end

    % find bytes per timestamp
    idx = regexp(headerData, '^bytes_per_timestamp.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        txt = headerData{idx};
        bytes_per_timestamp = sscanf(txt, '%*s %d');
    else
        warning('Bytes per timestamp not reported, defaulting to 4');
        bytes_per_timestamp = 4;
    end

    % find bytes per type
    idx = regexp(headerData, '^bytes_per_type.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        txt = headerData{idx};
        bytes_per_type = sscanf(txt, '%*s %d');
    else
        warning('Bytes per type not reported, defaulting to 1');
        bytes_per_type = 1;
    end

    % find bytes per value
    idx = regexp(headerData, '^bytes_per_value.*');
    idx = cellfun(@(x) ~isempty(x), idx);
    if any(idx)
        txt = headerData{idx};
        bytes_per_value = sscanf(txt, '%*s %d');
    else
        warning('Bytes per type not reported, defaulting to 2');
        bytes_per_value = 1;
    end

    % verify bytes per sample
    if bytes_per_sample ~= bytes_per_timestamp + bytes_per_type + bytes_per_value
        error('record size mismatch');
    end

    % count the number of data samples in the file
    if strcmp(char(bytebuffer(bytecount-11:bytecount))', sprintf('\r\ndata_end\r\n'))
        tailoffset = 12; % <CR><LF>data_end<CR><LF>
    else
        tailoffset = 0;
        warning('<CR><LF>data_end<CR><LF> not found at eof, did Dacq crash?n');
    end

    num_samples_in_file = floor((bytecount - headeroffset - tailoffset)/bytes_per_sample);
    % if (isfinite(num_inp_samples))
    %     if (num_samples_in_file > num_inp_samples)
    %         warning(sprintf('%d data points reported in header, but %s seems to contain %d data points.',num_pos_samples,filename,num_samples_in_file));
    %     elseif (num_samples_in_file < num_inp_samples)
    %         warning(sprintf('%d data points reported in header, but %s can contain up to %d data points.',num_pos_samples,filename,num_samples_in_file));
    %         num_inp_samples = num_samples_in_file;
    %     end
    % else
    %     num_inp_samples = num_samples_in_file;
    % end

    % allocate memory for return values
    inpstruct = struct('timestamp', 0, 'type', 0, 'value', 0);
    inp = repmat(inpstruct, num_inp_samples, 1);

    % put the spikes into the struct, one by one
    big_endian_vector_timestamps = (256.^((bytes_per_timestamp-1):-1:0))';
    little_endian_vector_type = (256.^(0:(bytes_per_type-1)))';
    little_endian_vector_value = (256.^(0:(bytes_per_value-1)))';

    big_endian_vector_type = (256.^((bytes_per_type-1):-1:0))';
    big_endian_vector_value = (256.^((bytes_per_value-1):-1:0))';

    for ii = 1:num_inp_samples
       % sort the bytes for this spike
       dataoffset = headeroffset + (ii-1)*bytes_per_sample;
       timestamp_bytes = bytebuffer((dataoffset+1):(dataoffset+bytes_per_timestamp));
       dataoffset = dataoffset + bytes_per_timestamp;
       type_bytes = bytebuffer((dataoffset+1):(dataoffset+bytes_per_type));
       dataoffset = dataoffset + bytes_per_type;
       value_bytes = bytebuffer((dataoffset+1):(dataoffset+bytes_per_value));
       % interpret the bytes for this sample
       inp(ii).timestamp = sum(timestamp_bytes .* big_endian_vector_timestamps) / timebase; % time stamps are big endian
       inp(ii).type = sum(type_bytes .* big_endian_vector_type);
       inp(ii).value = sum(value_bytes .* big_endian_vector_value);
    end
    if (~isfinite(duration))
        duration = ceil(inp(end).timestamp);
    end

    inpparam = struct('timebase', timebase, 'bytes_per_sample', bytes_per_sample, ...
        'bytes_per_type', bytes_per_type, 'bytes_per_value', bytes_per_value, ...
        'bytes_per_timestamp', bytes_per_timestamp, 'duration', duration, ...
        'num_inp_samples', num_inp_samples);

end