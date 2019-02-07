classdef GroupSpikesTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()general.groupPositions(), 'BNT:numArgs');
        end

        function emptyArguments(testCase)
            spkIndices = general.groupSpikes([], [])
            testCase.verifyEqual(spkIndices, []);
        end

        function normalGrouping(testCase)
            t = 0:0.02:60.04; t = t';
            x = rand(1, length(t))';
            y = rand(1, length(t))';
            spikes = randsample(t, round(length(t)/3));
            spikes = sort(spikes);

            expNumGroups = 2;

            [~, edges] = general.groupPositions([t, x, y], 'num', expNumGroups);
            grpSpikes = general.groupSpikes(spikes, edges);

            numGroups = length(unique(grpSpikes));

            testCase.verifyEqual(size(grpSpikes), size(spikes));
            testCase.verifyEqual(numGroups, expNumGroups);
        end
        
        function noSpikesGroup2(testCase)
            t = 0:0.02:60.04; t = t';
            x = rand(1, length(t))';
            y = rand(1, length(t))';
            spikes = randsample(t, round(length(t)/3));
            spikes = sort(spikes);
            spikes(spikes >= (max(t)/2)) = [];

            expNumGroups = 2;

            [~, edges] = general.groupPositions([t, x, y], 'num', expNumGroups);
            grpSpikes = general.groupSpikes(spikes, edges);

            numGroups = length(unique(grpSpikes));

            testCase.verifyEqual(size(grpSpikes), size(spikes));
            testCase.verifyEqual(numGroups, 1);
        end

        function spikeBeforePosition(testCase)
            t = 0:0.02:60.04; t = 2 + t';
            x = rand(1, length(t))';
            y = rand(1, length(t))';
            spikes = randsample(t, round(length(t)/3));
            spikes(end+1) = 0.235;
            spikes = sort(spikes);

            expNumGroups = 2;

            [~, edges] = general.groupPositions([t, x, y], 'num', expNumGroups);
            grpSpikes = general.groupSpikes(spikes, edges);

            numGroups = length(unique(grpSpikes));

            testCase.verifyEqual(size(grpSpikes), size(spikes));
            testCase.verifyEqual(numGroups, expNumGroups+1);
        end
    end
end