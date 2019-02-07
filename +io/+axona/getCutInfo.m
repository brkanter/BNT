% Get list of sessions that are covered by a cut file
%
% Each cut file in Axona contains a list of sessions which were used during creation
% of the cut file. This function extracts and returns this list.
%
%  USAGE
%   [session, numSpikes] = io.axona.getCutInfo(cutfile);
%   cutfile     Path to cut file.
%   session     Cell array of used sessions. Example, {'24111201_200', '24111202_200'}
%   numSpikes   Number of spikes
%
function [sessions, numSpikes] = getCutInfo(cutfile)
    fid = data.safefopen(cutfile, 'r');
    while ~feof(fid)
        str = fgets(fid);
        if str == -1
            sessions = {};
            numSpikes = 0;
            return;
        end
        string = strtrim(str);
        if ~isempty(string)
            if string(1) == 'E'
                break;
            end
        end
    end
    endInd = strfind(string, ' spikes');
    startInd = length('Exact_cut_for: ');
    sessions = string(startInd:endInd);
    sessions = strsplit(sessions, ',');
    sessions = cellfun(@(x)strtrim(x), sessions, 'uniformoutput', false);
    emptyIdx = cellfun(@(x) isempty(x), sessions);
    sessions(emptyIdx) = [];

    numSpikes = 0;
    startInd = endInd + 2;
    spikesStr = regexp(string(startInd:end), '\d*', 'match');
    if ~isempty(spikesStr)
        numSpikes = str2double(spikesStr{1});
    end
end