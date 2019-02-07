classdef GridnessScoreTester < tests.TestCaseWithData
    methods
        function this = GridnessScoreTester()
            this.copyRecordings = false;
        end
    end
    
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.gridnessScore(), 'MATLAB:minrhs');
        end

        function nanMap(testCase)
            map = NaN(50);
            gscore = analyses.gridnessScore(map);

            testCase.verifyEqual(gscore, nan);
        end

        function zeroMap(testCase)
            map = zeros(50);
            gscore = analyses.gridnessScore(map);

            testCase.verifyEqual(gscore, nan);
        end

        function image(testCase)
            % Image from a Matlab bundle
            I = double(rgb2gray(imread('fabric.png')));
            gscore = analyses.gridnessScore(I);

            testCase.verifyEqual(gscore, nan);
        end

        function perfectScore(testCase)
            points = helpers.hexGrid([0 0 50 50], 15);
            rmap = helpers.gauss2d(points, 5*ones(size(points, 1), 1), [50 50]);
            aCorr = analyses.autocorrelation(rmap);

            gscore = analyses.gridnessScore(aCorr);
            gscore = round(gscore * 1000) / 1000;

            testCase.verifyEqual(gscore, 1.382);
        end

        function threeFieldsMap(testCase)
            sigma = [8 4 3];
            mu = [14 11; 5 18; 12 21];
            rmap = helpers.gauss2d(mu, sigma', [25 25]);
            aCorr = analyses.autocorrelation(rmap);

            gscore = analyses.gridnessScore(aCorr);
            gscore = round(gscore * 10000) / 10000;

            testCase.verifyEqual(gscore, -0.2114);
        end

        function rectangularMap(testCase)
            sigma = [8 2]';
            mu = [11 25; 4 5];
            rmap = helpers.gauss2d(mu, sigma, [50 25]);
            aCorr = analyses.autocorrelation(rmap);

            gscore = analyses.gridnessScore(aCorr);
            gscore1 = round(gscore * 10000) / 10000;
            testCase.verifyEqual(gscore1, -0.0064);

            gscore = analyses.gridnessScore(aCorr');
            gscore2 = round(gscore * 10000) / 10000;
            testCase.verifyEqual(gscore2, -0.0064);
            testCase.verifyLessThan(abs(gscore1 - gscore2), 0.05);
        end
        
        function testRealMaps(testCase)
            dataFile = fullfile(testCase.DataFolder, 'mouse_grids.mat');
            aCorrs = {};
            load(dataFile, 'aCorrs');
            expectedScores = [0.866, 1.1865, 1.2478, 1.1408, 0.9295, 1.389, 1.0397];
            
            for i = 1:length(aCorrs)
                aCorr = aCorrs{i}; 
                gs = analyses.gridnessScore(aCorr);
                %testCase.verifyLessThan(abs(gs - expectedScores(i)), 0.001);
                testCase.verifyEqual(gs, expectedScores(i), 'abstol', 0.001);
            end
        end
    end
end