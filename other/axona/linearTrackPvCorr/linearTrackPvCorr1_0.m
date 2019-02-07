% linearTrackPvCorr1_0('dataFolder', 'cellFile.txt', 'trackPosFolder','outputFile.xls')
%
% Linear track population vector correlation. Made on request from Nenita
% Charlotte Dagslott and Tale Litleré Bjerknes. Data must be recorded on
% the linear track with different start positions. Data is then aligned at
% start or end postion at the population vector correlation is calculated
% between the different starting positions.
%
% NOTE: Correlation values both in figures and in the output file is
% ordered by distance from alignment point. That means that end aligned
% data will have the values closest to the end first.
%
% NOTE: The track is assumed to be placed horizontally relative to the 
% camera: meaning that the track goes along the x-axis of the camera. If 
% the track is placed otherwise the code need be updated accordingly.
%
%
%
% INPUT ARGUMENTS
%
% dataFolder    Directory with all the session that belong together. I.e.
%               all the runs that should be analyzed together. No other
%               recording sessions must be stored in the same folder. The
%               name of the folder have to be written in single quotes.
%               Example: 'N:\talelitl\LinearTrackData\17237\110912'
%               
% cellFile      Name of the text file where the tetrode and cluster number
%               for all cells that are to be analyzed are listed. Look
%               below for the structure of the cell file. The name of the
%               file have to be written in single quotes.
%
%               Example on content in file (No empty lines in file):
%
%               T7C1
%               T7C2
%               T7C3
%               T7C4
%               T7C7
%               T7C8
%               T8C1
%
% trackPosFolder
%               Folder where the position files with the positions of the 
%               linear track can be found. The folder needs to contain the
%               following position files:
%                   1. start (200 cm).pos
%                   2. start of box (0 cm).pos
%                   3. end of box.pos
%               The name of the folder must be written in single quotes.
%
% outputFile    Name for the output file where the results will be written.
%               The name must be written in single quotes.
%
% Example on running the program: 
%
%   linearTrackPvCorr1_0('N:\talelitl\Data\17906\241112', 'cellList.txt', 'N:\talelitl\Data\TrackPosition', 'Results.xls')
%
% 
%
%
% Version 1.0   
% 19. Dec. 2012
%
% Created by Raymond Skjerpeng, KI/CBM, NTNU, 2012.
function linearTrackPvCorr1_0(dataFolder, cellFile, trackPosFolder, outputFile)

%__________________________________________________________________________
%
%                       Program parameters
%__________________________________________________________________________

% Length of the linear track. (Before anything is cut off)
p.trackLength = 200; % [cm]

% Length of area at the left hand side of track that have to be cut off.
p.leftCutOff = 0; % [cm]

% Length of area at the right hand side of track that have to be cut off.
p.rightCutOff = 0; % [cm]

% Bin width for the rate maps that are used to construct the population
% vectors
p.binWidth = 5.0; % [cm]

% Set the maximum time gap in the position data that should be
% interpolated. If there is gaps with durtion longer than this the samples
% will be left as NaN.
p.maximumInterpolationGap = 1; % [sec]

% Folder to store the images in. Folder will be created in the current
% folder.
p.imageFolder = 'pvImages';

% Picture storing format. 
% format = 1 -> bmp (24 bit)
% format = 2 -> png
% format = 3 -> eps
% format = 4 -> jpg
% format = 5 -> ai (Adobe Illustrator)
% format = 6 -> tiff (24 bit)
p.imageFormat = 2;

%__________________________________________________________________________

% if exist('importvideotracker.m') == 0 %#ok<EXIST>
%     disp('No inportvideotracker function is defined. You need to setup Matlab properly');
%     return
% end
fprintf('%s%s\n','Start analysing at ', datestr(now));
% Sampling rate fore Axona is 50 Hz
p.sampleTime = 0.02;

