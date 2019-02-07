classdef BorderScoreTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.borderScore(), 'MATLAB:minrhs');
        end

        function nanMap(testCase)
            map = NaN(50);
            [fieldsMap, fields] = analyses.placefield(map, 'threshold', 0.3, 'minBins', 2);

            score = analyses.borderScore(map, fieldsMap, fields);

            testCase.verifyEqual(score, -1);
        end

        function perfectScore(testCase)
            map = zeros(50);
            map(1, :) = 1 / 2;

            [fieldsMap, fields] = analyses.placefield(map, 'threshold', 0.3, 'minBins', 1, 'minPeak', 0.1);

            score = analyses.borderScore(map, fieldsMap, fields);
            score = round(score * 100);

            testCase.verifyEqual(score, 92);
        end
    end
end