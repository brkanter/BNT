%__________________________________________________________________________
%
%                       GridnessScore-legacy parameters
%__________________________________________________________________________

% Set this if the input file contains a line with room information for each
% session.
% 0 = No room information
% 1 = Room information exist
p.inputFileRoomInfo = 1;

% Size in centimeters for the bins in the ratemap
p.binWidth = 2.5; % [cm]

% Bin width for the head direction rate map.
p.hdBinWidth = 3; % [degrees]

% Bin width for the head direction time map. A map that will contain how
% much time the rat spends in each head direction.
p.hdTimeBinWidth = 6; % [degrees]

% Format of the images made by the program.
% format = 1 -> bmp (24 bit)
% format = 2 -> png
% format = 3 -> eps
% format = 4 -> jpg
% format = 5 -> tiff (24 bit)
% format = 6 -> fig (Matlab figure)
p.imageFormat = 2;

% Low speed threshold. Segments of the path where the rat moves slower
% than this threshold will be removed. Set it to zero (0) to keep
% everything. Value in centimeters per second.
p.lowSpeedThreshold = 2.5; % [cm/s]

% High speed threshold. Segments of the path where the rat moves faster
% than this threshold will be removed. Set it to zero (0) to keep
% everything. Value in centimeters per second.
p.highSpeedThreshold = 100; % [cm/s]

% Minimum radius used in the auto-correlogram when finding the best
% gridness score
p.minRadius = 20; % [cm]


% Increment step of the radius when calculating what radius gives the best
% gridness score.
p.radiusStep = p.binWidth; % [cm]

% When calculating gridness score based on the best radius, the program
% calculates the gridness score as an average over adjacent radii. This
% parameter sets the number of radii to use. The number must be odd. The
% middle radius will be set to be the best radius.
p.numGridnessRadii = 3;

% Threshold value used when defining the centre field. Border of centre
% field is defined as the place where the correlation falls under this
% threshold or the correlation start to increase again.
p.correlationThresholdForCentreField = 0.2;

% Sets how the gridness values are calculated.
% Mode = 0: Gridness is calculated as the mean correlation at 60 and 120
%           degrees minus the mean correlation at 30, 90 and 150 degrees.
% Mode = 1: Gridness is calculated as the minimum correlation at 60 and 120
%           degrees minus the maximum correlation at 30, 90 and 150
%           degrees.
p.gridnessCalculationMode = 1;

% Minimum allowed width of the correlogram disk. I.e the distance from the
% centre radius to the radius that gives the best gridness score. If the
% centre field radius is closer to the edge of the correlogram than the
% disk with, the gridness score will be NaN.
p.minDiskWidth = 10; % [cm]

% Set if the shuffling analysis will be done. This analysis takes a long
% time and should be omitted if you don't need the expected values. You can
% choose to do the shuffling for only selected variables by setting the
% list below.
% 1 = Do the shuffling analysis
% 0 = Omit shuffling analysis
p.doShufflingAnalysis = 0;

% Set what calculations that have to be done in the shuffling analysis.
% 1 = Do the analysis
% 0 = Omit the analysis
p.shuffleAnalysisList = zeros(9,1);
% Gridness score peak based (small time saving, if the normal gridness
% score is calculated. Huge time saving if both gridness calculations are
% omitted)
p.shuffleAnalysisList(1) = 0;
% Spatial Coherence unsmoothed (Very little time saving)
p.shuffleAnalysisList(2) = 0;
% Stability. Both Spatial and Angular. (Large time saving)
p.shuffleAnalysisList(3) = 0;
% Mean Vector Length for head direction mapo. The p.doHeadDirectionAnalysis
% must also be set to 1 for this one to be calculated. (Small time saving)
p.shuffleAnalysisList(4) = 0;
% Normal gridness score.  (small time saving, if the peak based gridness
% score is calculated. Huge time saving if both gridness calculations are
% omitted)
p.shuffleAnalysisList(5) = 0;
% Mean vector length for movement direction. The p.doMovementDirectionAnalysis
% parameter must also be set to one for this one to be calculated (small
% time saving)
p.shuffleAnalysisList(6) = 0;
% Border score. (If both this and spatial information is omitted it will
% save time)
p.shuffleAnalysisList(7) = 0;
% Spatial information (If both this and border socre is omitted it will
% save time)
p.shuffleAnalysisList(8) = 0;
% Theta power ratio for the temporal spike autocorrelogram.
% NOTE: You have to run p.scrambleMode = 0 for this analysis. Using
%       p.scrambleMode = 1 will give the same result for every shuffle
%       since the inter spike times stay the same. For all the other
%       variables in the shuffling we usually run with p.scrambleMode = 1.
p.shuffleAnalysisList(9) = 1;
% Flag that specifies whether to do shuffling for directional information or not.
% Possible values are true or false.
p.doDirInformationShuffle = true;

