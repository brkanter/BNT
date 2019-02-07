classdef LoadParametersTester < tests.TestCaseWithData

    methods
        function this = LoadParametersTester()
            this.copyRecordings = false;            
        end
    end
    
    methods (Test)
        function noArguments(testCase)
            testCase.verifyError(@()data.loadParameters(), 'MATLAB:minrhs');
        end

        function emptyArguments(testCase)
            testCase.verifyError(@()data.loadParameters([]), ?MException);
        end

        function wrongFile(testCase)
            bntRoot = helpers.bntRoot();
            wrongFile = fullfile(bntRoot, '+plot', 'lines.m');
            testCase.verifyError(@()data.loadParameters(wrongFile), ?MException);
        end

        function loading(testCase)
            p = io.readParamFile(fullfile(testCase.DataFolder, 'bntSettings.m'));
            expectedP.percentile = 50;
            expectedP.hdMapLineWidth = 1;
            expectedP.hdBinWidth = 3;
            expectedP.hdTimeBinWidth = 6;
            expectedP.hdSmooth = 1;
            expectedP.imageFormat = 'png';

            testCase.verifyEqual(p, expectedP);
        end

        function userParamsAreDifferent(testCase)
            userParams.percentile = 60;
            userParams.someOther = 10;
            userParams.hdBinWidth = 15;

            bntParams = struct('percentile', 50, ...
                'hdMapLineWidth', 1, ...
                'imageFormat', 'png', ...
                'hdSmooth', 1 ...
                );

            expectedP = struct('percentile', 60, ...
                'someOther', 10, ...
                'hdBinWidth', 15, ...
                'hdMapLineWidth', 1, ...
                'imageFormat', 'png', ...
                'hdSmooth', 1 ...
                );
            testCase.verifyWarning(@()helpers.checkParameters(userParams, bntParams), 'BNT:paramsDiff');

            warning('off', 'BNT:paramsDiff');
            actual = helpers.checkParameters(userParams, bntParams);
            warning('on', 'BNT:paramsDiff');

            testCase.verifyEqual(actual, expectedP);
        end
        
        function additionalParam(testCase)
            paramFile = fullfile(testCase.DataFolder, 'moreValuesThaninBNT.m');
            testCase.verifyWarning(@()data.loadParameters(paramFile), 'BNT:paramsDiff');
            expMsg = sprintf('Your parameters file has some values, which are no longer in use. Here is the list of these values:\nadditionalParameter\n');
            warningMsg = lastwarn;

            truncId = strfind(warningMsg, 'Check file ');
            testCase.assumeNotEmpty(truncId);
            if ~isempty(truncId)
                warningMsg(truncId:end) = [];
                testCase.verifyEqual(warningMsg, expMsg);
            end
        end
        
        function sameNumberButDifferent(testCase)
            paramFile = fullfile(testCase.DataFolder, 'sameNumberButDifferent.m');
            testCase.verifyWarning(@()data.loadParameters(paramFile), 'BNT:paramsDiff');
            expMsg = sprintf('Your parameters file has some values, which are no longer in use. Here is the list of these values:\nadditionalParameter\n');
            warningMsg = lastwarn;

            truncId = strfind(warningMsg, 'Check file ');
            testCase.assumeNotEmpty(truncId);
            if ~isempty(truncId)
                warningMsg(truncId:end) = [];
                testCase.verifyEqual(warningMsg, expMsg);
            end
        end
    end
end
