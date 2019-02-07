% Gets Axona EEG properties

% TODO: refactor and group channel return information together (i.e. channelMap, channelGain, adcFullscale)
% This will break compatibility, so make it during the next release
function [channelGain, adcFullscale, channelMap] = getEegProperties(setFileName)
    % Maximum number of EEGs that might exist for one session
    numPossibleEEGs = 16;
    % Array that will contain the channel gain for each available EEG
    channelGain = NaN(numPossibleEEGs, 1);
    % The adc fullscale value is depented on the dacq version and is used when
    % converting the EEG signal from bits to voltage.
    adcFullscale = 0;
    % container for information from .set file.
    valuesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    fid = data.safefopen(setFileName,'r');
   
    % Read each line of the file and put it into the cell array
    while ~feof(fid)
        ss = strtrim(fgets(fid));
        ind = strfind(ss, ' ');
        if isempty(ind)
            valuesMap(ss) = '';
        else
            key = ss(1:ind-1);
            value = ss(ind+1:end);
            valuesMap(key) = value;
        end
    end
    clear fid;

    % Set the keyword to search for when finding the ADC fullscale value
    keyword = 'ADC_fullscale_mv';
    if valuesMap.isKey(keyword)
        adcFullscale = str2double(valuesMap(keyword));
    end
    if adcFullscale ~= 3680 && adcFullscale ~= 1500
        error('Error: Corrupt setup file. ADC fullscale value not found or recognized')
    end

    % Search for the number of available EEGs
    availableEEGs = zeros(numPossibleEEGs, 1);
    for e = 1:numPossibleEEGs
        keyword = sprintf('saveEEG_ch_%u', e);
        if valuesMap.isKey(keyword)
            saveChannel = str2double(valuesMap(keyword));
            if saveChannel == 1
                availableEEGs(e) = 1;
            end    
        else
            % Keyword was not found. Assume that no more channels are available
            break;
        end
    end

    % Find the channel number for each EEG channel
    channelMap = nan(numPossibleEEGs, 1);
    for e = 1:numPossibleEEGs
        if availableEEGs(e) == 1
            keyword = sprintf('EEG_ch_%u', e);
            if valuesMap.isKey(keyword)
                channelMap(e) = str2double(valuesMap(keyword));
            end
        end
    end

    % Get the channel gain for each available EEG channel
    for e = 1:numPossibleEEGs
        if availableEEGs(e) == 1
            keyword = sprintf('gain_ch_%u', channelMap(e)-1);
            if valuesMap.isKey(keyword)
                channelGain(e) = str2double(valuesMap(keyword));
            end
        end
    end
end
