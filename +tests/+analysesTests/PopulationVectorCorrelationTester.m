classdef PopulationVectorCorrelationTester < tests.TestCaseWithData
    methods
        function this = PopulationVectorCorrelationTester()
            this.copyRecordings = false;
        end
    end

    methods(Test)
        function testDefaults(testCase)
            % stackA, stackB, description variables
            dataFile = fullfile(testCase.DataFolder, 'circle_261.mat');
            load(dataFile);
            
            pvCorr = analyses.populationVectorCorrelation(stackA, stackB);
            testCase.verifyEqual(size(pvCorr), [30 30]);

            pvCorr = analyses.populationVectorCorrelation(stackA, stackB, 'rows', 'all');
            numZeros = length(find(pvCorr(:) == 0));
            testCase.verifyTrue(numZeros > 150); % 150 is an arbitary number
        end
        
        function testDefaults1DMaps(testCase)
            % stackA, stackB, description variables
            dataFile = fullfile(testCase.DataFolder, 'linear_different.mat');
            load(dataFile);
            
            expLength = min([size(stackA, 2) size(stackB, 2)]);
            
            pvCorr = analyses.populationVectorCorrelation(stackA, stackB);
            testCase.verifyEqual(size(pvCorr), [1 expLength]);
        end

        function testPairwise(testCase)
            % stackA, stackB, description variables
            dataFile = fullfile(testCase.DataFolder, 'circle_261.mat');
            load(dataFile);

            pvCorr = analyses.populationVectorCorrelation(stackA, stackB, 'rows', 'pairwise');
            numZeros = length(find(pvCorr(:) == 0));
            testCase.verifyTrue(numZeros < 150); % 150 is an arbitary number

            pvCorr = analyses.populationVectorCorrelation(stackA, stackB, 'rows', 'all');
            numZeros = length(find(pvCorr(:) == 0));
            testCase.verifyTrue(numZeros > 150); % 150 is an arbitary number
        end
        
        function testDifferentCells(testCase)
            % stackA, stackB, description variables
            dataFile = fullfile(testCase.DataFolder, 'circle_261.mat');
            load(dataFile);

            testCase.verifyWarning(@() analyses.populationVectorCorrelation(stackA, stackB(:, :, 1:50)), 'BNT:stackSize'); %#ok<NODEF>
        end
        
        function testDifferentCellsResults(testCase)
            % stackA, stackB, description variables
            dataFile = fullfile(testCase.DataFolder, 'circle_261.mat');
            load(dataFile);

            warning('off', 'BNT:stackSize');
            pvCorr = analyses.populationVectorCorrelation(stackA, stackB(:, :, 1:50), 'rows', 'pairwise'); %#ok<NODEF>
            warning('on', 'BNT:stackSize');
            numZeros = length(find(pvCorr(:) == 0));
            testCase.verifyTrue(numZeros < 150); % 150 is an arbitary number
        end
    end
end