% Number of iterations to do in the shuffling analysis. The shuffling is
% done to calculate expected gridness score, expected spatial information
% and expected head direction score.
p.numShuffleIterations = 100;

% During the analysis of shuffled data, it is 'shuffled' again to obtain
% confidence intervals. See article 'Development of the Spatial Representation
% System in the Rat' by Langston et. al, Science 2010. You need to look at figure
% S12.
% 1) Obtain values for P95 and P99 from shuffled data.
% 2) Pick N samples from shuffled data (N - number of cells).
% 3) Calculate percentage of samples that lie above P95 or P99.
% 4) Repeat this p.numSecondShuffleIterations times
% 5) Calculate mean value of percentages of values that lie above the threshold.
p.numSecondShuffleIterations = 100000;

% Scramble mode. Set the way the spikes are scrambled when calculating the
% expected values.
% Mode = 0: Spikes are shifted randomly around on the path for each
%           iteration.
% Mode = 1: All the spikes are shifted by a random time t for each
%           iteration. The inter spike time intervals are kept as in the
%           original spike times. Spike positions are calculated based on the
%           shifted spike time stamps. The minimum allowed time shift is
%           set in the parameter p.minTimeShift. This is to avoid zero
%           shift.
p.scrambleMode = 0;

% Set if the head direction analysis will be done. For this your position
% data must have been recorded in 2-spot mode. If you don't have this or
% don't need the head direction information set this parameter to 0.
% 1 = Do the head direction analysis
% 0 = Omit the head direction analysis
p.doHeadDirectionAnalysis = 1;

% Set if the movement direction analysis will be done. If set the
% directional rate map based on movement direction (not head direction)
% will be calculated. The Rayleigh mean vector length for the directional
% rate map will be calculated and the preferred movement direction.
% 1 = Do the movement direction analysis
% 0 = Omit the movement direction analysis
p.doMovementDirectionAnalysis = 0;

% Percentile value for the arc percentile calculation. Value in percentage.
p.percentile = 50; % [%]


% Minimum allowed timeshift when scramble mode 1 is used.
p.minTimeShift = 20; % [sec]

% Sets the smoothing type for the spatial firing map.
% Mode = 0: Gaussian boxcar smoothing with 5 x 5 bin boxcar template
% Mode = 1: Gaussian boxcar smoothing with 3 x 3 bin boxcar template
p.smoothingMode = 0;

% Alpha value for the adaptive smoothing rate map calculation. In use for
% the spatial information calculation
p.alphaValue = 10000;

% Same as p.alphaValue, but for the head direction map
p.hdAlphaValue = 10000;

% Number of smoothing bins for turning curves. Default value is 2.
p.hdSmoothingNumBins = 2;

% Head direction firing map smoothing mode
% Mode = 0: Boxcar smoothing of length 5
% Mode = 1: Flat smoothing window. The size of the filter is set in the
%           parameter p.hdSmoothingWindowSize.
p.hdSmoothingMode = 1;

% Size of the smoothing window when using flat smoothing window for the
% head direction map. The size is the total span of the filter. Please make
% the size an odd integer multippel of the head direction bin width
% (p.hdBinWidth). If this is not the case the program will round the number
% of to make it a odd multippel of the head direction bin width,
p.hdSmoothingWindowSize = 14.5; % [degrees]

% Name for the folder where the images will be stored. In addition the name
% of the input file will be used in the folder name. Example: in121314.txt
% will give a folder name gridnessImages_in121314
p.imageFolder = 'gridnessImages';

