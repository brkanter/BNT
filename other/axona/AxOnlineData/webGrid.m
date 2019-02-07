% Prepare data to be published online. It was made specifically to work with
% linear track data, that had been recorded back in year 2008. This script is based
% on AxLinearTrack.
%
%   INPUT
%       inputFile       Path to the file that describes the data. You find an
%                       exampl in file 'examples/input_LT_11553_230606.txt'.
%
function webGrid(inputFile)

    p.outputDir = 'C:\home\workspace\OnlineGridData\full_sessions';
    % Velocity treshold. Samples where the rat is moving slower than this treshold
    % in the x-direction will be removed before analysing. [cm/s]
    param.vLimit = 10; %[cm/s]
    % ---
    % Flag indicating if a reduced phase range linear regression should be
    % done. 0 = Do not. 1 = Do it. The lowPhase and highPhase value are used to
    % set the range.
    param.reducedRangeRegression = 0;
    param.lowPhase = 90;
    param.highPhase = 270;
    % ---
    % Flag indicating if only a time segment of the session(s) should be used.
    % 0 = use whole session. 1 = use a time segment
    param.timeSegment = 0;
    % Start and stop time for the time segment in seconds. Set the stop time to
    % inf to go to the end of the trial.
    param.startTime = 0; % [sec]
    param.stopTime = inf; % [sec] (inf = end of trial)
    
    if exist(p.outputDir, 'dir') == 0
        stat = mkdir(p.outputDir);
        if ~stat
            stat = mkdir(p.outputDir);
        end
        if ~stat
            error('Failed to create output directory');
        end
    end
    
    fid = fopen(inputFile, 'r');
    if fid == -1
        error('Failed to open input file %s', inputFile);
    end
   
    c = onCleanup(@() fclose(fid));
   
    while ~feof(fid)
        % Flag indicating if we are combining sessions into one big session. 0 =
        % single session, 1 = combined sessions with joint cut file, 2 =
        % combined session with separate cut files.
        combined = 0;
        
        Xcounter = 0;
        
        str = fgetl(fid);
        if length(str) < 7
           error('Input file: no session');
        end

        if ~strcmpi(str(1:7), 'Session')
           error('Corrupt input file! Missing session data');
        else
           session = str(9:end);
        end

        str = fgetl(fid);
        if strcmpi(str(1:3), 'Cut')
            combined = 2;
            disp('Combined sessions with separate cut files detected')
            cutFile = str(5:end);
            % Read next line
            str = fgetl(fid);
            % Read session and cut info as long as there are more in the input
            % file
            getSess = 1;
            while 1
                if getSess % Session or room info expected next
                    if strcmpi(str(1:7), 'Session')
                        Xcounter = Xcounter + 1;
                        Xsessions{Xcounter} = str(9:end);
                        getSess = 0;
                        str = fgetl(fid);
                    else
                        % No more session
                        break
                    end
                else % Cut info expected next
                    if strcmpi(str(1:3), 'cut')
                        Xcut{Xcounter} = str(5:end);
                        str = fgetl(fid);
                        getSess = 1;
                    else
                        error('Missing cut file!');
                    end
                end
            end
        end
        
        while strcmpi(str(1:7),'Session')
            % Sessions will be combined
            combined = 1;
            Xcounter = Xcounter + 1;
            Xsessions(Xcounter) = {str(9:end)};
            str = fgetl(fid);
        end
       
        if combined==1
            disp('Combined sessions with joint cut file detected');
            % Get shareed cut file for the combined sessions
            if strcmpi(str(1:3),'cut')
                cutFile = str(5:end);
                str = fgetl(fid);
            else
                error('Missing cut file!');
            end
        end
        
        % Get length of the linear track
        if length(str)<6
            error('Missing length information');
        end
        if strcmpi(str(1:6), 'length')
            trackLength = sscanf(str,'%*s%u');
            str = fgetl(fid);
        else
            error('Missing length information!');
        end
        % Get tracking colour used
        if length(str)<9
            error('Missing tracking information');
        end
        if ~strcmp(str(1:8),'Tracking') && ~strcmp(str(1:8),'tracking') && ~strcmp(str(1:8),'TRACKING')
            error('Missing tracking information');
        else
            tracking = str(10:end);
        end
        
        % Read eeg data
        eegext = '.eeg';
        eegfile = sprintf('%s%s',session, eegext);
        disp(sprintf('%s%s','Read EEG data from file: ',eegfile));
        [EEG, Fs] = readeeg(eegfile);
        [EGF, FsEgf] = readEGF(sprintf('%s.egf', session));
        
        inpFile = sprintf('%s.inp',session);
        
        % Import the position data from the inp file
        [post, posx] = getDTD(inpFile);
        N = length(posx);
        posy = zeros(N,1);
        cPost = post;
        % Mean filter
        for cc = 8:length(posx)-7
            posx(cc) = nanmean(posx(cc-7:cc+7));
        end
        
        if combined==1 || combined==2
            timeOffset = [];
            % Make sure that the dimension is correct
            if size(post,1) < size(post,2)
                post = post';
                posx = posx';
                cPost = cPost';
            end
            combPosX = posx;
            combPosY = posy;
            combPosT = post;
            for ii = 1:Xcounter
                eegfile = sprintf('%s%s',Xsessions{ii},eegext);
                [xEEG, xFs] = readeeg(eegfile);
                if Fs ~= xFs
                    % Not the same sampling rate in the eeg signals. Issue an
                    % error message and terminate the program.
                    msgbox('Error: Not same sampling rate in the eeg signals');
                    disp('Error: Not same sampling rate in the eeg signals');
                    disp('Analysis was terminated')
                    return
                end
                EEG = [EEG; xEEG];
                
                [xEGF, xFsEgf] = readEGF(sprintf('%s.egf', Xsessions{ii}));
                if FsEgf ~= xFsEgf
                    error('Not a same sampling rate');
                end
                EGF = [EGF; xEGF];
                inpFile = sprintf('%s.inp',Xsessions{ii});
                
                % Time offset
                offset = combPosT(end) + 0.02;
                
                 % Import the position data from the inp file
                [post, posx] = getDTD(inpFile);
                N = length(posx);
                posy = zeros(N,1);
                cPost = [cPost; (post+offset)'];
                % Mean filter
                for cc = 8:length(posx)-7
                    posx(cc) = nanmean(posx(cc-7:cc+7));
                end
                timeOffset = [timeOffset; offset];
                combPosX = [combPosX; posx'];
                combPosY = [combPosY; posy];
                combPosT = [combPosT; (post+offset)']; 
            end
            
            % Centre the track in the coordinate system
            maxX = max(combPosX);
            maxX = maxX(1);
            minX = min(combPosY);
            minX = minX(1);
            centre = (maxX+minX)/2;
            combPosX = combPosX - centre;

            % Observed length of the track
            obsLength = max(combPosX)-min(combPosX);

            % Ratio between observed track length and real length.
            ratio = obsLength/trackLength;

            % Adjust coordinates
            combPosX = combPosX/ratio;
            combPosY = combPosY/ratio;
        else
            % single session
            maxX = max(posx);
            maxX = maxX(1);
            minX = min(posy);
            minX = minX(1);
            centre = (maxX + minX)/2;
            posx = posx - centre;

            % Observed length of the track
            obsLength = max(posx)-min(posx);

            % Ratio between observed track length and real length.
            ratio = obsLength/trackLength;

            % Adjust coordinates
            posx = posx/ratio;
            posy = posy/ratio;
        end
 
        % Band pass filter the eeg signal to take out the theta band (6-10 Hz)
        EEG = fftbandpass(EEG, Fs,5,6,10,11);
        fake.EEG = fftbandpass(EGF, FsEgf, 5, 6, 10, 11);
        fake.Fs = FsEgf; % Put high frequency data in a fake structure to
                % save it under name EEG, FS.
        
        [sessionName, mouseName] = extractSessionAndMouse(session);
        if combined == 1 || combined == 2
            lastSession = Xsessions{end}(end-1:end);
            filebase = fullfile(p.outputDir, sprintf('%s-%s+%s_', mouseName, sessionName, lastSession));
            save(strcat(filebase, 'eeg'), 'EEG', 'Fs');
            save(strcat(filebase, 'egf'), '-struct', 'fake', 'EEG', 'Fs');

            fake.post = combPosT;
            fake.posx = combPosX;
            save(strcat(filebase, 'POS'), '-struct', 'fake', 'posx', 'post');

            post = combPosT;
            posx = combPosX;
            posy = combPosY;
        else
            filebase = fullfile(p.outputDir, sprintf('%s-%s_', mouseName, sessionName));
            save(strcat(filebase, 'eeg'), 'EEG', 'Fs');
            save(strcat(filebase, 'egf'), '-struct', 'fake', 'EEG', 'Fs');

            fake.post = post;
            fake.posx = posx;
            save(strcat(filebase, 'POS'), '-struct', 'fake', 'posx', 'post');
        end
        
        % Continue to read data from the input file
        str = fgetl(fid);
        while ~feof(fid)
            if strcmp(str,'---') % End of this block of data, start over.
                break
            end
            if length(str) > 7
                if strcmpi(str(1:7), 'Tetrode')
                    tetrode = sscanf(str, '%*s %u');

                    % Import data from cut file(s)
                    if combined == 0
                        cutFile = sprintf('%s_%u.cut',session,tetrode);
                        cut = getcut(cutFile);
                    elseif combined == 1
                        cut = getcut(cutFile);
                    else
                        % Read the separate cut files, and join them together
                        cut = getcut(cutFile);
                        for ii = 1:Xcounter
                            cutTemp = getcut(Xcut{ii});
                            cut = [cut; cutTemp];
                        end
                    end
                    
                    % Get spike data
                    datafile = sprintf('%s.%u',session,tetrode);
                    ts = getspikes(datafile);
                    if combined==1 || combined==2
                        combTS = ts;
                        for ii = 1:Xcounter
                            datafile = sprintf('%s.%u',Xsessions{ii},tetrode);
                            ts = getspikes(datafile);
                            combTS = [combTS; ts+timeOffset(ii)];
                        end
                        ts = combTS;
                    end

                    str = fgetl(fid);
                    while length(str) > 4 && strcmpi(str(1:4), 'Unit')
                        unit = sscanf(str,'%*s %u');
                        
                        % Truncate the data
                        ind = find(post > param.startTime & post < param.stopTime);
                        posx = posx(ind);
                        posy = posy(ind);
                        post = post(ind);
                        cPost = cPost(cPost >= param.startTime & cPost <= param.stopTime);
                        ind = find(ts >= param.startTime & ts <= param.stopTime);
                        ts = ts(ind);
                        cut = cut(ind);
                        
                        
                        cellTS = ts(cut == unit);
                        save(strcat(filebase, sprintf('T%uC%u', tetrode, unit)), 'cellTS');
                        str = fgetl(fid);
                    end
                else
                    str = fgetl(fid);
                end
            else
                str = fgetl(fid);                
            end
        end
    end
    
    fprintf('Done\n');
end

% Reads EEG data
function [EEG,Fs] = readeeg(datafile)
    fid = fopen(datafile, 'r');
    for i = 1:8
       textstring = fgetl(fid);
    end
    textstring = textstring(13:end-3);
    Fs = sscanf(textstring,'%f');
    for i = 1:3
       textstring = fgetl(fid);
    end
    nosamples = sscanf(textstring(17:end),'%u');
    fseek(fid,10,0);
    EEG = fread(fid, nosamples,'int8');
    fclose(fid);
end

% [EEG,Fs] = readEGF(datafile)
%
% Reads high sampled eeg data and returns it in the array EEG together with the
% sampling rate Fs.
%
% Version 1.0. May 2006.
%
% Raymond Skjerpeng, CBM, NTNU, 2006.
function [EEG, Fs] = readEGF(datafile)
    % Open the file for reading
    status = 0;
    EEG = [];
    Fs = [];
    bytesPerSample = [];
    fid = fopen(datafile,'r');
    if fid == -1
        error('Failed to open file %s', datafile);
        return
    end
    
    c = onCleanup(@() fclose(fid));
    
    % Skip some lines of the header
    for ii = 1:8
       textstring = fgetl(fid);
    end

    % Read out the sampling rate
    Fs = sscanf(textstring(13:end-3),'%f');
    % Read out the number of bytes per sample
    textstring = fgetl(fid);
    bytesPerSample = sscanf(textstring(18:end),'%f');
    % Skip some more lines of the header
    textstring = fgetl(fid);
    % Read out the number of samples in the file
    nosamples = sscanf(textstring(17:end),'%u');
    % Go to the start of data (first byte after the data_start marker)
    fseek(fid,10,0);

    % Read data according to the number of bytes used per sample
    if bytesPerSample == 1
        EEG = fread(fid,nosamples,'int8');
    else
        EEG = fread(fid,nosamples,'int16');
    end
end


% Reads the inp file
function [pathTime,pathValue] = getDTD(inputfile)
    timeRes = 50;       %Hz
    diodeDist = 5;      % Distance between IR diodes. (5 cm).
    timebase = 1000;    %Default, but read this from file


    % Open the inputfile for reading
    [fid,errorMessage] = fopen(inputfile,'r');
    if fid == -1
        disp(['Error opening "',inputfile,'" : ', errorMessage])
    end

    % search for 'num_inp_samples'.
    temp = fread(fid,15,'char=>char')';
    while ~strcmp(temp,'num_inp_samples')
        temp(1:14) = temp(2:15);
        temp(15) = fread(fid,1,'char=>char');
    end
    fread(fid,1,'*char');
    NumberOfSamples = str2double(fgetl(fid));

    % search for 'data_start'.
    temp = fread(fid,10,'char=>char')';
    while ~strcmp(temp,'data_start')
        temp(1:9) = temp(2:10);
        temp(10) = fread(fid,1,'char=>char');
    end

    % READ DATA
    Data        = fread(fid,[7,NumberOfSamples],'uint8');   % 7 byte structures

    Vector      = [256^3,256^2,256,1,1,256,1];              % Format of data structure (big-endian)
    Matrix      = repmat(Vector,NumberOfSamples,1);         % Matrix of --^ matching the size of the Data array

    ValueData   = Data' .* Matrix;                          % Convert byte values to their "true values"
    digiTime    = sum(ValueData(:,1:4),2) / timebase;       % from 4 bytes Timestamp to 1 integer,    
    digiValue   = sum(ValueData(:,6:7),2);                  % from 2 bytes Value to 1 integer; This is distance in LED-number



    %Close inputfile  
    fclose(fid); 

    % Ignore 4 most significant bits (in case remote control is used)
    digiValue = bitand(digiValue,4095);

    % Divide into negative and positive path
    pI        = find(digiValue > 511 & digiValue < 2048);
    pValue    = digiValue(pI) - 512;     %positive positions
    pTime     = digiTime(pI);             %positive timestamps

    nI        = find(digiValue < 512);
    nValue    = digiValue(nI);            %negative positions
    nTime     = digiTime(nI);             %negative timestamps


    % Divide paths into positive and negative runs
    hilim = 350;
    lolim = 10;

    band = find(pValue > hilim | pValue < lolim);
    gaps = find( (pTime(band(2:length(band))) - pTime(band(1:length(band)-1))) > 15); %more than 15 sec gap == rat is between the ends of the track

    M1 = gaps(2:length(gaps));      %start of each run except the first
    M2 = gaps(1:length(gaps)-1)+1; % end of each run except the last
    TurningPointTimes = mean( [pTime(band(M1)),pTime(band(M2))],2 );

    Runs = [1];
    for cc = 1 : 1 : length(TurningPointTimes)  %change this to 2-dim matrix operation. faster.
        [v,i] = min(abs(pTime-TurningPointTimes(cc)));
        Runs = [Runs;i];
    end
    Runs = [Runs;length(nTime)]; % Contains index in pTime to all turning points

    posPath = [];
    negPath = [];


    endpoint = 1;
    if mod(numel(Runs),2) == 0   % Runs has even number of endpoints meaning uneven number of runs.
        endpoint = 3;
    end

    for cc = 1 : 2: length(Runs)-endpoint
        posPath = [posPath, Runs(cc):Runs(cc+1)];
        negPath = [negPath, Runs(cc+1):Runs(cc+2)];
    end


    % Pick max vals from positive path and min vals from negative path
    posI = [];
    negI = [];
    cPl = 0; %current Positive level, init for positive run.
    cNl = 0; %current Negative level

    for ii = 1 : length(posPath)
        if (pValue(posPath(ii)) > cPl  ) 
            posI = [posI;posPath(ii)];
            cPl = pValue(posPath(ii));

        else if (cPl > 350 && pValue(posPath(ii)) < 10)  % we're at the bottom again
                posI = [posI;posPath(ii)];
                cPl = 0;            % reset positive value to start a new positive run
            end
        end
    end

    for ii = 1: length(negPath)
        if (nValue(negPath(ii)) < cNl )
            negI = [negI;negPath(ii)];
            cNl = nValue(negPath(ii));

        else if (cNl < 10 && nValue(negPath(ii)) > 350)    % we're at the top
            negI = [negI;negPath(ii)];
            cNl = 361;
            end
        end
    end


    % Combine paths into one and multiply by diode distance
    pathValue = [pValue(posI);nValue(negI)];
    pathTime = [pTime(posI);nTime(negI)];
    [pathTime,i] = sortrows(pathTime);
    pathValue = pathValue(i) .* diodeDist; 

    % interpolate path
    timeResolution = 1/timeRes;   % 50Hz
    xi = pathTime(1) : timeResolution : pathTime(length(pathTime));
    yi = interp1(pathTime,pathValue,xi, 'cubic');

    pathTime = xi;
    pathValue = yi;
end


function [posx,posy,post] = getpos(posfile,colour,arena)
    %  
    %   [posx,posy,post] = getpos(posfile,colour,arena)
    %
    %   Copyright (C) 2004 Sturla Molden
    %   Centre for the Biology of Memory
    %   NTNU
    %   Modified by Raymond Skjerpeng 2004

    [tracker,trackerparam] = importvideotracker(posfile);
    if (trackerparam.num_colours ~= 4)
        error('getpos requires 4 colours in video tracker file.');
    end    
    post = zeros(trackerparam.num_pos_samples,1);


    N = size(tracker(1).xcoord,2);
    if N == 2 % A two point tracking has been done 
        temp = zeros(trackerparam.num_pos_samples,4);
    else % Normal tracking
        temp = zeros(trackerparam.num_pos_samples,8);
    end
    for ii = 1:trackerparam.num_pos_samples
        post(ii) = tracker(ii).timestamp;
        temp(ii,:) = [tracker(ii).xcoord tracker(ii).ycoord];
    end

    % Make sure all timestamps are unique
    [didFix,fixedPost] = fixTimestamps(post);
    if didFix
        post = fixedPost;
    end

    if N == 4
        switch colour
            case {'red LED'}
                posx = temp(:,1) + trackerparam.window_min_x;
                posy = temp(:,5) + trackerparam.window_min_y;
            case {'green LED'}
                posx = temp(:,2) + trackerparam.window_min_x;
                posy = temp(:,6) + trackerparam.window_min_y;
            case {'blue LED'}
                posx = temp(:,3) + trackerparam.window_min_x;
                posy = temp(:,7) + trackerparam.window_min_y;
            case {'black on white'}
                posx = temp(:,4) + trackerparam.window_min_x;
                posy = temp(:,8) + trackerparam.window_min_y;
            otherwise
                error(sprintf('unknown colour "%s"',colour));
        end    
    end
    if N == 2
        M = length(temp(:,1));
        n1 = sum(isnan(temp(:,1)));
        n2 = sum(isnan(temp(:,2)));
        if n1 > n2
            posx = temp(:,2);
            posy = temp(:,4);
        else
            posx = temp(:,1);
            posy = temp(:,3);
        end
    end

    numPos = length(posx);
    numPost = length(post);
    if numPos ~= numPost
        posx = posx(1:numPost);
        posy = posy(1:numPost);
    end


    % Set values that are outside camera scope to NaN
    ind = find(posx>1024 | posy>1024);
    posx(ind) = NaN;
    posy(ind) = NaN;

    if (nargin > 2)
        [posx, posy] = arena_config(posx,posy,arena);
    end
    post = post - post(1);
end

function [posx, posy] = arena_config(posx,posy,arena)
    switch arena
        case 'room0'
            centre = [433 256];
            conversion = 387;
        case 'room1'
            centre = [421 274];
            conversion = 403;
        case 'room2'
            centre = [404 288];
            conversion = 400;
        case 'room3'
            centre = [356 289]; % 2. Nov 2004
            conversion = 395;
        case 'room4'
            centre = [418 186]; % 2. Des 2006
            conversion = 210;
        case 'room5'
            centre = [406 268]; % 2. Nov 2004
            conversion = 317;   % 52 cm abow floor, Color camera
        case 'room5bw'
            centre = [454 192]; % 2. Nov 2004
            conversion = 314;   % 52 cm abow floor, Black/White camera
        case 'room5floor'
            centre = [422 266]; % 2. Nov 2004
            conversion = 249;   % On floor, Color camera
        case 'room5bwfloor'
            centre = [471 185]; % 2. Nov 2004
            conversion = 249;   % On floor, Black/White camera
        case 'room6'
            centre = [402 292]; % 1. Nov 2004
            conversion = 398;
        case 'room7'
            centre = [360 230]; % 11. Oct 2004
            conversion = 351;
        case 'room8'
            centre = [390 259]; % Color camera
            conversion = 475;   % January 2006, 52 cm abow floor, 
        case 'room8bw'
            centre = [383 273]; % 11. Oct 2004
            conversion = 391;   % 66 cm abow floor, Black/White camera
        case 'room9'
            centre = [393, 290]; % 16. Mars 2006
            conversion = 246;
        case 'room10'
            centre = [385, 331]; % 17. Mars 2006
            conversion = 247;
    end
    posx = 100 * (posx - centre(1))/conversion;
    posy = 100 * (centre(2) - posy)/conversion;
end

function [posx,posy,post] = removeNaN(posx,posy,post)
    while 1
        if isnan(posx(end)) || isnan(posy(end))
            posx(end) = [];
            posy(end) = [];
            post(end) = [];
        else
            break;
        end
    end
end


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


function clust = getcut(cutfile)
    fid = fopen(cutfile, 'rt');
    clust = [];
    while ~feof(fid)
        string = fgetl(fid);
        if (length(string))
            if (string(1) == 'E') 
                break;
            end
        end
    end
    while ~feof(fid)
      string = fgetl(fid);
      if length(string)
         content = sscanf(string,'%u')';
         clust = [clust content];

      end
    end
    fclose(fid);
    clust = clust';
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

function xf = fftbandpass(x,Fs,Fs1,Fp1,Fp2,Fs2)
% function XF = fftbandpass(X,FS,FS1,FP1,FP2,FS2)
%
% Bandpass filter for the signal X (time x trials). An acuasal fft 
% algorithm is applied (i.e. no phase shift). The filter functions is         
% constructed from a Hamming window. 
%
% Fs : sampling frequency
%
% The passbands (Fp1 Fp2) and stop bands (Fs1 Fs2) are defined as
%                 -----------                      
%                /           \
%               /             \
%              /               \
%             /                 \
%   ----------                   ----------------- 
%           Fs1  Fp1       Fp2  Fs2              
%
% If no output arguments are assigned the filter function H(f) and
% impulse response are plotted. 
%
% NOTE: for long data traces the filter is very slow.
%
%------------------------------------------------------------------------
% Ole Jensen, Brain Resarch Unit, Low Temperature Laboratory,
% Helsinki University of Technology, 02015 HUT, Finland,
% Report bugs to ojensen@neuro.hut.fi
%------------------------------------------------------------------------

%    Copyright (C) 2000 by Ole Jensen 
%    This program is free software; you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation; either version 2 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You can find a copy of the GNU General Public License
%    along with this package (4DToolbox); if not, write to the Free Software
%    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    if size(x,1) == 1
        x = x';
    end
    % Make x even
    Norig = size(x,1); 
    if rem(Norig,2)
        x = [x' zeros(size(x,2),1)]';                
    end

    % Normalize frequencies  
    Ns1 = Fs1/(Fs/2);
    Ns2 = Fs2/(Fs/2);
    Np1 = Fp1/(Fs/2);
    Np2 = Fp2/(Fs/2);

    % Construct the filter function H(f)
    N = size(x,1);
    Nh = N/2;

    B = fir2(N-1,[0 Ns1 Np1 Np2 Ns2 1],[0 0 1 1 0 0]); 
    H = abs(fft(B));  % Make zero-phase filter function
    IPR = real(ifft(H));
    if nargout == 0 
        subplot(2,1,1)
        f = Fs*(0:Nh-1)/(N);
        plot(f,H(1:Nh));
        xlim([0 2*Fs2])
        ylim([0 1]); 
        title('Filter function H(f)')
        xlabel('Frequency (Hz)')
        subplot(2,1,2)
        plot((1:Nh)/Fs,IPR(1:Nh))
        xlim([0 2/Fp1])
        xlabel('Time (sec)')
        ylim([min(IPR) max(IPR)])
        title('Impulse response')
    end


    if size(x,2) > 1
        for k=1:size(x,2)
            xf(:,k) = real(ifft(fft(x(:,k)) .* H'));
        end
        xf = xf(1:Norig,:);
    else
        xf = real(ifft(fft(x') .* H));
        xf = xf(1:Norig);
    end
end

function [ses, mouseName] = extractSessionAndMouse(path)
    [mousePath, ses] = fileparts(path);
    [~, mouseName] = fileparts(mousePath);
end
