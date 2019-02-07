classdef MeanRateTester < tests.TestCaseWithData
    methods
        function this = MeanRateTester()
            this.copyRecordings = false;
        end
    end

    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.meanRate(), 'MATLAB:minrhs');
        end

        function emptyArguments(testCase)
            rate = analyses.meanRate([], []);
            testCase.verifyEqual(rate, 0);
        end

        function values(testCase)
            spikes = [1 2 3];
            pos = ones(15, 3);
            pos(:, 1) = 0:0.02:(0.02*14);
            duration = 0.02 * 15;
            exp = 3/duration;

            rate = analyses.meanRate(spikes, pos);
            testCase.verifyEqual(round(rate), round(exp));
        end

        function nonUniformSamplingTime(testCase)
            posFile = fullfile(testCase.DataFolder, 'neuralynx_pos.mat'); % contains variable pos
            load(posFile);
            load(fullfile(testCase.DataFolder, 'neuralynx_random_spikes.mat'));

            rate = analyses.meanRate(spikes, pos);
            testCase.verifyEqual(roundn(rate, -4), 1.1400);
        end

        function testAxona(testCase)
            posFile = fullfile(testCase.DataFolder, 'axona_pos.mat'); % contains variable pos
            load(posFile);

            rate = analyses.meanRate(ones(1000, 1), pos);
            testCase.verifyEqual(roundn(rate, -4), 0.8319);
        end
        
        function combinedSessions(testCase)
            % this also tests for large gaps in position time
            pos = ones(15, 3);
            pos(:, 1) = 0:0.02:(0.02*14);
            pos2 = ones(150, 3);
            pos2(:, 1) = 0:0.02:(0.02*149);
            pos2(:, 1) = pos2(:, 1) + 350;
            
            posCombined = cat(1, pos, pos2);
            spikes = ones(21, 1); % arbitrary number
            expected = roundn(length(spikes) / ((15+150) * 0.02), -4);
            
            rate = analyses.meanRate(spikes, posCombined);
            testCase.verifyEqual(roundn(rate, -4), expected);
            
            % now verify that if time is continuous, then the result is the same
            pos2(:, 1) = pos2(:, 1) - 350;
            pos2(:, 1) = pos2(:, 1) + (0.02 * 15); % start right after pos
            posCombined = cat(1, pos, pos2);
            rate = analyses.meanRate(spikes, posCombined);
            testCase.verifyEqual(roundn(rate, -4), expected);
        end
        
        function sessionWithNansInPositions(testCase)
            posFile = fullfile(testCase.DataFolder, 'neuralynx_pos.mat'); % contains variable pos
            load(posFile);

            spikeInd = sort([18388 2696 10716 1151 13208 9011 15431 7749 544 12051 10714 11560 8577 1655 6293]);
            spikes = pos(spikeInd, 1);
            pos(5000:18000, 2:end) = nan;
            rate = analyses.meanRate(spikes, pos);
            testCase.verifyEqual(roundn(rate, -4), 0.0140);

            newPos = ones(size(pos));
            newPos(:, 1) = 0:0.02:(0.02*(size(pos, 1)-1));
            rate = analyses.meanRate(spikes, newPos);
            expected = roundn(length(spikes) / (size(newPos, 1) * 0.02), -4);
            testCase.verifyEqual(roundn(rate, -4), expected);
        end
        
    end
end