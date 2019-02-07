% Percentile value for the head direction arc calculation. Arc is between two points with
% values around globalPeak * (p.percentile / 100). Value is in percentage.
p.percentile = 50; % [%]

% Width of the line that marks the outline of the head direction rate map (polar plot).
% Value is set in points. (1 point = 1/72 inch)
% Default width is 0.5 points.
p.hdMapLineWidth = 1;

% Bin width for turning curves (head direction, moving direction rate maps).
p.hdBinWidth = 3; % [degrees]

% Smoothing size in bins for turning curves (head direction, trajectory, moving direction maps).
% (0 = no smoothing)
p.hdSmooth = 1; % [bins]

% Head direction measurements are separated in 3 different groups:
% 1) clockwise direction (CW). Samples with angular velocity v > p.hdTurnSpeedThreshold.
% 2) counterclockwise direction (CCW). Samples with angular velocity v < -p.hdTurnSpeedThreshold.
% 3) still. Samples with abs(v) < p.hdStillSpeedThreshold.
% If p.hdStillSpeedThreshold < abs(v) < p.hdTurnSpeedThreshold, then the sample is discarded.
p.hdTurnSpeedThreshold = 90; % [degrees/sec]

% See p.hdTurnSpeedThreshold.
p.hdStillSpeedThreshold = 15; % [degrees/sec]

% Format of the output images. It is possible to specify multiple
% values simultaneously. For this, imageFormat should be a cell array.
% For example, p.imageFormat = {'png' 'tiff' 'eps'}.
% Otherwise use a simple string: p.imageFormat = 'png'.
%
% Possible values are:
% format = 'bmp' (24 bit)
% format = 'png'
% format = 'eps'
% format = 'jpg'
% format = 'tiff' (24 bit)
% format = 'fig' (Matlab figure)
% format = 'pdf'
% format = 'svg'
p.imageFormat = 'png';

% DPI setting for stored images
p.imageDpi = 300;

% Number of time shifts during the time shift analysis.
% Example. We have recording sampling rate 50 Hz = 20 msec. With
% p.numTimeShifts == 5, we will include time from -5*20 msec up to 5*20 msec.
p.numTimeShifts = 5;

% Bin width for firing rate maps
p.binWidth = 5.0; % [cm]

% Controls the colour-scaling of a rate map plot. You can use this parameter if you want to
% plot several rate maps with the same colour scale.
%
% Format is p.rateMapScalling = [lower_end higher_end], where both values are given in Hz.
% When empty ([]) or NaN, then the plot is autoscaled: the lowest value of
% the map is represented by dark blue and the highest value of the map is represented by brown.
% Otherwise everything which is below or equal 'lower_end' value is represented by dark blue,
% and 'higher_end' is represented by brown. It's possible to set only one value to NaN:
% p.rateMapScalling = [NaN 15] will scale from the minimum value of the map up to 15 Hz.
% Default is p.rateMapScalling = [];, which means autoscale is used.
p.rateMapScalling = []; % Hz

% Smoothing size in bins for firing rate maps. (0 = no smoothing)
p.smooth = 2; % [bins]

% Determines how to deal with bins with no animal activity on the rate map.
% 'on' means that these bins will be blank and white (nan values are used).
% 'off' means that these bins will be 0 (results in deep blue colour).
% See help of function analyses.map.
p.rateMapShowBlanks = 'on';

% Low and high speed thresholds. Defines segments of path where animal moves slower/faster
% than the threshold. Such segments are removed from the processing. Set it to zero (0)
% to keep everything. Values are in centimetres per second.
% Common values found in GridnessScript are [2.5 100]
p.speedFilter = [0 0]; % [cm/s]

% Number of bins for a rate map. Sometimes it is more desirable to create
% rate maps in fixed number of bins, independently of bin width in
% centimetres. The parameter numBins could be either a single value or a
% two-element vector, i.e. [20 30]. If a single value is provided, then
% the map is divided in equal number of bins along both axes.
% !!! Most of the scripts doesn't use this value. Instead bin numbers is calculated
% through p.binWidth. Check the script you are running if it uses p.numBins. !!!
p.numBins = 20; % [20x20] for 2D maps

