classdef FindRunsByThresholdTester < tests.TestCaseWithData
    methods
        function this = FindRunsByThresholdTester()
            this.copyRecordings = false;
        end
    end

    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.findRunsByThreshold(), 'MATLAB:minrhs');
        end
        
        function emptyPos(testCase)
            testCase.verifyError(@()analyses.findRunsByThreshold([], [0 0]), 'MATLAB:InputParser:ArgumentFailedValidation');
        end
        
        function strangeData(testCase)
            pos = [0 1 0];
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, [0 0]);
            
            testCase.verifyEqual(max(leftIndices), 0);
            testCase.verifyEqual(max(rightIndices), 0);
        end
        
        function numRunsStartInIllegalZone(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track1800cm_6runs.mat'); % pos variable
            load(dataFile);            
            thLevel = general.runThreshold(1800, '%', 5) - 1800/2;
            
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevel);
            numLeftRuns = max(leftIndices);
            numRightIndices = max(rightIndices);
            
            testCase.verifyEqual(numLeftRuns, 3);
            testCase.verifyEqual(numRightIndices, 3);
        end
        
        function numRuns(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track1800cm_10runs.mat'); % pos variable
            load(dataFile);
            thLevel = general.runThreshold(1800, '%', 5) - 1800/2;
            
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevel);
            numLeftRuns = max(leftIndices);
            numRightIndices = max(rightIndices);
            
            testCase.verifyEqual(numLeftRuns, 5);
            testCase.verifyEqual(numRightIndices, 5);
        end
        
        function noIllegalSamples(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_runs_illegalZones.mat'); % pos variable
            load(dataFile);
            
            threshold = 5;
            trackLength = 200;
            thLevel = general.runThreshold(trackLength, '%', threshold) - trackLength/2;
            
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevel);
            numLeftRuns = max(leftIndices);
            numRightIndices = max(rightIndices);
            
            testCase.verifyEqual(numLeftRuns, 12);
            testCase.verifyEqual(numRightIndices, 12);
            
            leftPos = pos;
            leftPos(leftIndices == 0, 2:end) = nan;
            rightPos = pos;
            rightPos(rightIndices == 0, 2:end) = nan;
            testCase.verifyTrue(~(any(leftPos(:, 2) < thLevel(1)) | any(leftPos(:, 2) > thLevel(2))));
            testCase.verifyTrue(~(any(rightPos(:, 2) < thLevel(1)) | any(rightPos(:, 2) > thLevel(2))));
        end
        
        function teleportation(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_teleportation.mat'); % pos variable
            load(dataFile);
            thLevels = general.runThreshold(200, '%', 5) - 200/2;

            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevels);
            numLeftRuns = max(leftIndices);
            numRightIndices = max(rightIndices);
            
            testCase.verifyEqual(numLeftRuns, 0);
            testCase.verifyEqual(numRightIndices, 10);
        end
        
        function minSamples(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_runs_illegalZones.mat'); % pos variable
            load(dataFile);
            threshold = 5;
            trackLength = 200;
            thLevel = general.runThreshold(trackLength, '%', threshold) - trackLength/2;
            
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevel, 'minSamples', 4000);
            testCase.verifyEqual(max(leftIndices), 1);
            testCase.verifyEqual(max(rightIndices), 3);
        end
        
        function negativeMinSamples(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_runs_illegalZones.mat'); % pos variable
            load(dataFile);
            threshold = 5;
            trackLength = 200;
            thLevel = general.runThreshold(trackLength, '%', threshold) - trackLength/2;
            
            testCase.verifyError(@()analyses.findRunsByThreshold(pos, thLevel, 'minSamples', -100), 'MATLAB:InputParser:ArgumentFailedValidation');
        end
        
        function largeMinSamples(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_runs_illegalZones.mat'); % pos variable
            load(dataFile);
            threshold = 5;
            trackLength = 200;
            thLevel = general.runThreshold(trackLength, '%', threshold) - trackLength/2;
            
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevel, 'minSamples', 100000);
            testCase.verifyTrue(max(leftIndices) == 0);
            testCase.verifyTrue(max(rightIndices) == 0);
        end
        
        function minLength(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_runs_illegalZones.mat'); % pos variable
            load(dataFile);
            threshold = 5;
            trackLength = 200;
            thLevel = general.runThreshold(trackLength, '%', threshold) - trackLength/2;
            
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevel, 'minLength', 179.5);
            testCase.verifyEqual(max(leftIndices), 9);
            testCase.verifyEqual(max(rightIndices), 6);
        end
        
        function negativeMinLength(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_runs_illegalZones.mat'); % pos variable
            load(dataFile);
            threshold = 5;
            trackLength = 200;
            thLevel = general.runThreshold(trackLength, '%', threshold) - trackLength/2;
            
            testCase.verifyError(@()analyses.findRunsByThreshold(pos, thLevel, 'minLength', -100), 'MATLAB:InputParser:ArgumentFailedValidation');
        end
        
        function largeMinLength(testCase)
            dataFile = fullfile(testCase.DataFolder, 'track200cm_runs_illegalZones.mat'); % pos variable
            load(dataFile);
            threshold = 5;
            trackLength = 200;
            thLevel = general.runThreshold(trackLength, '%', threshold) - trackLength/2;
            
            [leftIndices, rightIndices] = analyses.findRunsByThreshold(pos, thLevel, 'minLength', 100000);
            testCase.verifyTrue(max(leftIndices) == 0);
            testCase.verifyTrue(max(rightIndices) == 0);
        end
    end
end