classdef DetectMClustCutsTester < tests.TestCaseWithData
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()io.detectMClustCuts(), 'MATLAB:minrhs');
        end
        
        function noUnit(testCase)
            sessionData = helpers.initTrial();
            sessionData.cuts = {};
            sessionData.units = [1 5];
            sessionData.system = bntConstants.RecSystem.Neuralynx;
            sessionData.path = fullfile(testCase.DataFolder, '24455', '2018-04-03_09-47-13');
            sessionData.sessions{1} = fullfile(testCase.DataFolder, '24455', '2018-04-03_09-47-13');
            sessionData.sessions{2} = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53');
            
            verifyError(testCase, @()io.detectMClustCuts(sessionData), 'BNT:noCutFile');
        end
        
        function noUnitOneSession(testCase)
            sessionData = helpers.initTrial();
            sessionData.cuts = {};
            sessionData.units = [1 7];
            sessionData.system = bntConstants.RecSystem.Neuralynx;
            sessionData.path = fullfile(testCase.DataFolder, '24455', '2018-04-03_09-47-13');
            sessionData.sessions{1} = fullfile(testCase.DataFolder, '24455', '2018-04-03_09-47-13');
            sessionData.sessions{2} = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53');
            
            sessionData_ret = io.detectMClustCuts(sessionData);
            testCase.verifyEmpty(sessionData_ret.units);
        end
        
        function cutsWithExtension(testCase)
            sessionData = helpers.initTrial();
            sessionData.cuts = {};
            sessionData.units = [1 3; 1 4];
            sessionData.system = bntConstants.RecSystem.Neuralynx;
            sessionData.path = fullfile(testCase.DataFolder, '24455', '2018-04-03_09-47-13');
            sessionData.sessions{1} = fullfile(testCase.DataFolder, '24455', '2018-04-03_09-47-13');
            sessionData.sessions{2} = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53');
            
            verifyWarningFree(testCase, @() io.detectMClustCuts(sessionData));
            
            sessionData_ret = io.detectMClustCuts(sessionData);
            testCase.verifyEqual(sessionData_ret.units, sessionData.units);
            
            for i = 1:size(sessionData.units, 1)
                cellLinearInd = helpers.tetrodeCellLinearIndex(sessionData.units(i, 1), sessionData.units(i, 2));
                testCase.verifyTrue(isfield(sessionData_ret, 'cutHash'));
                testCase.verifyTrue(any(cellfun(@(x) isequaln(x, cellLinearInd), sessionData_ret.cutHash.keys())));
            end
        end
        
        function simpleCase(testCase)
            sessionData = helpers.initTrial();
            sessionData.cuts = {};
            sessionData.units = [1 2];
            sessionData.system = bntConstants.RecSystem.Neuralynx;
            sessionData.path = fullfile(testCase.DataFolder, 'simpleCase');
            sessionData.sessions{1} = fullfile(testCase.DataFolder, 'simpleCase');
            
            verifyWarningFree(testCase, @() io.detectMClustCuts(sessionData));
            sessionData = io.detectMClustCuts(sessionData);
            testCase.verifyEqual(sessionData.units, [1 2]);
            testCase.verifyTrue(isfield(sessionData, 'cutHash'));
            testCase.verifyEqual(length(sessionData.cutHash.keys()), 1);
        end
        
        function cutPattern(testCase)
            sessionData = helpers.initTrial();
            sessionData.units = [1 1];
            sessionData.system = bntConstants.RecSystem.Neuralynx;
            sessionData.path = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53_1');
            sessionData.sessions{1} = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53_1');
            sessionData.cuts{1, 1} = 'TT%u_%02u';
            
            sessionData_ret = io.detectMClustCuts(sessionData);
            testCase.verifyEqual(sessionData_ret.units, sessionData.units);
            cellLinearInd = helpers.tetrodeCellLinearIndex(sessionData.units(1, 1), sessionData.units(1, 2));
            testCase.verifyTrue(any(cellfun(@(x) isequaln(x, cellLinearInd), sessionData_ret.cutHash.keys())));
        end
        
        function cutPatternInSubfolder(testCase)
            sessionData = helpers.initTrial();
            sessionData.units = [1 2];
            sessionData.system = bntConstants.RecSystem.Neuralynx;
            sessionData.path = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53_1');
            sessionData.sessions{1} = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53_1');
            sessionData.cuts{1, 1} = fullfile(testCase.DataFolder, '24455', '2018-04-04_08-51-53_1', 'sub', 'T%u_%03u');
            
            sessionData_ret = io.detectMClustCuts(sessionData);
            testCase.verifyEqual(sessionData_ret.units, sessionData.units);
            cellLinearInd = helpers.tetrodeCellLinearIndex(sessionData.units(1, 1), sessionData.units(1, 2));
            testCase.verifyTrue(any(cellfun(@(x) isequaln(x, cellLinearInd), sessionData_ret.cutHash.keys())));
        end
    end
end