% Threshold for how far a rat can move (150cm/s) in one sample
p.distanceThreshold = 150;

% Set the maximum time gap in the position data that should be interpolated.
% If there are gaps with duration longer than this, then the samples will be left as NaN.
p.maxInterpolationGap = 1; % [sec]

% There could be outliers in tracked position samples. These are commonly several
% values between longer list of NaNs. They lie far away from 'good' points, so
% we discard everything that is further away than p.posStdThreshold*STD. If your
% data is somehow truncated strangely, then try to increase this threshold.
% Default value is 2.5
p.posStdThreshold = 2.5;

% This parameter is used during firing rate map calculation. Minimum time an animal
% must spend in a bin, in order to include this bin in the resulting firing map.
% In other words if an animal has spent less than p.binMinTime in a bin, the value
% of this bin is set to NaN. Default value is 0, meaning that all bins matter.
p.binMinTime = 0;

% During light stimulation analysis we are interested in spikes that occur some
% time before and after an event. This parameter defines this 'some time'. First
% value is how much milliseconds we should look back. Second value is how much
% milliseconds we should include after the event.
% Default values are 50 ms before the event and 100 ms after the event.
p.lightPulseOffset_ms = [50 100]; % [ms], millisecond

% Duration of stimulation phase in seconds. In use only for certain scripts!
% Example: There are light pulses of some frequency for total duration of
% stimulationDuration_sec == 5 seconds.
% Default value is 5, but you should really adjust it to your experiment;
p.stimulationDuration_sec = 5;

% Value of 'light on' event in an event file. In use in some scripts
% which need to find time of light on events.
% Default value is 1, but you should really adjust it to your experiment.
p.lightOnEventValue = 1;

% Alpha value for adaptive smoothing rate map calculation. Also in use for
% the spatial information calculation.
p.alphaValue = 10000;

% Nx2 matrix of session name pairs that should be used for rate map cross-correlation.
% Session name for NeuraLynx data is the name of the folder where data is located.
% Consider this example:
%   You have data in folders (and they appear in exact same order in your input file)
%       N:\wernle\LOOP_Project\18914\Recordings\050913_rec1\02. s1 To ends1
%       N:\wernle\LOOP_Project\18914\Recordings\050913_rec1\04. s2 To ends2
%       N:\wernle\LOOP_Project\18914\Recordings\050913_rec1\06. s3 To ends3
%   which are referenced as A, B, C correspondingly. So you want to correlate
%   A vs. C and B vs. C. Your parameter should be:
%   p.correlationSessionNames = {'02. s1 To ends1' '06. s3 To ends3'; '04. s2 To ends2' '06. s3 To ends3'};
% You can divide long line into smaller ones by using ellipses (...). Example:
% p.correlationSessionNames = {'02. s1 To ends1' '06. s3 To ends3'; ...
% '04. s2 To ends2' '06. s3 To ends3'; ...
% '02. s1 To ends1' '04. s2 To ends2'};
% DO NOT FORGET to divide pairs with ; character!
p.correlationSessionNames = {};

% Number of bins that are used as 'a single' entity during the correlation of rate maps.
% Example. We have two maps of size 20x20. If we do correlation with p.numCorrelationBins == 1,
% then the result is a single value. However, for p.numCorrelationBins == 2, the result will be
% an array with 20/2 = 10 elements.
p.numCorrelationBins = 1;

% Some scripts need to divide position data into smaller groups. This value specifies the time
% duration of each group, so that position data is divided into groups of p.posSampleTime seconds.
p.posSampleTime = 1; % [sec]

% Some scripts need to divide position data into smaller number of group. This value specifies
% number of these groups. For example, p.posNumGroups == 2 will result in division of position
% data in to halves. It's better to divide into even number of groups, i.e. multiple of 2
p.posNumGroups = 2;

