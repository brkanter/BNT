% trackPosFolderAnalyzer - Extract properties of linear track from specially recorded data.
%
% Analyzes the linear track position folder. This folder should contain
% tracked coordinates with the position of the linear track relative to the
% camera. These coordinates will be used to align the different session
% before the population vector analysis.
%
function linearTrackPos = trackPosFolderAnalyzer(trackPosFolder)

    % Locate position files in the folder
    searchStr = fullfile(trackPosFolder, '*.pos');
    dirInfo = dir(searchStr);

    % Array with the position values for the track
    % 1 row: Start position of track
    % 2 row: Start position of box at the end of the track
    % 3 row: End position of the box at the end of the track
    % 1 col: x-coordinate
    % 2 col: y-coordinate
    linearTrackPos = zeros(3, 2);

    % Number of files and directories in the data folder
    N = size(dirInfo, 1);

    if N < 3
        error('The linear track position folder doesn''t contain enough tracked data');
    end

    loaded = zeros(1, 3);
    for f = 1:N
        if sum(loaded) == 3
            % All done
            break
        end
        
        if loaded(1) == 0
            if strcmpi(dirInfo(f).name,'start (200 cm).pos')
                % Load the data
                fName = fullfile(trackPosFolder, dirInfo(f).name);
                pos = io.axona.getPos(fName);
                posx = pos(:, bntConstants.PosX);
                posy = pos(:, bntConstants.PosY);
                
                % Use the median position as the position for the start of the
                % track
                linearTrackPos(1, 1) = nanmedian(posx);
                linearTrackPos(1, 2) = nanmedian(posy);
                
                loaded(1) = 1;
            end
        end
        
        if loaded(2) == 0
            if strcmpi(dirInfo(f).name, 'start of box (0 cm).pos')
                % Load the data
                fName = fullfile(trackPosFolder, dirInfo(f).name);
                pos = io.axona.getPos(fName);
                posx = pos(:, bntConstants.PosX);
                posy = pos(:, bntConstants.PosY);
                
                % Use the median position as the position for the start of the
                % box at the end of the track
                linearTrackPos(2, 1) = nanmedian(posx);
                linearTrackPos(2, 2) = nanmedian(posy);
                
                loaded(2) = 1;
            end
        end
        
        if loaded(3) == 0
            if strcmpi(dirInfo(f).name, 'end of box.pos')
                % Load the data
                fName = fullfile(trackPosFolder, dirInfo(f).name);
                pos = io.axona.getPos(fName);
                posx = pos(:, bntConstants.PosX);
                posy = pos(:, bntConstants.PosY);
                
                % Use the median position as the position for the start of the
                % track
                linearTrackPos(3, 1) = nanmedian(posx);
                linearTrackPos(3, 2) = nanmedian(posy);
                
                loaded(3) = 1;
            end
        end
    end

    if sum(loaded) ~= 3
        error('Failed to load all data about the track.');
    end
end
