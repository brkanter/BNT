classdef GroupPositionsTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()general.groupPositions(), 'BNT:numArgs');
        end

        function emptyArguments(testCase)
            testCase.verifyError(@()general.groupPositions([], []), ?MException);
        end

        function testHalf(testCase)
            t = [0 5 10]';
            x = rand(1, length(t))';
            y = rand(1, length(t))';

            [groupIndices, edges] = general.groupPositions([t, x, y], 'num', 2);

            testCase.verifyEqual(size(edges), [1 3]);
            testCase.verifyEqual(edges, [0 5 Inf]);
            testCase.verifyEqual(size(groupIndices, 2), 1); % single column
            testCase.verifyEqual(groupIndices, [1 2 2]');
        end
        
        function testHalfNonZeroStart(testCase)
            t = 5 + [0 5 10]';
            x = rand(1, length(t))';
            y = rand(1, length(t))';

            [groupIndices, edges] = general.groupPositions([t, x, y], 'num', 2);

            testCase.verifyEqual(size(edges), [1 3]);
            testCase.verifyEqual(edges, 5 + [0 5 Inf]);
            testCase.verifyEqual(size(groupIndices, 2), 1); % single column
            testCase.verifyEqual(groupIndices, [1 2 2]');
        end

        function simpleDuration(testCase)
            t = [0 5 10]';
            x = rand(1, 3)';
            y = rand(1, 3)';

            [groupIndices, edges] = general.groupPositions([t, x, y], 'time', 1);
            expEdges = [0 1 2 3 4 5 6 7 8 9 10 Inf];

            testCase.verifyEqual(size(groupIndices, 2), 1); % single column
            testCase.verifyEqual(groupIndices, [1 6 11]');

            testCase.verifyEqual(edges, expEdges);
        end

        function testOddDuration(testCase)
            t = [0:0.02:300.02]'; % sampling of Axona system
            x = rand(1, length(t))';
            y = rand(1, length(t))';

            [grpPos, edges] = general.groupPositions([t, x, y], 'time', 67);
            numGroups = length(unique(grpPos));

            expNumGroups = 5;
            expEdges = [0 67 134 201 268 Inf];

            testCase.verifyEqual(numGroups, expNumGroups);
            testCase.verifyEqual(edges, expEdges);
        end

        function testOddDurationOffset(testCase)
            offset = 13;
            t = offset + [0:0.02:300.02]'; % sampling of Axona system
            x = rand(1, length(t))';
            y = rand(1, length(t))';

            [grpPos, edges] = general.groupPositions([t, x, y], 'time', 67);
            numGroups = length(unique(grpPos));

            expNumGroups = 5;
            expEdges =  offset + [0 67 134 201 268 Inf];

            testCase.verifyEqual(numGroups, expNumGroups);
            testCase.verifyEqual(edges, expEdges);
        end

        function testEvenDuration(testCase)
            t = [0:0.02:300.02]'; % sampling of Axona system
            x = rand(1, length(t))';
            y = rand(1, length(t))';

            [grpPos, edges] = general.groupPositions([t, x, y], 'time', 32);
            numGroups = length(unique(grpPos));

            expNumGroups = 10;
            expEdges = [0 32 64 96 128 160 192 224 256 288 Inf];

            testCase.verifyEqual(numGroups, expNumGroups);
            testCase.verifyEqual(edges, expEdges);
        end

        function testOddNum(testCase)
            t = [0:0.02:300.02]'; % sampling of Axona system
            x = rand(1, length(t))';
            y = rand(1, length(t))';
            expNumGroups = 5;

            [grpPos, edges] = general.groupPositions([t, x, y], 'num', expNumGroups);
            expEdges = 0:(300.02/expNumGroups):300.02;
            expEdges(end) = Inf;

            numGroups = length(unique(grpPos));

            testCase.verifyEqual(numGroups, expNumGroups);
            testCase.verifyEqual(edges, expEdges);
        end
    end
end