% Field detection method for 2D field detection, a string with possible values
% 'adaptive' or 'threshold'. Threshold-based method uses p.fieldThreshold2D parameter.
% Adaptive method uses different threshold for each detected field. Default is 'threshold'.
% See also help of analyses.placefield and analyses.placefieldAdaptive.
p.fieldDetection2D = 'threshold';

% Threshold that is used to define place field in a 2D firing map.
% Value above threshold*peak belong to a field (default = 0.2).
p.fieldThreshold2D = 0.2;

% Minimum number of bins in a place field. Fields with fewer bins are not considered as place
% fields. Remember to adjust this value when you change the bin width (default = 9).
p.fieldMinBins = 9;

% Fields with peak value less than p.fieldMinPeak are considered spurious and ignored.
% Default value is 1. If this value is zero, then all fields are processed.
% Peak value is normally a rate, however, it's units are not necessary Hz.
p.fieldMinPeak = 1;

% Threshold type, see analyses.placefield1D.
% Default is '%'
p.fieldThresholdType_1d = '%';

% Threshold value, see analyses.placefield1D.
% Default is 0.2
p.fieldThreshold_1d = 0.2;

% Minimum number of row bins in a place field. See analyses.placefield1D.
% Default is 3
p.fieldMinRows_1d = 3;

% Minimum number of spikes in a place field. See analyses.placefield1D.
% Default is 0
p.fieldMinSpikes_1d = 0;

% Minimum number of bins between adjacent fields. See analyses.placefield1D.
% Default is 0
p.fieldMinDistance_1d = 0;

% Cell array of Lineseries Properties which are passed to Matlab's plot function
% when path plot is created. See Matlab's help (search for Lineseries Properties)
% for a complete list of possible values.
% Default values are: grey color and line width of 0.5 points.
p.plotPath = {'Color', [0.5 0.5 0.5], 'LineWidth', 0.5};

% Cell array of Lineseries Properties which are passed to Matlab's plot function
% in order to plot spikes. Here you can define the color of spikes, their shape
% and size.
% Defaults are: red point of size 15, no line between spikes
p.plotSpikes = {'Marker', '.', 'Color', [1 0 0], 'MarkerSize', 15, 'LineStyle', 'none'};

% Direction of increasing values along y-axis for plots. The value
% could be either 'normal' or 'reverse'. 'Normal' means that values increase from
% bottom to top, 'reverse' means that values decrease from bottom to top.
% Default value is 'normal'. Set to 'reverse' if you want to flip your rate maps vertically.
% This will also affect path plots for 2D environments.
p.plotYDir = 'normal';

% Trajectory plot is normalized to make it smaller. This happens because trajectory
% is often plotted on the same image as turning curve. Turning curve is normalized,
% i.e. it's maximum value is 1.
% Trajectory plot size is p.trajectoryNorm of 1.
p.trajectoryNorm = 1/4;

% Properties of a trajectory circular plot. Trajectory plot is a histogram of animal's
% positions binned to degrees 0..360.
% The parameter is a cell array if Lineseries Properties which are passed to Matlab's
% plot function. See Matlab's help (search for Lineseries Properties) for a complete
% list of possible values.
% Default values are: blue color
p.trajectoryPlot = {'Color', [0.28 0.6 0.75294]};

% If set to true, data in each group (see p.posNumGroups) is additionally filtered
% by moving direction. Animal should move in all four quadrants of a circle during
% a short period of time. Default is false.
p.filterByMovement = false;

% Value of the average firing rate filter. Each group of data (see p.posNumGroups)
% is additionally filtered by firing rate. If average rate of a group is lower
% than this value, then this group is skipped from the analysis.
% Value of 0 means that the filter is not used. Value units are Hz.
p.averageRateFilter = 0; % [Hz]

% Search width for the border score calculation. If map is not perfect, but contains NaN values
% along borders, then the search for border pixels can have NaNs. To mitigate this, we check
% searchWidth rows/columns near border and if the closest to the border pixel equals to NaN,
% we search for first non-NaN value in searchWidth rows-columns. Default value is 8.
p.borderSearchWidth = 8;

