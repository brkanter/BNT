% Tests for analyses.coherence function
classdef CoherenceTester < tests.TestCaseWithData
    methods
        function this = CoherenceTester()
            this.copyRecordings = false;
        end
    end
    
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.coherence(), 'MATLAB:minrhs');
        end

        function emptyArgument(testCase)
            testCase.verifyError(@()analyses.coherence([]), ?MException);
        end

        function smallMap(testCase)
            map = [1 2 3];
            z = analyses.coherence(map);
            testCase.verifyEqual(z, 0);
        end

        function mapSinglevalue(testCase)
            map = [3];
            z = analyses.coherence(map);
            testCase.verifyEqual(z, nan);
        end

        function zeros(testCase)
            map = ones(10) * 0;
            exp = NaN;

            z = analyses.coherence(map);
            testCase.verifyEqual(z, exp);
        end

        function nans(testCase)
            map = nan(10);
            exp = NaN;

            z = analyses.coherence(map);
            testCase.verifyEqual(z, exp);
        end

        function perfectGrid(testCase)
            points = helpers.hexGrid([0 0 50 50], 15);
            map = helpers.gauss2d(points, 5*ones(size(points, 1), 1), [50 50]);
            exp = 2.2424;

            z = roundn(analyses.coherence(map), -4);
            testCase.verifyEqual(z, exp);
        end

        function perfectGridUnsmoothed(testCase)
            points = helpers.hexGrid([0 0 50 50], 15);
            
            invInd = points(:, 2) > 50 | points(:, 1) > 50 | isnan(points(:, 1)) | isnan(points(:, 2));
            points(invInd, :) = [];
            
            points = round(points);
            zerInd = points(:, 1) == 0;
            points(zerInd, 1) = 1;
            zerInd = points(:, 2) == 0;
            points(zerInd, 2) = 1;
            
            map = zeros(50);
            linInd = sub2ind([50 50], points(:, 2), points(:, 1));
            map(linInd) = 1;            
            
            exp = -0.0140;

            z = roundn(analyses.coherence(map), -4);
            testCase.verifyEqual(z, exp);
        end

        function realMap(testCase)
            dataFile = fullfile(testCase.DataFolder, 'aCorr.mat'); % aCorr and map variables
            load(dataFile);
            
            expV = 3.35;
            expV_raw = 0.545;
            
            z = roundn(analyses.coherence(map.z), -4);
            testCase.verifyEqual(z, expV);
            
            z_raw = roundn(analyses.coherence(map.zRaw), -4);
            testCase.verifyEqual(z_raw, expV_raw);
     end
    end
end