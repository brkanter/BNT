classdef DetectRecordingSystemTester < tests.TestCaseWithData

    methods
        function this = DetectRecordingSystemTester()
            this.doCleanUp = true;
        end
    end

    methods(Test)
        function axonaSubFolder(testCase)
            sessionData = helpers.initTrial();
            sessionData.sessions{1} = fullfile(testCase.DataFolder, 'Rat_01_20573', '20150126', '20150126');
            sessionData = io.detectRecordingSystem(sessionData);
            
            testCase.verifyMatches(sessionData.system, bntConstants.RecSystem.Axona);
        end
        
        function axonaSimple(testCase)
            sessionData = helpers.initTrial();
            sessionData.sessions{1} = fullfile(testCase.DataFolder, 'Rat_01_20573', '20150124', '20150124');
            sessionData = io.detectRecordingSystem(sessionData);
            
            testCase.verifyMatches(sessionData.system, bntConstants.RecSystem.Axona);
        end
        
        function neuralynxSimple(testCase)
            sessionData = helpers.initTrial();
            sessionData.sessions{1} = fullfile(testCase.DataFolder, '08. laser 10mW start To laser stop');
            sessionData = io.detectRecordingSystem(sessionData);
            
            testCase.verifyMatches(sessionData.system, bntConstants.RecSystem.Neuralynx);
        end
        
        function axonaMultipleSessions(testCase)
            sessionData = helpers.initTrial();
            sessionData.sessions{1} = fullfile(testCase.DataFolder, 'Linear Track', '17906', '241112', '24111201_200');
            sessionData = io.detectRecordingSystem(sessionData);
            
            testCase.verifyMatches(sessionData.system, bntConstants.RecSystem.Axona);
        end
    end
end