% Definition of walls along which the border score is calculated. Provided by a string which
% contains characters that stand for walls:
% T - top wall (we assume the bird-eye view on the arena)
% R - right wall
% B - bottom wall
% L - left wall
% Characters are case insensitive. Default value is 'TRBL' meaning that border
% score is calculated along all walls. Any combination is possible, e.g.
% 'R' to calculate along right wall, 'BL' to calculate along two walls, e.t.c.
p.borderWalls = 'TRBL';

% Definition of walls along which the border score is calculated for circular recording arenas.
% It is a Nx2 matrix, where N is number of borders and two elemnts represent beginning and end
% of a wall in degrees. One example which defines one wall around the whole arena:
% p.borderWallsCircular = [1 360;];
% Another example with two non-consequitive walls:
% p.borderWallsCircular = [1 90; 181 270];
% Note that you can not have 0 as a wall angle.
% Default value is [1 360];
p.borderWallsCircular = [1 360;];

% Recordings are stored in folders that correspond to animal's name or number.
% This function returns part of the stored data path, which is believed
% to be animal's name.
% Consider these example of sessions from an input file:
% * (Axona)       C:\work\recordings\<animal_name>\07040501
% * (Axona)       C:\work\recordings\<animal_name>\trials\07040501
% * (NeuraLynx)   C:\work\recordings\Ivan\050913_rec1\02. s1 To ends1
% * (NeuraLynx)   C:\work\recordings\Ivan\050913_rec2
% To extract animal name from the first path, you have to set animalNameLevel to 1.
% To extract animal name from the second path, you have to set animalNameLevel to 2.
% Third - 2, fourth - 1.
% In other words, you have to count from right to left. For Axona, current folder is 1,
% next folder up is 2. For NeuraLynx, first folder up is 1, next folder up is two.
%
% Some scripts always use animal name in their output even if p.animalNameLevel is set
% to 0. These scripts treat value 0 as 1.
p.animalNameLevel = 0;

% Normalized threshold value used to search for peaks on an autocorrelogram.
% Ranges from 0 to 1, default value is 0.2. See also analyses.gridnessScore
p.gridnessThreshold = 0.2;

% Value of minimal difference of inner fields orientation (in degrees). If there are fields
% that differ in orientation for less than this value, then only the closest to the centre field are left.
% Default value is 15. See also analyses.gridnessScore
p.gridnessMinOrientation = 15;

% Number of iterations to do in the shuffling analysis. The shuffling is
% done to calculate expected values.
p.numShuffleIterations = 500;

% Shuffling is performed by making a circular shift of spikes timestamps starting from a random point.
% Circular shift happens on top of position data. p.shuffleCircOffset defines a valid interval for
% a starting point of the shift. If N is the time of last position sample and p.shuffleCircOffset == 20,
% then a starting point will be a random number in interval [20 N-20]. Default value is 20.
p.shuffleCircOffset = 20; % [sec]

% Table that defines what values to shuffle.
% Each line consists of 3 items:
%   <entry name>        name of the shuffling entry which is used internally in the scripts. Do not change!
%   <description>       Description string (column name) that will be in the resulting Excel file.
%                       Could be changed, but not recommended.
%   <shuffle flag>      TRUE or FALSE. If TRUE then shuffling of this variable will be performed.
%                       Change to your needs.
% By default all shuffling is set to FALSE.
p.shuffleTable = {...
    'doGridnessScore', 'Gridness score', false; ...
    'doInformationContent', 'Information content [bits/spike]', false; ...
    'doBorderScore', 'Border score', false; ...
    'doHeadDirection', 'Head direction (mean vector length)', false; ...
    'doSpeedScore', 'Speed score', false; ...
    'doCoherence', 'Coherence (unsmoothed map)', false; ...
    };

% List of percentile values that should be calculated on shuffled data.
% Default value [95 99].
p.shufflePercentiles = [95 99];

% Flag that specifies whether to use dual criterion (<one variable> + information content)
% on gridness score and border score distribution. Possible values: false or true.
% Default is false.
p.shuffleGridnessDualCriterion = false;