% Set the minimum allowed coverage. If the animal have covered less than
% this amount of the arena the cells from the session are not included in
% the shuffling analysis. Value as percentage between 0 and 100.
p.minCoverage = 80; % [%]

% Minimum allowed number of spikes for a cell for it to be included in the
% shuffling analysis. It is the number of spikes left after speed filtering
% that must be over the minimum number of spikes value.
p.minNumSpikes = 100;

% Bin width for the shuffled data. If you need to bin with different
% binning you can enter more than one value in square brackets.
% (p.binWidthShuffleData = [0.05, 0.10, 0.20];) It will be created one file
% with binned values for each binning value in the array.
p.binWidthShuffleData = 0.01;


% Minimum number of bins in a placefield. Fields with fewer bins than this
% treshold will not be considered as a placefield. Remember to adjust this
% value when you change the bin width
p.minNumBins = 5;

% Bins with rate at p.fieldTreshold * peak rate and higher will be considered as part
% of a place field
p.fieldTreshold = 0.2;

% Lowest field rate in Hz. Peak of field.
p.lowestFieldRate = 1; % [Hz]

% Threshold used when finding peaks in the auto-correlogram in the grid
% orientation calculation
% you may need to tweak this threshold value to find correct fields when
% grid is messy
p.gridOrientationThreshold = 0.5;

% It is possible to only analyse part of the recording by setting these
% values. If both are set to zero the whole recording will be used. When
% one or both are set to non-zero values only data within the interval is
% used for analysing.
p.startTime = 0; % [second]
p.stopTime = 0; % [second]

% Set if we include the time the rat spend in each directional bin in the
% output file
% 0 = no
% 1 = yes
p.includeDirectionalBins = 0;

% Minimum time bins in the rate map must have been visited by the rat. Bins
% with less time will be set to NaN, and plotted as white pixels. This
% apply only to the normal rate maps and not the adaptive smoothed rate
% maps. Time in seconds.
p.minBinTime = 0.020; % [sec]

% Size of the dots that mark the spikes in the path plot. The size is set
% in dots (1 dot = 1/72 inch). Note that Matlab draws the point marker at
% one third the specified size. Default values is 6 points.
p.spikeDotSize = 14;
p.spikeColor = 'k';

% Width of the line that marks the path. Default value is 0.5
p.pathLineWidth = 0.2;
p.pathLineColor = [0.8 0.8 0.8];

% Width of the line that marks the outline of the head direction rate map
% (polar plot). Value is set in points. (1 point = 1/72 inch)
% Default width is 0.5 points.
p.hdMapLineWidth = 1;

% Value that specify what rate the red colour in the rate maps will
% correspond to. If the value is set to zero the red colour will correspond
% to the peak rate of the map. If a map have bins with higher rate than the
% maximum set in this parameter the bins will be plotted as red. Set the
% value to zero or a positive integer or floating point number.
p.maxPlotRate = 0;

% Set how much of the correlogram is used when finding the orientation line
% that gives the highest mean correlation in the correlogram. (Requested
% from Jonathan Whitlock). Value is set in percentage of the maximum side
% length and defines the radius of a circle with centre in the centre of
% the correlogram. Note that even on 100 percent the corners of the
% correlgoram will be cut out.
p.gridOrientationLineMaximumSize = 100;

% Bin width for the autocorrelogram from the spike train. Used in the theta
% power ratio calculation.
p.acgBinWidth = 0.002; % [Sec]

% Length of the spike train autocorrelogram.
p.acgDiagramLength = 0.500; % [Sec]

% Frequencies below this value will not be used in calculating the mean
% power of the auto-correlogram.
p.fftLowestFrequency = 0; % [Hz]

% Frequency border values for the theta band
p.thetaLow = 4; % [Hz]
p.thetaHigh = 11; % [Hz]

% Controls whether to save copy of all plots, but without axis. Possible values
% are 'true' and 'false'. If set to TRUE there will be an additional file for
% each image with name suffix _NoAxis
p.saveNoAxis = false;

% Trajectory plot is normalized to make it smaller.
% It's size is p.trajectoryNorm of 1.
p.trajectoryNorm = 1/4;

%__________________________________________________________________________