if ~strcmp(p.imageFolder(end),'\')
    p.imageFolder = strcat(p.imageFolder,'\');
end

% Get the cells from the cell file
[status, cellList] = cellFileReader(cellFile);

if status == 0
    disp('Analysis failed')
    fclose('all');
    return
end

% Locate sessions in the data folder
[status, sessionArray, cutFiles] = dataFolderAnalyzer(dataFolder);

if status == 0
    disp('Analysis failed')
    fclose('all');
    return
end

% Get the location of the track
[status, linearTrackPos] = trackPosFolderAnalyzer(trackPosFolder);

if status == 0
    disp('Analysis failed')
    fclose('all');
    return
end

% Make sure the image folder exists
d = dir(p.imageFolder);
if isempty(d)
    try
        mkdir(p.imageFolder);
    catch me
        disp(me)
    end
end

% Open the output file for writing
try
    fid = fopen(outputFile,'w');
catch me
    disp('Couldn''t open the output file')
    disp(me)
end

if fid == -1
    disp('Couldn''t open the output file')
    return
end

% Maximum number of bins in a map
maxNumCorrValues = ceil(p.trackLength / p.binWidth);

% Write header to the output file
fprintf(fid,'%s\t','Start position 1');
fprintf(fid,'%s\t','Start position 2');
fprintf(fid,'%s\t','Alignment');
for ii = 1:maxNumCorrValues
    fprintf(fid,'%s%u\t','Bin ',ii);
end
fprintf(fid,'\n');


% Calculate the conversion value for the position data
scale = p.trackLength / (linearTrackPos(3,1) - linearTrackPos(1,1));

% Set the session id
sInd = strfind(dataFolder,'\');
if ~isempty(sInd)
    if length(sInd) >= 2
        p.sessionId = sprintf('%s%s%s',dataFolder(sInd(end-1)+1:sInd(end)-1),'_',dataFolder(sInd(end)+1:end) );
    else
        p.sessionId = sprintf('%s%s%s',dataFolder(1:sInd-1),'_', dataFolder(sInd+1:end));
    end
else
    p.sessionId = dataFolder;
end

p.numSessions = size(sessionArray,1);
if p.numSessions == 0
    disp('Error: Didn''t locate any sessions in the data folder')
    return
else
    fprintf('%u%s\n',p.numSessions,' sessions located in the data folder');
end

if ~strcmp(dataFolder(end),'\')
    dataFolder = strcat(dataFolder,'\');
end

startPositions = zeros(p.numSessions,1);
for ii = 1:p.numSessions
    startPositions(ii) = sessionArray{ii,2};
end

startPositions = unique(startPositions);
p.numStartPos = length(startPositions);

% Tetrodes listed in the cell list
tetrodes = cellList(:,1);
tetrodes = unique(tetrodes);
p.numTetrodes = length(tetrodes);

% 1: posx
% 2: posy
% 3: post
posData = cell(p.numSessions,3);
% Time stamps for each tetrode for each session
tetrodeData = cell(p.numSessions, p.numTetrodes);
% Cut file for each start positions and tetrode
cutData = cell(p.numStartPos, p.numTetrodes);

p.numCutFiles = size(cutFiles,1);

% Treshold for how far a rat can move (150cm/s), in one sample
threshold = 150 / 50;

p.minY = inf;
p.numPosSamples = 0;
for s = 1:p.numSessions
    fprintf('%s%s\n','Loading data for session ', sessionArray{s,1});
    
    % Load position data
    videoFile = strcat(dataFolder,sessionArray{s,1},'.pos');
    [posData{s,1},posData{s,2},posData{s,3}] = getPos(videoFile);
    
    % Remove bad tracking from the position samples
    [posData{s,1},posData{s,2}] = remBadTrack(posData{s,1},posData{s,2},threshold);
    [posData{s,1},posData{s,2}] = interporPos(posData{s,1},posData{s,2},p.maximumInterpolationGap,50);
    [posData{s,1}, posData{s,2}] = pathMovingMeanFilter(posData{s,1}, posData{s,2});
    
    tMinY = min(posData{s,2});
    if tMinY < p.minY
        p.minY = tMinY;
    end

    % Increment the number of position samples
    p.numPosSamples = p.numPosSamples + length(posData{s,1});
    
    % Load tetrode data
    for t = 1:p.numTetrodes
        spikeFile = sprintf('%s%s%s%u',dataFolder,sessionArray{s,1},'.',tetrodes(t));
        
        tetrodeData{s,t} = getspikes(spikeFile);
    end
end

% Convert the coordinates to the correct length
for s = 1:p.numSessions
    posData{s,1} = (posData{s,1} - linearTrackPos(3,1)) * scale;
    posData{s,2} = (posData{s,2} - p.minY) * scale;
end

if p.leftCutOff > 0
    % Cut of part of the track at the left side
    for s = 1:p.numSessions
        ind = find(posData{s,1} < (p.minX+p.leftCutOff));
        if ~isempty(ind)
            posData{s,1}(ind) = NaN;
            posData{s,2}(ind) = NaN;
        end
    end
    % New minimum x value
    p.minX = p.leftCutOff;
    % New length of track
    p.trackLength = p.trackLength - p.leftCutOff;
end
if p.rightCutOff > 0
    % Cut of part of the track at the right side
    for s = 1:p.numSessions
        ind = find(posData{s,1} > (p.maxX-p.rightCutOff));
        if ~isempty(ind)
            posData{s,1}(ind) = NaN;
            posData{s,2}(ind) = NaN;
        end
    end
    % New maximum x value
    p.maxX = p.maxX - p.rightCutOff;
    % New length of track
    p.trackLength = p.trackLength - p.rightCutOff;
end

% Load the cut data
for ii = 1:p.numStartPos
    for t = 1:p.numTetrodes
        for c = 1:p.numCutFiles
            if cutFiles{c,3} == startPositions(ii) && cutFiles{c,2} == tetrodes(t)
                % We got the correct cut file, load the cut data.
                cutFileName = strcat(dataFolder,cutFiles{c,1});
                cutData{ii,t} = getcut(cutFileName);
            end
        end
    end
end


% Set the position vector for the figures
screenSize = get(0,'screenSize');
p.positionVector = [20,80,screenSize(3)-40,screenSize(4)-170];

% Analyze the data
mainFunction(posData, tetrodeData, cutData, sessionArray, startPositions, tetrodes, cellList, fid, p);

% Close all
fclose('all');
close('all');
fprintf('%s%s\n','Finished analysing at ', datestr(now));

end







%__________________________________________________________________________
%
%                           Main function
%__________________________________________________________________________




% Main function do all the analyses
function mainFunction(posData, tetrodeData, cutData, sessionArray, startPositions, tetrodes, cellList, fid, p)

disp('Analysing data')

coreName = strcat(p.imageFolder, p.sessionId);

% 1 col: posx
% 2 col: posy
% 3 col: post
posDataByStartPos = cell(p.numStartPos, 3);
% Array to hold number of samples in each run
samplesInRun = zeros(p.numStartPos, 100);


runTimeOffset = zeros(p.numStartPos,1000);
runCounter = zeros(p.numStartPos,1);
for s = 1:p.numSessions
    for sp = 1:p.numStartPos
        if sessionArray{s,2} == startPositions(sp)  % Correct starting position
           runCounter(sp) = runCounter(sp) + 1;
            % Set time offset for this run
            if isempty(posDataByStartPos{sp,3})
                timeOffset = 0;
            else
                timeOffset = posDataByStartPos{sp,3}(end) + 0.02;
            end
            posDataByStartPos{sp,1} = [posDataByStartPos{sp,1}; posData{s,1}];
            posDataByStartPos{sp,2} = [posDataByStartPos{sp,2}; posData{s,2}];
            % Add time offset to the timestamps to create continuous
            % timestamps
            posDataByStartPos{sp,3} = [posDataByStartPos{sp,3}; posData{s,3} + timeOffset];
            
            % Store number of samples in run
            samplesInRun(sp,runCounter(sp)) = length(posData{s,1});
            
            % Keep the offset values for use with the spike data
            runTimeOffset(sp,runCounter(sp)) = timeOffset;
        end
    end
end

runCounter = zeros(p.numStartPos,1);

% Join spike data for same tetrode and start position on track
spikeDataByStartPos = cell(p.numStartPos,p.numTetrodes);
for sp = 1:p.numStartPos
    for s = 1:p.numSessions
        if sessionArray{s,2} == startPositions(sp) % Correct starting position
            runCounter(sp) = runCounter(sp) + 1;
            for t = 1:p.numTetrodes
                % Add spike timestamps with time offset
                spikeDataByStartPos{sp,t} = [spikeDataByStartPos{sp,t}; tetrodeData{s,t} + runTimeOffset(sp,runCounter(sp))];
            end
        end
    end
end

% Number of cells listed
numCells = size(cellList,1);

% Calculate the rate map for each cell and start position on the track
% 1 = Map stack
% 2 = map axis
mapStack = cell(p.numStartPos,2);
for sp = 1:p.numStartPos
    % Number of bins in the rate map for this start position
    numBins = ceil(startPositions(sp) / p.binWidth);
    % Allocate memory for the map stack
    mapStack{sp,1} = zeros(numCells, numBins);
end

for sp = 1:p.numStartPos
    perSp = zeros(1, numCells);
    for c = 1:numCells
        tetrode = cellList(c,1);
        unit = cellList(c,2);
        tInd = find(tetrodes == tetrode);
        
        % Timestamps for this cell
        ts = spikeDataByStartPos{sp,tInd}(cutData{sp,tInd} == unit);
        
        % Calculate spike positions
        [spkx, spky] = spikePos(ts,posDataByStartPos{sp,1},posDataByStartPos{sp,2},posDataByStartPos{sp,3});
        
        posx = posDataByStartPos{sp, 1};
        % Calculate the 1-D rate map
        [mapStack{sp,1}(c,:), mapStack{sp,2}] = rateMap1D(posDataByStartPos{sp,1}, spkx, p.binWidth, nanmin(posDataByStartPos{sp,1}), startPositions(sp), p);
        
        % cell rate mape
        rateMap = mapStack{sp, 1}(c, :);
        
        % find out how far is the spike peak from the start position
        [~, cellPeakInd] = max(rateMap);
        
        % convert peak index to location
        peakX = (cellPeakInd - 1) * p.binWidth + p.binWidth/2;
        
        perSp(c) = peakX;
    end
    figure, bar(perSp);
end

% Calculate the map stacks
for c = 1:numCells
    tetrode = cellList(c,1);
    unit = cellList(c,2);
    tInd = find(tetrodes == tetrode);
    perSp = [];
    for sp = 1:p.numStartPos
        % Timestamps for this cell
        ts = spikeDataByStartPos{sp,tInd}(cutData{sp,tInd} == unit);
        
        % Calculate spike positions
        [spkx, spky] = spikePos(ts,posDataByStartPos{sp,1},posDataByStartPos{sp,2},posDataByStartPos{sp,3});
        
        % Calculate the 1-D rate map
        [mapStack{sp,1}(c,:), mapStack{sp,2}] = rateMap1D(posDataByStartPos{sp,1}, spkx, p.binWidth, nanmin(posDataByStartPos{sp,1}), startPositions(sp), p);
        
        % cell rate mape
        %rateMap = mapStack{sp, 1}(c, :);
        
        % find out how far is the spike peak from the start position
        %[~, cellPeakInd] = max(rateMap);
        
        % convert peak index to location
        %peakX = (cellPeakInd - 1) * p.binWidth + p.binWidth/2;
        
        %perSp(end+1) = peakX;
    end
end

% Calculate the number of possible combinations of start position
numCombos = 0;
for ii = 2:p.numStartPos
    numCombos = numCombos + (ii-1);
end

% 1 Correlation Array
% 2 Start pos 1
% 3 Start pos 2
pvCorrelationArray = cell(numCombos,3);

for ii = 1:p.numStartPos
    for c = 1:numCells
        % cell rate mape
        rateMap = mapStack{sp, 1}(c, :);
    end
end

% Calculate the PV-correlations for every combination of start positions
% with data aligned at start position
counter = 0;
for ii = 1:p.numStartPos-1
    for jj = 2:p.numStartPos
        if ii ~= jj
            counter = counter + 1;

            % Calculate the population vector correlation
            myCorrArray = myCorrelation(mapStack{ii, 1}, mapStack{jj, 1});
            
            pvCorrelationArray{counter,1} = populationVectorCorrelation(mapStack{ii,1}, mapStack{jj,1}, 1);

            pvCorrelationArray{counter,2} = startPositions(ii);
            pvCorrelationArray{counter,3} = startPositions(jj);
        end
    end
end


% Create the figure window and maximize it to the screen
h1 = figure(1);
set(h1,'position',p.positionVector);

% Plot the correlation values for the start aligned data
for ii = 1:numCombos
    xAxis = p.binWidth/2:p.binWidth:length(pvCorrelationArray{ii,1})*p.binWidth-p.binWidth/2;
    bar(xAxis,pvCorrelationArray{ii,1});
    
    titleStr = sprintf('%u%s%u',pvCorrelationArray{ii,2},' vs ',pvCorrelationArray{ii,3});
    title(titleStr)
    ylabel('Correlation')
    xlabel('Distance from start of track [cm]')
    
    % Store figure
    fName = sprintf('%s%s%u%s%u%s', coreName,'_Segment_',pvCorrelationArray{ii,2},'_vs_Segment_',pvCorrelationArray{ii,3},'_pvCorrelation_StartAligned');
    imageStore(figure(1),p.imageFormat,fName,300);
end


% Write the start aligned values to the output file
for ii = 1:numCombos
    fprintf(fid,'%u\t',pvCorrelationArray{ii,2});
    fprintf(fid,'%u\t',pvCorrelationArray{ii,3});
    fprintf(fid,'%s\t','Start');
    for jj = 1:length(pvCorrelationArray{ii,1})
        fprintf(fid,'%1.2f\t',pvCorrelationArray{ii,1}(jj));
    end
    fprintf(fid,'\n');
end




% Redo the calculation but for data aligned at the end of the track

% 1 Correlation Array
% 2 Start pos 1
% 3 Start pos 2
pvCorrelationArray = cell(numCombos,3);

% Calculte the PV-correlations for every combination of start positions
% with data aligned at the end position
counter = 0;
for ii = 1:p.numStartPos-1
    for jj = 2:p.numStartPos
        if ii ~= jj
            counter = counter + 1;

            % Calculate the population vector correlation
            pvCorrelationArray{counter,1} = populationVectorCorrelation(mapStack{ii,1}, mapStack{jj,1}, 0);

            pvCorrelationArray{counter,2} = startPositions(ii);
            pvCorrelationArray{counter,3} = startPositions(jj);
        end
    end
end

% Plot the correlation values for the end aligned data
for ii = 1:numCombos
    % Set the reversed axis
    xAxis = length(pvCorrelationArray{ii,1})*p.binWidth-p.binWidth/2:-p.binWidth:p.binWidth/2;
    
    bar(xAxis,pvCorrelationArray{ii,1});
    
    titleStr = sprintf('%u%s%u',pvCorrelationArray{ii,2},' vs ',pvCorrelationArray{ii,3});
    title(titleStr)
    ylabel('Correlation')
    xlabel('Distance from end of track [cm]')
    
    % Store figure
    fName = sprintf('%s%s%u%s%u%s', coreName,'_Segment_',pvCorrelationArray{ii,2},'_vs_Segment_',pvCorrelationArray{ii,3},'_pvCorrelation_EndAligned');
    imageStore(figure(1),p.imageFormat,fName,300);
end


% Write the end aligned values to the output file
for ii = 1:numCombos
    fprintf(fid,'%u\t',pvCorrelationArray{ii,2});
    fprintf(fid,'%u\t',pvCorrelationArray{ii,3});
    fprintf(fid,'%s\t','End');
    numBins = length(pvCorrelationArray{ii,1});
    for jj = 1:numBins
        fprintf(fid,'%1.2f\t',pvCorrelationArray{ii,1}(numBins-jj+1));
    end
    fprintf(fid,'\n');
end

end



%__________________________________________________________________________
%
%                       Population vector correlation
%__________________________________________________________________________


function pvCorrArray = myCorrelation(stack1, stack2)
    [numCells1, numBins1] = size(stack1);
    [numCells2, numBins2] = size(stack2);

    if numCells1 ~= numCells2
        disp('Error: Not the same number of cells in the map stacks')
        pvCorrArray = [];
        return
    end
    
    % Align at start and limit the number of bins to the shortest array
    numBins = min([numBins1, numBins2]);
    
    % Calculate the correlation in each bin
    pvCorrArray = zeros(numCells1, numBins);
    for jj = 1:numCells1
        for ii = 1:numBins
            corrValue = corrcoef(stack1(jj, ii), stack2(jj, ii));
            pvCorrArray(jj, ii) = corrValue(2,1);
        end
    end
end

% Calculates the pearson correlation for every bin in the the stacks.
%
% stack1    Stack of maps for the first start position
%
% stack     Stack of maps for the second start postion
%
% startAligned
%           Flag setting if we are aligning data at start or end position 
%           of the track. 1 = start, 0 = end.
function pvCorrArray = populationVectorCorrelation(stack1, stack2, startAligned)

[numCells1, numBins1] = size(stack1);
[numCells2, numBins2] = size(stack2);

if numCells1 ~= numCells2
    disp('Error: Not the same number of cells in the map stacks')
    pvCorrArray = [];
    return
end

if startAligned == 1
    % Align at start and limit the number of bins to the shortest array
    numBins = min([numBins1, numBins2]);
    
    % Calculate the correlation in each bin
    pvCorrArray = zeros(numBins,1);
    for ii = 1:numBins
        corrValue = corrcoef(stack1(:,ii), stack2(:,ii));
        pvCorrArray(ii) = corrValue(2,1);
    end
else
    % Align at end and limit the number of bins to the shortest array
    numBins = min([numBins1, numBins2]);
    
    % Calculate the correlation in each bin
    pvCorrArray = zeros(numBins,1);
    for ii = 1:numBins
        corrValue = corrcoef(stack1(:,numBins1-ii+1), stack2(:,numBins2-ii+1));
        pvCorrArray(numBins-ii+1) = corrValue(2,1);
    end    
end

end







%__________________________________________________________________________
%
%                       Input data analyzer
%__________________________________________________________________________


% Analyzes the linear track position folder. This folder should contain
% tracked coordinates with the position of the linear track relative to the
% camera. These coordinates will be used to align the different session
% before the population vector analysis.
function [status, linearTrackPos] = trackPosFolderAnalyzer(trackPosFolder)

status = 0;

% Locate position files in the folder
searchStr = fullfile(trackPosFolder, '*.pos');
dirInfo = dir(searchStr);

% Array with the position values for the track
% 1 row: Start position of track
% 2 row: Start position of box at the end of the track
% 3 row: End position of the box at the end of the track
% 1 col: x-coordinate
% 2 col: y-coordinate
linearTrackPos = zeros(3,2);

% Number of files and directories in the data folder
N = size(dirInfo,1);

if N < 3
    disp('The linear track position folder don''t contain enough tracked data')
    return
end

loaded = zeros(1,3);
for f = 1:N
    if sum(loaded) == 3
        % All done
        break
    end
    
    if loaded(1) == 0
        if strcmpi(dirInfo(f).name,'start (200 cm).pos')
            % Load the data
            fName = fullfile(trackPosFolder, dirInfo(f).name);
            [posx,posy] = getPos(fName);
            
            % Use the median position as the position for the start of the
            % track
            linearTrackPos(1,1) = nanmedian(posx);
            linearTrackPos(1,2) = nanmedian(posy);
            
            loaded(1) = 1;
        end
    end
    
    if loaded(2) == 0
        if strcmpi(dirInfo(f).name,'start of box (0 cm).pos')
            % Load the data
            fName = fullfile(trackPosFolder, dirInfo(f).name);
            [posx,posy] = getPos(fName);
            
            % Use the median position as the position for the start of the
            % box at the end of the track
            linearTrackPos(2,1) = nanmedian(posx);
            linearTrackPos(2,2) = nanmedian(posy);
            
            loaded(2) = 1;
        end
    end
    
    if loaded(3) == 0
        if strcmpi(dirInfo(f).name,'end of box.pos')
            % Load the data
            fName = fullfile(trackPosFolder, dirInfo(f).name);
            [posx,posy] = getPos(fName);
            
            % Use the median position as the position for the start of the
            % track
            linearTrackPos(3,1) = nanmedian(posx);
            linearTrackPos(3,2) = nanmedian(posy);
            
            loaded(3) = 1;
        end
    end
end


% Hurray, it was a success
status = 1;

end

% Reads the information in the cell file
function [status, cellList] = cellFileReader(cellFile)


status = 1;
% 1: Tetrode number
% 2: Cluster number
cellList = zeros(1000,2);

fid = fopen(cellFile,'r');
if fid == -1
    status = 0;
    return
end

cellCounter = 0;

while ~feof(fid)
    str = fgetl(fid);
    
    cellCounter = cellCounter + 1;
    
    % Remove space at end of line
    str = stripSpaceAtEndOfString(str);
    
    % Check that line is not empty
    if isempty(str)
        disp('Error: There can''t be any empty lines in the cell file');
        fprintf('%s%u\n','Empty line was found in line number ',cellCounter);
        status = 0;
        return
    end
    
    sInd1 = strfind(str,'T');
    if isempty(sInd1)
        sInd1 = strfind(str,'t');
        if isempty(sInd1)
            disp('Error: The cell id is not in the correct format')
            fprintf('%s%s\n','The wrong cell id is ', str);
            status = 0;
            return
        end
    end
    
    sInd2 = strfind(str,'C');
    if isempty(sInd2)
        sInd2 = strfind(str,'c');
        if isempty(sInd2)
            disp('Error: The cell id is not in the correct format')
            fprintf('%s%s\n','The wrong cell id is ', str);
            status = 0;
            return
        end
    end
    
    cellList(cellCounter,1) = str2double(str(sInd1+1:sInd2-1));
    cellList(cellCounter,2) = str2double(str(sInd2+1:end));
    if isnan(cellList(cellCounter,1)) || isnan(cellList(cellCounter,2))
        disp('Error: The cell id is not in the correct format')
        fprintf('%s%s\n','The wrong cell id is ', str);
        status = 0;
        return
    end
end

cellList = cellList(1:cellCounter,:);

fclose(fid);
end

% Removes space at the end of the string input
function str = stripSpaceAtEndOfString(str)
    if isempty(str)
        return
    end

    while ~isempty(str)
        if strcmp(str(end),' ')
            str = str(1:end-1);
        else
            break;
        end
    end
end


% Analyzes the session names in the data folder.
function [status, sessionArray, cutFiles] = dataFolderAnalyzer(dataFolder)
    % Number of .set files in the data folder
    dirInfoSet = dir(fullfile(dataFolder, '*.set'));
    N_set = size(dirInfoSet, 1);

    % Number of .cut files in the data folder
    dirInfoCut = dir(fullfile(dataFolder, '*.cut'));
    N_cut = size(dirInfoCut, 1);

    N = N_set + N_cut;

    % 1: Session id
    % 2: Start position on track (length from end)
    sessionNames = cell(N_set,1);
    startPositions = cell(N_set,1);

    % 1 Cut file name
    % 2 Tetrode number
    % 3 Start position on track
    cutFiles = cell(N_cut,3);
    status = 1;
    sessionCounter = 0;
    cutCounter = 0;

    dirInfo = dirInfoSet;
    for ii = 1:N_set
        sInd = strfind(dirInfo(ii).name,'.');
        sInd2 = strfind(dirInfo(ii).name,'_');
        if ~isempty(sInd2)
            sessionCounter = sessionCounter + 1;
            sessionNames{sessionCounter} = dirInfo(ii).name(1:sInd(end)-1);
            try
                startPos = str2double(dirInfo(ii).name(sInd2(end)+1:sInd(end)-1));
                if isempty(startPos)
                    disp('Error: Session name are not in the expected format')
                    fprintf('%s%s\n','file name = ', dirInfo(ii).name);
                    status = 0;
                    return
                end
                startPositions{sessionCounter} = startPos;
            catch me
                disp('Error: Session name are not in the expected format')
                fprintf('%s%s\n','file name = ', dirInfo(ii).name);
                disp(me)
                status = 0;
                return
            end
        else
            disp('Error: Session name are not in the expected format')
            fprintf('%s%s\n','file name = ', dirInfo(ii).name);
            status = 0;
            return
        end
    end

    dirInfo = dirInfoCut;
    for ii = 1:N_cut
        sInd = strfind(dirInfo(ii).name,'.');
        sInd2 = strfind(dirInfo(ii).name,'_');
        if length(sInd2) >= 2
            cutCounter = cutCounter + 1;
            % Tetrode number
            try
                tetrode = str2double(dirInfo(ii).name(sInd2(end)+1:sInd(end)-1));
            catch me
                fprintf('%s\n','Error: Cut file not in the expected format: session_StartPos_Tetrode.cut')
                fprintf('%s%s\n','The file name is ', dirInfo(ii).name);
                disp(me)
                status = 0;
                return
            end
            % Start position
            try
                startPos = str2double(dirInfo(ii).name(sInd2(end-1)+1:sInd2(end)-1));
                if isempty(startPos)
                    disp('Error: Cut file are not in the expected format')
                    fprintf('%s%s\n','file name = ', dirInfo(ii).name);
                    status = 0;
                    return
                end
            catch me
                disp('Error: Cut file are not in the expected format')
                fprintf('%s%s\n','file name = ', dirInfo(ii).name);
                disp(me)
                status = 0;
                return
            end
            cutFiles{cutCounter,1} = dirInfo(ii).name;
            cutFiles{cutCounter,2} = tetrode;
            cutFiles{cutCounter,3} = startPos;
        end
    end

    % Sort the arrays in alphabetical order
    [sessionNames, idx] = sort(sessionNames);
    startPositions = startPositions(idx);

    sessionArray = cell(sessionCounter,2);
    sessionArray(1:sessionCounter,1) = sessionNames;
    sessionArray(1:sessionCounter,2) = startPositions;
end



%__________________________________________________________________________
%
%                           Rate map functions
%__________________________________________________________________________


% Calculates the 1-D rate map
function [map, mapAxis] = rateMap1D(posx, spkx, binWidth, xStart, xLength, p)



numBins = ceil(xLength / binWidth);


spikeMap = zeros(numBins,1);
timeMap = zeros(numBins,1);

mapAxis = zeros(numBins,1);

start = xStart;
stop = xStart + binWidth;

for ii = 1:numBins
    
    timeMap(ii) = length(posx(posx>= start & posx < stop));
    spikeMap(ii) = length(spkx(spkx >= start & spkx < stop));
    
    mapAxis(ii) = (start + stop) / 2;
    start = start + binWidth;
    stop = stop + binWidth;
end

timeMap = timeMap * p.sampleTime;

timeMap = mapSmoothing1D(timeMap);
spikeMap = mapSmoothing1D(spikeMap);

map = spikeMap ./ timeMap;
end


% Smooths the map with guassian smoothing
function sMap = mapSmoothing1D(map)
    box = boxcarTemplate1D();

    numBins = length(map);
    sMap = zeros(1,numBins);

    for ii = 1:numBins
        for k = 1:5
            % Bin shift
            sii = k-3;
            % Bin index
            binInd = ii + sii;
            % Boundry check
            if binInd<1
                binInd = 1;
            end
            if binInd > numBins
                binInd = numBins;
            end

            sMap(ii) = sMap(ii) + map(binInd) * box(k);
        end
    end
end

% 1-D Gaussian boxcar template 5 bins
function box = boxcarTemplate1D()
    % Gaussian boxcar template
    box = [0.05 0.25 0.40 0.25 0.05];
end

%__________________________________________________________________________
%
%                       Position data functions
%__________________________________________________________________________

% Finds the position to the spikes
function [spkx,spky,spkInd] = spikePos(ts,posx,posy,post)
    ts(ts>post(end)) = [];
    N = length(ts);
    spkx = zeros(N,1);
    spky = zeros(N,1);
    spkInd = zeros(N,1);

    count = 0;
    currentPos = 1;
    for ii = 1:N
        ind = find(post(currentPos:end) >= ts(ii),1,'first') + currentPos - 1;

        % Check if spike is in legal time sone
        if ~isnan(posx(ind))
            count = count + 1;
            spkx(count) = posx(ind);
            spky(count) = posy(ind);
            spkInd(count) = ind(1);
        end
        currentPos = ind;
    end
    spkx = spkx(1:count);
    spky = spky(1:count);
    spkInd = spkInd(1:count);
end


function [posx, posy] = pathMovingMeanFilter(posx, posy)
    % Smooth samples with a mean filter over 15 samples
    for cc = 8:length(posx)-7
        posx(cc) = nanmean(posx(cc-7:cc+7));   
        posy(cc) = nanmean(posy(cc-7:cc+7));
    end
end

% Removes position "jumps", i.e position samples that imply that the rat is
% moving quicker than physical possible.
function [x,y] = remBadTrack(x,y,treshold)
    N = length(x);
    % Indexes to position samples that are to be removed
    remInd = zeros(N,1);
    remCounter = 0;

    diffX = diff(x);
    diffY = diff(y);
    diffR = sqrt(diffX.^2 + diffY.^2);
    ind = find(diffR > treshold);

    if isempty(ind)
        return;
    end

    if ind(end) == length(x)
        offset = 2;
    else
        offset = 1;
    end

    for ii = 1:length(ind)-offset
        if ind(ii+1) == ind(ii)+1
            % A single sample position jump, tracker jumps out one sample and
            % then jumps back to path on the next sample. Remove bad sample.
            remCounter = remCounter + 1;
            remInd(remCounter) = ind(ii)+1;
            ii = ii+1;
            continue
        else
            % Not a single jump. 2 possibilities:
            % 1. Tracker jumps out, and stay out at the same place for several
            % samples and then jumps back.
            % 2. Tracker just has a small jump before path continues as normal,
            % unknown reason for this. In latter case the samples are left
            % untouched.
            idx = find(x(ind(ii)+1:ind(ii+1)+1)==x(ind(ii)+1));
            if length(idx) == length(x(ind(ii)+1:ind(ii+1)+1));
                n = ind(ii+1)+1 - ind(ii);
                remInd(remCounter+1:remCounter+n) = (ind(ii)+1:ind(ii+1)+1)';
                remCounter = remCounter + n;
            end
        end
    end

    remInd = remInd(1:remCounter);

    % Remove the samples
    x(remInd) = NaN;
    y(remInd) = NaN;
end


% Estimates lacking position samples using linear interpolation. When more
% than timeTreshold sec of data is missing in a row the data is left as
% missing.
%
% Raymond Skjerpeng 2006.
function [x,y] = interporPos(x,y,timeTreshold,sampRate)

% Turn of warnings
warning off;

% Number of samples that corresponds to the time treshold.
sampTreshold = floor(timeTreshold * sampRate);

% number of samples
numSamp = length(x);
% Find the indexes to the missing samples
temp1 = 1./x;
temp2 = 1./y;
indt1 = isinf(temp1);
indt2 = isinf(temp2);
ind = indt1 .* indt2;
ind2 = find(ind==1);
% Number of missing samples
N = length(ind2);

if N == 0
    % No samples missing, and we return
    return
end

change = 0;

% Remove NaN in the start of the path
if ind2(1) == 1
    change = 1;
    count = 0;
    while 1
        count = count + 1;
        if ind(count)==0
            break
        end
    end
    x(1:count) = x(count);
    y(1:count) = y(count);
%     ind(1:count) = 0;
%     ind2(1:count) = [];
end

% Remove NaN in the end of the path
if ind2(end) == numSamp
    change = 1;
    count = length(x);
    while 1
       count = count - 1;
       if ind(count)==0
           break
       end
    end
    x(count:numSamp) = x(count);
    y(count:numSamp) = y(count);
end

if change
    % Recalculate the missing samples
    temp1 = 1./x;
    temp2 = 1./y;
    indt1 = isinf(temp1);
    indt2 = isinf(temp2);
    % Missing samples are where both x and y are equal to zero
    ind = indt1 .* indt2;
    ind2 = find(ind==1);
    % Number of samples missing
    N = length(ind2);
end

for ii = 1:N
    % Start of missing segment (may consist of only one sample)
    start = ind2(ii);
    % Find the number of samples missing in a row
    count = 0;
    while 1
        count = count + 1;
        if ind(start+count)==0
            break
        end
    end
    % Index to the next good sample
    stop = start+count;
    if start == stop
        % Only one sample missing. Setting it to the last known good
        % sample
        x(start) = x(start-1);
        y(start) = y(start-1);
    else
        if count < sampTreshold
            % Last good position before lack of tracking
            x1 = x(start-1);
            y1 = y(start-1);
            % Next good position after lack of tracking
            x2 = x(stop);
            y2 = y(stop);
            % Calculate the interpolated positions
            X = interp1([1,2],[x1,x2],1:1/count:2);
            Y = interp1([1,2],[y1,y2],1:1/count:2);
            % Switch the lacking positions with the estimated positions
            x(start:stop) = X;
            y(start:stop) = Y;

            % Increment the counter (avoid estimating allready estimated
            % samples)
            ii = ii+count;
        else
            % To many samples missing in a row and they are left as missing
            ii = ii+count;
        end
    end
end

end






%__________________________________________________________________________
%
%                     Functions to read recorded data
%__________________________________________________________________________





% [posx,posy,post,posx2,posy2] = getpos(posfile)
%
% Reads Axona Dacq position data from the .pos file. If a 2-spot or 2
% colours are used for tracking the function returns coordinates for both
% colours/spots. 
%
% Version 2.0       Function automatically check if this is a 2 diode
% 24. Feb. 2010     recording or not. Checks if the number of timestamps is
%                   the same as the number of position samples.
%
% Created by Sturla Molden and Raymond Skjerpeng 2004-2010
function [posx,posy,post,posx2,posy2] = getPos(posfile)



[tracker,trackerparam] = importvideotracker(posfile);
   
post = zeros(trackerparam.num_pos_samples,1);


% Check the number of columns in the tracker
N = size(tracker(1).xcoord,2);

if N == 2 % A 2-spot tracking has been done (Big and small dot)
    temp = zeros(trackerparam.num_pos_samples,4);
else % Normal tracking - 1 or more colour
    temp = zeros(trackerparam.num_pos_samples,8);
end

% Read the timestamps and position samples into the arrays
for ii = 1:trackerparam.num_pos_samples
    post(ii) = tracker(ii).timestamp;
    temp(ii,:) = [tracker(ii).xcoord tracker(ii).ycoord];
end

% Fix possible glitches in the timestamps
post = fixTimestamps(post);

if N == 4
    
    % Get the number of valid samples for the 4 tracking colours
    colours = zeros(4,1);
    numRed = sum(~isnan(temp(:,1)));
    if numRed > 0
        colours(1) = 1;
    end
    numGreen = sum(~isnan(temp(:,2)));
    if numGreen > 0
        colours(2) = 1;
    end
    numBlue = sum(~isnan(temp(:,3)));
    if numBlue > 0
        colours(3) = 1;
    end
    numBoW = sum(~isnan(temp(:,4)));
    if numBoW > 0
        colours(4) = 1;
    end
    
    if sum(colours) == 0
        disp('Error: No valid position samples in the position file')
        posx = [];
        posy = [];
        posx2 = [];
        posy2 = [];
        return
    end
    
    if sum(colours) == 1
        % 1 tracking colour used for tracking
        if colours(1) == 1
            posx = temp(:,1) + trackerparam.window_min_x;
            posy = temp(:,5) + trackerparam.window_min_y;
        end
        if colours(2) == 1
            posx = temp(:,2) + trackerparam.window_min_x;
            posy = temp(:,6) + trackerparam.window_min_y;
        end
        if colours(3) == 1
            posx = temp(:,3) + trackerparam.window_min_x;
            posy = temp(:,7) + trackerparam.window_min_y;
        end
        if colours(4) == 1
            posx = temp(:,4) + trackerparam.window_min_x;
            posy = temp(:,8) + trackerparam.window_min_y;
        end
        % Set the length of the arrays according to the number of timestamps
        numPos = length(posx);
        numPost = length(post);
        if numPos ~= numPost
            posx = posx(1:numPost);
            posy = posy(1:numPost);
        end

        % Make empty arrays for the second set of coordinates to have
        % something to return
        posx2 = [];
        posy2 = [];
    else
        % More than 1 tracking colour used for tracking.
        if colours(1) == 1
            if colours(2) == 1
                posx = temp(:,1) + trackerparam.window_min_x;
                posy = temp(:,5) + trackerparam.window_min_y;
                posx2 = temp(:,2) + trackerparam.window_min_x;
                posy2 = temp(:,6) + trackerparam.window_min_y;
            elseif colours(3) == 1
                posx = temp(:,1) + trackerparam.window_min_x;
                posy = temp(:,5) + trackerparam.window_min_y;
                posx2 = temp(:,3) + trackerparam.window_min_x;
                posy2 = temp(:,7) + trackerparam.window_min_y;
            elseif colours(4) == 1
                posx = temp(:,1) + trackerparam.window_min_x;
                posy = temp(:,5) + trackerparam.window_min_y;
                posx2 = temp(:,4) + trackerparam.window_min_x;
                posy2 = temp(:,8) + trackerparam.window_min_y;
            end
        elseif colours(2) == 1
            if colours(3) == 1
                posx = temp(:,2) + trackerparam.window_min_x;
                posy = temp(:,6) + trackerparam.window_min_y;
                posx2 = temp(:,3) + trackerparam.window_min_x;
                posy2 = temp(:,7) + trackerparam.window_min_y;
            elseif colours(4) == 1
                posx = temp(:,2) + trackerparam.window_min_x;
                posy = temp(:,6) + trackerparam.window_min_y;
                posx2 = temp(:,4) + trackerparam.window_min_x;
                posy2 = temp(:,8) + trackerparam.window_min_y;
            end
        elseif colours(3) == 1
            posx = temp(:,3) + trackerparam.window_min_x;
            posy = temp(:,7) + trackerparam.window_min_y;
            posx2 = temp(:,4) + trackerparam.window_min_x;
            posy2 = temp(:,8) + trackerparam.window_min_y;
        end
    end
end
if N == 2 % 2-spot recording
    % First set of coordinates
    posx = temp(:,1) + trackerparam.window_min_x;
    posy = temp(:,3) + trackerparam.window_min_y;
    % Second set of coordinates
    posx2 = temp(:,2) + trackerparam.window_min_x;
    posy2 = temp(:,4) + trackerparam.window_min_y;
    
    % Set the length of the arrays according to the number of timestamps
    numSamp = length(post);
    posx = posx(1:numSamp);
    posy = posy(1:numSamp);
    posx2 = posx2(1:numSamp);
    posy2 = posy2(1:numSamp);
end


% Make sure timestamps start at zero
post = post - post(1);

% Make sure the arrays is of the same length
M = length(posx);
N = length(posy);
O = length(post);

P = min([M, N, O]);

posx = posx(1:P);
posy = posy(1:P);
post = post(1:P);

if ~isempty(posx2)
    posx2 = posx2(1:P);
    posy2 = posy2(1:P);
end

numNans = sum(isnan(posx2));
if numNans > 0.95 * P
    posx2 = [];
    posy2 = [];
end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tracker,trackerparam] = importvideotracker(filename)
%
%   [tracker,trackerparam] = importvideotracker(filename)
%   
%   Copyright (C) 2004 Sturla Molden 
%   Centre for the Biology of Memory
%   NTNU
%

fid = fopen(filename,'r','ieee-be');
if (fid < 0)
   error(sprintf('Could not open %s\n',filename)); 
end    

% read all bytes, look for 'data_start'
fseek(fid,0,-1);
sresult = 0;
[bytebuffer, bytecount] = fread(fid,inf,'uint8');
for ii = 10:length(bytebuffer)
    if strcmp( char(bytebuffer((ii-9):ii))', 'data_start' )
        sresult = 1;
        headeroffset = ii;
        break;
    end
end
if (~sresult)
    fclose(fid);
    error(sprintf('%s does not have a data_start marker', filename));
end

% count header lines
fseek(fid,0,-1);
headerlines = 0;
while(~feof(fid))
    txt = fgetl(fid);
    tmp = min(length(txt),10);
    if (length(txt))
        if (strcmp(txt(1:tmp),'data_start'))
            break;
        else
            headerlines = headerlines + 1;
        end
    else
        headerlines = headerlines + 1;
    end   
end    


% find time base
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^timebase.*')))
        timebase = sscanf(txt,'%*s %d %*s');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Timebase not reported, defaulting to 50 Hz');   
    timebase = 50;    
end

% find sample rate
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^sample_rate.*')))
        sample_rate = sscanf(txt,'%*s %d %*s');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Timebase not reported, defaulting to 50 Hz');   
    sample_rate = 50;    
end

% find duration
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^duration.*')))
        duration = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Duration not reported, defaulting to last time stamp');   
    duration = inf;    
end

% find number of samples
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^num_pos_samples.*')))
        num_pos_samples = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Number of samples not reported, using all that can be found');   
    num_pos_samples = inf;    
end

% find number of colours
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^num_colours .*')))
        num_colours  = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Number of colours not reported, defaulting to 4');   
    num_colours = 4;    
end

% find bytes per coord
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^bytes_per_coord.*')))
        bytes_per_coord = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Bytes per coordinate not reported, defaulting to 1');   
    bytes_per_coord = 1;    
end

% find bytes per timestamp
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^bytes_per_timestamp.*')))
        bytes_per_timestamp = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Bytes per timestamp not reported, defaulting to 4');   
    bytes_per_timestamp = 4;    
end

% find window_min_x
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^window_min_x.*')))
        window_min_x = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Minimum x-value for tracker window not reported, defaulting to 0');   
    window_min_x = 0;    
end

% find window_min_y
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^window_min_y.*')))
        window_min_y = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Minimum y-value for tracker window not reported, defaulting to 0');   
    window_min_y = 0;    
end

% find window_max_x
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^window_max_x.*')))
        window_max_x = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Maximum x-value for tracker window not reported, defaulting to 767 (PAL)');   
    window_max_x = 767;    
end

% find window_max_y
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^window_max_y.*')))
        window_max_y = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Maximum y-value for tracker window not reported, defaulting to 575 (PAL)'); 
    window_max_y = 575;    
end

% check position format
pformat = '^pos_format t';
for ii = 1:num_colours
    pformat = strcat(pformat,sprintf(',x%u,y%u',ii,ii));
end    
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^pos_format.*')))
        if (length(regexp(txt,pformat)))
            sresult = 1;
            twospot = 0;
            break;
        elseif (length(regexp(txt,'^pos_format t,x1,y1,x2,y2,numpix1,numpix2')))     
            sresult = 1;
            twospot = 1;
            break;
        else
           fclose(fid);
           fprintf(1,'%s\n',txt);
           error(sprintf('Unexpected position format, cannot read positions from %s',filename));   
        end
    end
end    
if (~sresult)
    fclose(fid);
    error(sprintf('No position format reported, cannot read positions from %s.\nAre you sure this is a video tracker file?',filename));   
end

% close the file
fclose(fid);

% count the number of positions in the file
if strcmp(char(bytebuffer(bytecount-11:bytecount))',sprintf('\r\ndata_end\r\n')) 
    tailoffset = 12; % <CR><LF>data_end<CR><LF>
else
    tailoffset = 0;
    warning('<CR><LF>data_end<CR><LF> not found at eof, did Dacq crash?n');
end    
if twospot
    poslen = bytes_per_timestamp + (4*bytes_per_coord + 8);
else    
    poslen = bytes_per_timestamp + (num_colours * 2 * bytes_per_coord);
end

num_samples_in_file = floor((bytecount - headeroffset - tailoffset)/poslen);  
if (isfinite(num_pos_samples))
    if (num_samples_in_file > num_pos_samples)
        warning(sprintf('%d spikes reported in header, but %s seems to contain %d positions.',num_pos_samples,filename,num_samples_in_file));
    elseif (num_samples_in_file < num_pos_samples)
        warning(sprintf('%d spikes reported in header, but %s can contain %d positions.',num_pos_samples,filename,num_samples_in_file));
        num_pos_samples = num_samples_in_file;    
    end
else
    num_pos_samples = num_samples_in_file;
end
    
% allocate memory for return values
if twospot
    posstruct = struct('timestamp',0,'xcoord',zeros(2,1),'ycoord',zeros(2,1),'numpix1',[],'numpix2',[]);
else
    posstruct = struct('timestamp',0,'xcoord',zeros(num_colours,1),'ycoord',zeros(num_colours,1));
end
tracker = repmat(posstruct,num_pos_samples,1);

% put the positions into the struct, one by one
big_endian_vector =  (256.^((bytes_per_timestamp-1):-1:0))';
big_endian_matrix = repmat((256.^((bytes_per_coord-1):-1:0))',1,num_colours*2);
if twospot
    big_endian_matrix_np = repmat((256.^(3:-1:0))',1,2);
    big_endian_matrix = repmat((256.^((bytes_per_coord-1):-1:0))',1,4);
end
for ii = 1:num_pos_samples
   % sort the bytes for this spike
   posoffset = headeroffset + (ii-1)*poslen;
   t_bytes = bytebuffer((posoffset+1):(posoffset+bytes_per_timestamp));
   tracker(ii).timestamp  = sum(t_bytes .* big_endian_vector) / timebase; % time stamps are big endian
   posoffset = posoffset + bytes_per_timestamp;
   if twospot
      c_bytes = reshape( bytebuffer((posoffset+1):(posoffset+(4*bytes_per_coord))), bytes_per_coord, 4); 
      tmp_coords =  sum(c_bytes .* big_endian_matrix, 1); % tracker data are big endian
      tracker(ii).xcoord = tmp_coords(1:2:end);
      index = find(tracker(ii).xcoord == 1023);
      tracker(ii).xcoord(index) = NaN; 
      tracker(ii).ycoord = tmp_coords(2:2:end);
      index = find(tracker(ii).ycoord == 1023);
      tracker(ii).ycoord(index) = NaN; 
      posoffset = posoffset + 4*bytes_per_coord;
      np_bytes = reshape( bytebuffer((posoffset+1):(posoffset+8)), 4, 2); 
      tmp_np = sum(np_bytes .* big_endian_matrix_np, 1);
      tracker(ii).numpix1 = tmp_np(1);
      tracker(ii).numpix2 = tmp_np(2);
      posoffset = posoffset + 8;
   else    
      c_bytes = reshape( bytebuffer((posoffset+1):(posoffset+(num_colours*2*bytes_per_coord))) , bytes_per_coord, num_colours*2); 
      tmp_coords =  sum(c_bytes .* big_endian_matrix, 1); % tracker data are big endian
      tracker(ii).xcoord = tmp_coords(1:2:end);
      index = find(tracker(ii).xcoord == 1023);
      tracker(ii).xcoord(index) = NaN; 
      tracker(ii).ycoord = tmp_coords(2:2:end);
      index = find(tracker(ii).ycoord == 1023);
      tracker(ii).ycoord(index) = NaN; 
   end
end
if (~isfinite(duration))
    duration = ceil(tracker(end).timestamp);
end

trackerparam = struct('timebase',timebase,'sample_rate',sample_rate,'duration',duration, ...
                  'num_pos_samples',num_pos_samples,'num_colours',num_colours,'bytes_per_coord',bytes_per_coord, ...
                  'bytes_per_timestamp',bytes_per_timestamp,'window_min_x',window_min_x,'window_min_y',window_min_y, ...
                  'window_max_x',window_max_x,'window_max_y',window_max_y,'two_spot',twospot);
end

% Fixes the Axona position timestamps
function fixedPost = fixTimestamps(post)

% First time stamp in file
first = post(1);
% Number of timestamps
N = length(post);

% Find the number of zeros at the end of the file
numZeros = 0;
while 1
    if post(end-numZeros)==0
        numZeros = numZeros + 1;
    else
        break;
    end
end

last = first + (N-1-numZeros) * 0.02;
fixedPost = first:0.02:last;
fixedPost = fixedPost';

end




function [ts,ch1,ch2,ch3,ch4] = getspikes(filename)
%
%   [ts,ch1,ch2,ch3,ch4] = getspikes(filename)
%   
%   Copyright (C) 2004 Sturla Molden 
%   Centre for the Biology of Memory
%   NTNU
%

[spikes,spikeparam] = importspikes(filename);
ts = [spikes.timestamp1]';
nspk = spikeparam.num_spikes;
spikelen = spikeparam.samples_per_spike;
ch1 = reshape([spikes.waveform1],spikelen,nspk)';
ch2 = reshape([spikes.waveform2],spikelen,nspk)';
ch3 = reshape([spikes.waveform3],spikelen,nspk)';
ch4 = reshape([spikes.waveform4],spikelen,nspk)';
end

function [spikes,spikeparam] = importspikes(filename)
%
%   [spikes,spikeparam] = importspikes(filename)
%   
%   Copyright (C) 2004 Sturla Molden 
%   Centre for the Biology of Memory
%   NTNU
%

fid = fopen(filename,'r','ieee-be');
if (fid < 0)
   error(sprintf('Could not open %s\n',filename)); 
end    

% read all bytes, look for 'data_start'
fseek(fid,0,-1);
sresult = 0;
[bytebuffer, bytecount] = fread(fid,inf,'uint8');
for ii = 10:length(bytebuffer)
    if strcmp( char(bytebuffer((ii-9):ii))', 'data_start' )
        sresult = 1;
        headeroffset = ii;
        break;
    end
end
if (~sresult)
    fclose(fid);
    error(sprintf('%s does not have a data_start marker', filename));
end

% count header lines
fseek(fid,0,-1);
headerlines = 0;
while(~feof(fid))
    txt = fgetl(fid);
    tmp = min(length(txt),10);
    if (length(txt))
        if (strcmp(txt(1:tmp),'data_start'))
            break;
        else
            headerlines = headerlines + 1;
        end
    else
        headerlines = headerlines + 1;
    end   
end    

% find timebase
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^timebase.*')))
        timebase = sscanf(txt,'%*s %d %*s');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Timebase not reported, defaulting to 96 kHz');   
    timebase = 96000;    
end

% find duration
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^duration.*')))
        duration = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Duration not reported, defaulting to last time stamp');   
    duration = inf;    
end

% find number of spikes
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^num_spikes.*')))
        num_spikes = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Number of spikes not reported, using all that can be found');   
    num_spikes = inf;    
end

% find bytes per sample
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^bytes_per_sample.*')))
        bytes_per_sample = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Bytes per sample not reported, defaulting to 1');   
    bytes_per_sample = 1;    
end

% find bytes per timestamp
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^bytes_per_timestamp.*')))
        bytes_per_timestamp = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Bytes per timestamp not reported, defaulting to 4');   
    bytes_per_timestamp = 4;    
end

% find samples per spike
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^samples_per_spike.*')))
        samples_per_spike = sscanf(txt,'%*s %d');    
        sresult = 1;
        break;
    end
end    
if (~sresult)
    warning('Samples per spike not reported, defaulting to 50');   
    samples_per_spike = 50;    
end

% check spike format
fseek(fid,0,-1);
sresult = 0;
for cc = 1:headerlines
    txt = fgetl(fid);
    if (length(regexp(txt,'^spike_format.*')))
        if (length(regexp(txt,'^spike_format t,ch1,t,ch2,t,ch3,t,ch4')))
            sresult = 1;
            break;
        else
           fclose(fid);
           error(sprintf('Unknown spike format, cannot read spikes from %s',filename));   
        end
    end
end    
if (~sresult)
    fclose(fid);
    error(sprintf('No spike format reported, cannot read spikes from %s.\nAre you sure this is a spike file?',filename));   
end

% close the file
fclose(fid);

% count the number of spikes in the file
spikelen = 4 * (bytes_per_sample * samples_per_spike + bytes_per_timestamp);
num_spikes_in_file = floor((bytecount - headeroffset)/spikelen);
if (isfinite(num_spikes))
    if (num_spikes_in_file > num_spikes)
        warning(sprintf('%d spikes reported in header, but %s seems to contain %d spikes.',num_spikes,filename,num_spikes_in_file));
    elseif (num_spikes_in_file < num_spikes)
        warning(sprintf('%d spikes reported in header, but %s can contain have %d spikes.',num_spikes,filename,num_spikes_in_file));
        num_spikes = num_spikes_in_file;    
    end
else
    num_spikes = num_spikes_in_file;
end
    
% allocate memory for return values

spikestruct = struct('timestamp1',0,'waveform1',zeros(samples_per_spike,1), ...
                     'timestamp2',0,'waveform2',zeros(samples_per_spike,1), ...
                     'timestamp3',0,'waveform3',zeros(samples_per_spike,1), ...
                     'timestamp4',0,'waveform4',zeros(samples_per_spike,1));

spikes = repmat(spikestruct,num_spikes,1);
                        
% out the spikes into the struct, one by one

big_endian_vector =  (256.^((bytes_per_timestamp-1):-1:0))';
little_endian_matrix = repmat(256.^(0:(bytes_per_sample-1))',1,samples_per_spike);

for ii = 1:num_spikes
   % sort the bytes for this spike
   spikeoffset = headeroffset + (ii-1)*spikelen;
   t1_bytes = bytebuffer((spikeoffset+1):(spikeoffset+bytes_per_timestamp));
   spikeoffset = spikeoffset + bytes_per_timestamp;
   w1_bytes = bytebuffer((spikeoffset+1):(spikeoffset+(bytes_per_sample*samples_per_spike)));
   w1_bytes( w1_bytes > 127 ) = w1_bytes( w1_bytes > 127 ) - 256;
   w1_bytes = reshape(w1_bytes,bytes_per_sample,samples_per_spike);
   spikeoffset = spikeoffset + bytes_per_sample*samples_per_spike;
   t2_bytes = bytebuffer((spikeoffset+1):(spikeoffset+bytes_per_timestamp));
   spikeoffset = spikeoffset + bytes_per_timestamp;
   w2_bytes = bytebuffer((spikeoffset+1):(spikeoffset+(bytes_per_sample*samples_per_spike)));
   w2_bytes( w2_bytes > 127 ) = w2_bytes( w2_bytes > 127 ) - 256;
   w2_bytes = reshape(w2_bytes,bytes_per_sample,samples_per_spike);
   spikeoffset = spikeoffset + bytes_per_sample*samples_per_spike;
   t3_bytes = bytebuffer((spikeoffset+1):(spikeoffset+bytes_per_timestamp));
   spikeoffset = spikeoffset + bytes_per_timestamp;
   w3_bytes = bytebuffer((spikeoffset+1):(spikeoffset+(bytes_per_sample*samples_per_spike)));
   w3_bytes( w3_bytes > 127 ) = w3_bytes( w3_bytes > 127 ) - 256;
   w3_bytes = reshape(w3_bytes,bytes_per_sample,samples_per_spike);
   spikeoffset = spikeoffset + bytes_per_sample*samples_per_spike;
   t4_bytes = bytebuffer((spikeoffset+1):(spikeoffset+bytes_per_timestamp));
   spikeoffset = spikeoffset + bytes_per_timestamp;
   w4_bytes = bytebuffer((spikeoffset+1):(spikeoffset+(bytes_per_sample*samples_per_spike)));
   w4_bytes( w4_bytes > 127 ) = w4_bytes( w4_bytes > 127 ) - 256;
   w4_bytes = reshape(w4_bytes,bytes_per_sample,samples_per_spike);
   % interpret the bytes for this spike
   spikes(ii).timestamp1 = sum(t1_bytes .* big_endian_vector) / timebase; % time stamps are big endian
   spikes(ii).timestamp2 = sum(t2_bytes .* big_endian_vector) / timebase;
   spikes(ii).timestamp3 = sum(t3_bytes .* big_endian_vector) / timebase;
   spikes(ii).timestamp4 = sum(t4_bytes .* big_endian_vector) / timebase;
   spikes(ii).waveform1 =  sum(w1_bytes .* little_endian_matrix, 1); % signals are little-endian
   spikes(ii).waveform2 =  sum(w2_bytes .* little_endian_matrix, 1);
   spikes(ii).waveform3 =  sum(w3_bytes .* little_endian_matrix, 1);
   spikes(ii).waveform4 =  sum(w4_bytes .* little_endian_matrix, 1);
end
if (~isfinite(duration))
    duration = ceil(spikes(end).timestamp1);
end
spikeparam = struct('timebase',timebase,'bytes_per_sample',bytes_per_sample,'samples_per_spike',samples_per_spike, ...
                    'bytes_per_timestamp',bytes_per_timestamp,'duration',duration,'num_spikes',num_spikes);

end

                
                
                  
function clust = getcut(cutfile)
    fid = fopen(cutfile, 'rt');
    clust = zeros(1000000,1);
    counter = 0;
    while ~feof(fid)
        string = fgetl(fid);
        if ~isempty(string)
            if (string(1) == 'E') 
                break;
            end
        end
    end
    while ~feof(fid)
      string = fgetl(fid);
      if ~isempty(string)
         content = sscanf(string,'%u')';
         N = length(content);

         clust(counter+1:counter+N) = content;
         counter = counter + N;
      end
    end
    fclose(fid);
    if counter > 0
        clust = clust(1:counter);
    else
        clust = [];
    end
end


%__________________________________________________________________________
%
%                           Plot and image functions
%__________________________________________________________________________




% Function for storing figures to file
% figHanle  Figure handle (Ex: figure(1))
% format = 1 -> bmp (24 bit)
% format = 2 -> png
% format = 3 -> eps
% format = 4 -> jpg
% format = 5 -> tiff (24 bit)
% format = 6 -> fig (Matlab figure)
% figFile   Name (full path) for the file
% dpi       DPI setting for the image file
function imageStore(figHandle,format,figFile,dpi)
    % Make the background of the figure white
    set(figHandle,'color',[1 1 1]);
    dpi = sprintf('%s%u','-r',dpi);

    switch format
        case 1
            % Store the image as bmp (24 bit)
            figFile = strcat(figFile,'.bmp');
            print(figHandle, dpi, '-dbmp',figFile);
        case 2
            % Store image as png
            figFile = strcat(figFile,'.png');
            print(figHandle, dpi,'-dpng',figFile);
        case 3
            % Store image as eps (Vector format)
            figFile = strcat(figFile,'.eps');
            print(figHandle, dpi,'-depsc',figFile);
        case 4
            % Store image as jpg
            figFile = strcat(figFile,'.jpg');
            print(figHandle,dpi, '-djpeg',figFile);
        case 5
            % Store image as tiff (24 bit)
            figFile = strcat(figFile,'.tif');
            print(figHandle,dpi, '-dtiff',figFile);
        case 6
            % Store figure as Matlab figure
            figFile = strcat(figFile,'.fig');
            saveas(figHandle,figFile,'fig')
    end
end

% drawMap(map, xAxis, yAxis)
%
% drawMap draws the rate map in a color coded image, using the jet color
% map. The number of color used for the scaling can be changed in the
% variable numLevels.
%
% map       Rate map that is to be displayed as image
% xAxis     The x-axis values (values for each column in the map)
% yAxis     The y-axis values (values for each row in the map)
%
% (c) Raymond Skjerpeng, KI/CBM, NTNU, 2012.
function drawMap(map, xAxis, yAxis, cmap, maxRate)
    map(map>maxRate) = maxRate;

    % Set the number of colors to scale the image with. This value must be the
    % same as the number of levels set in the getCmap function.
    numLevels = 256;

    % Size of rate map
    [numRows,numCols] = size(map);

    % Allocate memory for the image
    plotMap = ones(numRows,numCols,3);

    % Peak rate of the map
    peakRate = nanmax(nanmax(map));

    if peakRate > 0
        % set color of each bin scaled according to the peak rate, bins with NaN
        % will be plotted as white RGB = [1,1,1].
        for r = 1:numRows
            for c = 1:numCols
                if ~isnan(map(r,c))
                    % Set the color level for this bin
                    level = round((map(r,c) / peakRate) * (numLevels-1)) + 1;
                    if isnan(level)
                        plotMap(r,c,:) = cmap(1,:);
                    else
                        plotMap(r,c,:) = cmap(level,:);
                    end
                end
            end
        end
    else
        for r = 1:numRows
            for c = 1:numCols
                if ~isnan(map(r,c))
                    % Set the color level for this bin
                    level = 1;
                    plotMap(r,c,:) = cmap(level,:);
                end
            end
        end
    end

    % Display the image in the current figure window. (window must be created
    % before calling this function
    image(xAxis,yAxis,plotMap);
    % Adjust axis to the image format
    axis('image')
end