% This parameter controls how rectangular rate maps are plotted. Rectangular rate maps have one
% side shorter than the other side. If p.plotMapsSquare is set to true, then the map will be extended
% to a square (based on the value of maximum side). Otherwise maps are plotted as is.
% Default value is false.
p.plotMapsSquare = false;

% For analysis that uses EEG specifies what kind of EEG file to use. For example, Axona
% outputs two files one with 250 Hz sampling, and another one with 4800 Hz. p.eegFs parameter
% is used to select one of the file. You have two options:
% 1. set eegFs to a desired Fs value in Hz. Example, p.eegFs = 300. Then, the closest match will be selected.
% 2. set eegFs to a string 'best', then the eeg file with highest sampling will be used.
% Default value is 'best'.
p.eegFs = 'best';

% Argument for analyses.movingDirection function, [n1 n2].
% The moving direction for current sample is calculated using the mean value of it's neighbours.
% mdwindowPoints specifies how many points will be taken before the current sample (n1) and
% how many after (n2). Default value is [1 1], which means that the moving direction for
% sample i is determined by samples i-1 and i+1. Note that [1 1] gives you a histogram with
% very sharp bins at [0 90 180 270] degrees.
p.mdWindowPoints = [1 1];

% Argument for analyses.movingDirection function.
% Moving direction can be calculated not for every position sample, but for every 'mdStep' sample.
% Default is 1.
p.mdStep = 1;

% Width of a bin for speed data binning.
p.speedBinWidth = 5; % [cm/s]

% Limits of values for speed data binning. This parameter is used along with p.speedBinWidth.
% For example, if p.speedBinLimits = [0 50] and p.speedBinWidth = 2, then
% the data is binned on range from 0 to 50 cm/s in 2 cm/s bins.
% If value [0] is provided, then the limits is extracted from the data (min and max values).
p.speedBinLimits = [0 50]; % [cm/s]

% This parameter is used during speed rate map calculation. Minimum time an animal
% must spend in a bin, in order to include this bin in the resulting speed map.
% In other words if an animal has spent less than p.speedBinMinTime in a bin, the value
% of this bin is set to NaN. Default value is 10, meaning that only bins in which
% animal spent more than 10 seconds are included.
% Value of 0 means that all bins matter.
p.speedBinMinTime = 10; % [sec]

% Line height for plots that use vertical lines (e.g. spike density on a linear track).
% Could be any positive number, but practical value is somewhere between 0 and 1.
% For spike density plots, defines height of spike tick between two linear track runs.
% Default value is 0.2.
p.lineHeight = 0.2;

% Cell array of Lineseries Properties which are passed to Matlab's plot function
% when images with lines are create. See Matlab's help (search for Lineseries Properties)
% for a complete list of possible values.
% Spike density plots for linear track is one example where this parameter might be used.
% Default values are: blue color and line width of 1 points.
p.plotLineStyle = {'Color', [0 0 0.8], 'LineWidth', 1};

% Axis limits for speed plots. For example, in speed vs rate plot firing rate values lie
% along y-axis and speed values lie along x-axis. y-axis limits are [0 max(firingRate)+3].
% p.speedPlotLimits allows you to set fixed limit for x-axis. Default value ([]) uses autoscaling.
% Otherwise, you should provide both min and max value: p.speedPlotLimits = [min max].
p.speedPlotLimits = [];

% Experimental! Used during shuffling of gridness score. Number of expanding circles taken before
% and after the radius which corresponds to gridness score for real data. Seems
% that smaller values work better. At least one number must be > 0!
p.gridShuffleRadii = [1 1];

% Value of a minimum run duration in seconds. If provided, then runs that are
% shorter than this value, are discarded. Default value is 0, meaning all
% runs are stored.
p.runDetectionMinDuration = 0; % [sec]

% Value of a minimum run length in cm. If provided, then runs that
% are shorter than this value will be discarded.
% Default value is 0, meaning that all runs are kept.
p.runDetectionMinLength = 0; % [cm]

