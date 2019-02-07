classdef BorderScoreCircularTester < tests.TestCaseWithData
    methods
        function this = BorderScoreCircularTester()
            this.copyRecordings = false;
        end
    end

    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.borderScoreCircular(), 'MATLAB:minrhs');
        end

        function nanMap(testCase)
            map = NaN(50, 360);
            [fieldsMap, fields] = analyses.placefield(map, 'threshold', 0.3, 'minBins', 2);

            score = analyses.borderScoreCircular(map, fieldsMap);
            testCase.verifyEqual(score, -1);
        end

        function noFields(testCase)
            map = zeros(50, 350);
            fieldsMap = zeros(50, 360);
            score = analyses.borderScoreCircular(map, fieldsMap);
            testCase.verifyEqual(score, -1);
        end

        function perfectScore(testCase)
            map = zeros(20, 360);
            map(end, :) = randi(5, 1, 360);
            fieldsMap = analyses.placefield(map, 'threshold', 0.2, ...
                'minBins', 0, 'binWidth', 2.5, 'minPeak', 0);

            score = analyses.borderScoreCircular(map, fieldsMap);
            testCase.verifyEqual(score, 1, 'AbsTol', 0.005);
        end

        function oneFieldWholeWall(testCase)
            mapFile = fullfile(testCase.DataFolder, 'one_field.mat');
            load(mapFile); % mapPolar variable

            fieldsMap = analyses.placefield(mapPolar, 'threshold', 0.2, ...
                'minBins', 9, 'binWidth', 2.5, 'minPeak', 1);

            score = analyses.borderScoreCircular(mapPolar, fieldsMap);
            testCase.verifyEqual(score, 0.14994338, 'AbsTol', 0.0005);
        end

        function oneFieldSpecificWall(testCase)
            mapFile = fullfile(testCase.DataFolder, 'one_field.mat');
            load(mapFile); % mapPolar variable

            fieldsMap = analyses.placefield(mapPolar, 'threshold', 0.2, ...
                'minBins', 9, 'binWidth', 2.5, 'minPeak', 1);

            score = analyses.borderScoreCircular(mapPolar, fieldsMap, 'walls', [260 360]);
            testCase.verifyEqual(score, 1, 'AbsTol', 0.005);
        end
    end
end