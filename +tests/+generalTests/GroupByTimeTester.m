classdef GroupByTimeTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()general.groupByTime(), 'BNT:numArgs');
        end

        function emptyArguments(testCase)
            testCase.verifyError(@()general.groupByTime([], []), ?MException);
        end

        function testHalf(testCase)
            t = [0 5 10]';
            x = rand(1, 3)';
            y = rand(1, 3)';

            [groupIndices, edges] = general.groupByTime([t, x, y], 'half');

            testCase.verifyEqual(size(edges), [1 3]);
            testCase.verifyEqual(edges, [0 5 Inf]);
            testCase.verifyEqual(size(groupIndices, 2), 1); % single column
            testCase.verifyEqual(groupIndices, [1 2 2]');
        end

        function simpleDuration(testCase)
            t = [0 5 10]';
            x = rand(1, 3)';
            y = rand(1, 3)';

            [groupIndices, edges] = general.groupByTime([t, x, y], 1);
            expEdges = [0 1 2 3 4 5 6 7 8 9 10 Inf];

            testCase.verifyEqual(size(groupIndices, 2), 1); % single column
            testCase.verifyEqual(groupIndices, [1 6 11]');

            testCase.verifyEqual(edges, expEdges);
        end
    end
end