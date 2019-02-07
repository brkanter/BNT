# Change log
All notable changes to BNT will be documented in this file.

## [Current version]

## [1.0] - 2018-09-04

### Added

 - New function for place field detection. It is based on adaptive algorithm.
 No user-specified threshold is used.

### Changed

 - Modifications to gridness score calculation. Changed the way centre field
 is detected. New algorithm doesn't use threshold, but relies on an adaptive
 place field detection.

## [0.7] - 2017-12-12

### Added
 - Possibility to create manually altered version of cache positions (cleaned positions) file. Such files won't be automatically deleted by BNT. In case BNT would like to delete them, a backup will be created.
 - New *general* input file format, version 0.4.

## [0.6] - 2017-05-16

### Changed
 - Position samples are filtered per session. This is important for combined sessions, since there might be a jump between two sessions. Such jump is not very important if we create a rate map, but is more crucial if we calculate speed.
 - Speed is smoothed by default.
 - Speed of loading Axona spikes and positions is greatly improved (~400 times). The maximum improvement can be achieved when data is loaded from a local storage. Network loading brings delays.
 - Check if any of NeuraLynx tracking timestamps are out of order and try to fix them. The timestamps should be in increasing order. However, sometimes they are not. The corresponding data should be fine it is just the timestamps that are wrong. If this is the case, then bad timestamps are replaced with an average of their neighbours.

### Added
 - Option to select lowess filter for position data. See Matlab's smooth function for details.
 - Support for loading EEG/LFP data. This is done through a new keyword in general input file for specifying EEG/LFP channels to use.
 - Code to calculate border score for data recorded in circular environments.

### Fixed
 - Loading of Axona data files is now much much faster. Especially if data is on local disc. Loading from a network location is faster, but 10x slower than from a local disc.

## [0.5] - 2016-08-05
### Changed
 - **Compatibility break**. Change format of function analyses.findRunsByThreshold. It doesn't calculate threshold levels by itself any more. Threshold levels should be provided by calling function. The function outputs runs as subregions of position data.
 - Changed the way how 2 LEDs position data is scaled. First, LED which covers the biggest area is selected. Then a scale factor (in X and Y dimensions) is calculated and applied to both LEDs. Positions are centred based on data of LED with the biggest coverage.
 - analyses.map function is now more general and can be used to produce not only spike rate maps, but also, for example, speed rate maps. This is a map that shows average speed of the animal in each bin.
 - More flexible way of extracting animal name from folder structure. It is controlled through parameter p.animalNameLevel.
 - Introduced integrity check of cut files during loading. During first load, raw data is saved in Matlab format in order to speed up it's reading later. It might be that unit spikes are recut between data loads and the original cut file is overwritten with new information. The toolbox is now able to detect these situations and to reload cut file if needed.

### Added
 - Save images in multiple formats simultaneously.
 - Version 0.3 of 'linear track tale' input files.
 - Option to select kind of filter which is applied to positions. Right now it only allows to turn filtering off.
 - Kalman filter routines for speed scores.

## [0.4] - 2015-11-03
### Changed
 - Clarified things with calculation of information rate and content. The information is now calculated solely from the output of function analyses.map. This results in change of input arguments of function analyses.mapStatsPDF.
 - Changed the output of analyses.map function. Returned occupancy and spike count maps are smoothed by default (if smooth factor is provided). Raw data is returned in addition.
 - Shuffling of grid scores. A different algorithm is used which depends a lot on data from non-shuffle step. This is still work in progress and can be changed in the future.

### Added
 - Support of Virmen virtual reality for linear track recordings alongside of Axona system.

### Fixed
 - Fixed functions dealing with cache and input files (creation, deletion, multiple tetrodes without cut information, base name for combined sessions).

## [0.3] - 2015-09-02
### Changed
 - Changed the way analyses.tcStatistics function is called. It is now more suited for parallel processing.

### Added
 - Added support for .t32 and .t64 MClust cut files.
 - Added a new function to fix tracked position to LEDs assignment. This function could be used when tracking is very bad in Axona.

### Fixed
 - Fixed various bugs related to cut file autodetection; usage of calibration data; update process; e.t.c. See Git log for all the details.

### Removed
 - analyses.tcMeanVectorLength.


## [0.2] - 2015-04-21
### Added
 - Added version 0.2 for general input file. Details are here [https://www.ntnu.no/wiki/display/kavli/Input+file+formats](https://www.ntnu.no/wiki/display/kavli/Input+file+formats). This version allows to provide camera calibration data in input file.

### Fixed
 - Fixed various bugs related to Git usage and auto-update process.


## [0.1] - 2015-04-13
### Added
 - Initial release