% Type of the value in p.runDetectionThreshold. Can be either '%' or 'direct'.
% '%' means that the p.runDetectionThreshold is given as percentage of track length.
% 'direct' means that p.runDetectionThreshold has the same units as your positions (normally cm),
% and it is the offset from track edges.
% See examples in description of p.runDetectionThreshold.
% Usage of 'direct' value might be helpfull if you have recordings on a linear track of different
% lengths and you always want to remove exact amount of cm from your tracks.
p.runDetectionThresholdType = '%';

% For example, if your linear track is 120 cm and p.runDetectionThreshold = 5
%   * p.runDetectionThresholdType is '%'. Runs will be detected in range 6..114 cm.
%   * p.runDetectionThresholdType is 'direct'. Runs will be detected in range 5..115 cm.
%
% It is possible to provide two values, for example p.runDetectionThreshold = [5 10];
% In this case, 5 is applied to the beginning of track and 10 is applied to the end of track.
% This allows you to have independent thresholds on different sides of the track.
% Since 'begin' and 'end' is somewhat relative, this means that begin is either the side
% that is closer to 0 or the one with minimum value along X-axis.
% Default value is 5.
p.runDetectionThreshold = 5; % unit depends on p.runDetectionThresholdType!

% One or several thresholds to separate grids in different modules based on their spacing.
% It's primary purpose is to colour-code dots on plot that shows distribution of grid spacing
% and distance. If 0, then no colour-coding is used.
% If for example p.spacingModuleThresholds = [10], then all dots that have spacing 0-10 cm will
% have identical colour. Other dots (10+) will have a different colour.
% If p.spacingModuleThresholds = [10 20], then three colours will be used. One for 0-10 spacing,
% another for 10-20, and another one for 20+.
p.spacingModuleThresholds = [0]; % [cm]

% This parameter is used during analysis of prospective firing of speed cells.
% It defines the minimum and maximum offset for spikes. Spikes are shifted
% backwards and forward. For each shift a correlation between firing rate
% and speed is calculated.
% Default value is [-400 400].
p.speedProspectiveLimit_ms = [-400 400];

% This parameter is linked to p.speedProspectiveLimit_ms. It defines
% the step size for spike shift. Spikes are shifted by values defined by vector:
% p.speedProspectiveLimit_ms(1):p.speedProspectiveBinWidth_ms:p.speedProspectiveLimit_ms(2)
% Default value is 20.
p.speedProspectiveBinWidth_ms = 20;

% Controls the colour-scaling of a speed map plot. You can use this parameter if you want to
% plot several speed maps with the same colour scale.
%
% Format is p.speedMapScalling = [lower_end higher_end], where both values are given in cm/s.
% When empty ([]) or NaN, then the plot is autoscaled: the lowest value of
% the map is represented by dark blue and the highest value of the map is represented by brown.
% Otherwise everything which is below or equal 'lower_end' value is represented by dark blue,
% and 'higher_end' is represented by brown. It's possible to set only one value to NaN:
% p.speedMapScalling = [NaN 15] will scale from the minimum value of the map up to 15 Hz.
% Default is p.speedMapScalling = [];, which means autoscale is used.
p.speedMapScalling = []; % cm/s

% Width of the Gaussian smoothing kernel applied to during calculation of speed score(s).
% Smoothing of instantaneous firing rate is affected by this value.
% Default value is 400 ms.
p.speedSmoothing_sec = 0.4;

% Defines filter that is applied to position data. Possible values are:
% 'off' - no filtering is done
% 'mean' - median filter by Matlab function medfilt1. Default order is 15.
% Default is 'mean'.
p.posFilter = 'mean';

% Defines minimum duration of a trial in seconds. Trials that are shorter than the value
% specified, will be excluded from the analysis (for scripts that support this).
% For example, if p.trialMinDuration = 120; Then all trials shorter or equal to 2 minutes (120 sec),
% will not be analysed.
% Default value is 0, which means that all trials are processed.
p.trialMinDuration = 0; % [sec]

% The passband and stop band for theta signal in Hz. These values will be used
% to filter LFP signal in order to obtain theta.
p.thetaFrequency = [6 10]; % Hz