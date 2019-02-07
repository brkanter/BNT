% Read header from Axona's tracker file (.pos file)
%
% This function reads the header of provided .pos file and returns it
% as a structure. Field names correspond to header keywords, and field
% values correspond to header keywords values.
%
%  USAGE
%   [header, dataStart] = io.axona.readTrackerHeader(filename)
%   filename        Path to the .pos file.
%   header          Structure that contiains header information.
%   dataStart       Position in bytes at which data start. First data byte
%                   located exactly at dataStart.
%
function [header, dataStart] = readTrackerHeader(filename)
    fid = data.safefopen(filename, 'r', 'ieee-be');
    header = {};
    lastOffset = 0;
    dataStart = nan;
    while ~feof(fid)
        str = fgetl(fid);
        if ~isempty(strfind(str, 'data_start'))
            fseek(fid, lastOffset + length('data_start'), 'bof');
            dataStart = ftell(fid);
            break;
        end
        lastOffset = ftell(fid);
        % find first whitespace and the word before
        [tokensData, tokensInd] = regexp(str, '(^\w*)(\s{1})', 'tokens', 'tokenExtents');
        spaceInd = tokensInd{1}(2, 2);

        curLine{1, 1} = tokensData{1}{1};
        curLine{1, 2} = strtrim(str(spaceInd+1:end));
        header = cat(1, header, curLine);
    end
    [~, nonRepeatingIdx] = unique(header(:, 1));
    header = cell2struct(header(nonRepeatingIdx, 2), header(nonRepeatingIdx, 1));
end