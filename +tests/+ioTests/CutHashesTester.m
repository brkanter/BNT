classdef CutHashesTester < tests.TestCaseWithData

    methods (Test)
        function loadOldCache(testCase)
            inputfile = fullfile(testCase.DataFolder, 'input-cut-hash.txt');
            trials = io.parseGeneralFile(inputfile);
            trial = helpers.initTrial();
            trial.extraInfo = trials{1}.extraInfo;
            trial.sessions = trials{1}.sessions;
            trial.cuts = trials{1}.cuts;
            trial.units = trials{1}.units;
            [baseFolder, firstName] = helpers.fileparts(trials{1}.sessions{1});
            trial.basename = firstName;
            trial.path = baseFolder;
            trial.system = bntConstants.RecSystem.Axona;
            trial.sampleTime = 0.02; % 50 Hz
            trial.videoSamplingRate = 50;
            
            trial = io.axona.detectAxonaCuts(trial);
            [loaded, ~] = io.checkAndLoad(trial);
            testCase.verifyFalse(loaded);
        end
        
        function loadAll(testCase)
            global gBntData;
            
            inputFile = fullfile(testCase.DataFolder, 'input-cut-hash.txt');
            testCase.verifyWarningFree(@()data.loadSessions(inputFile));
            
            for i = 1:length(gBntData)
                loaded = io.checkAndLoad(gBntData{i});
                testCase.verifyTrue(loaded, sprintf('Trial #%u failed to load from cache', i));
            end
        end
    end
end