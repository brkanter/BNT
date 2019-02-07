classdef GetAnimalNameTester < tests.TestCaseWithData
    methods
        function this = GetAnimalNameTester()
            this.doCleanUp = true;
            this.copyRecordings = true;
        end
    end
    
    methods(Test)
        function noArguments(testCase)
            data.loadSessions(fullfile(testCase.DataFolder, 'input-axona-no-cuts.txt'));
            
            expectedName = '11138';
            animalName = data.getAnimalName();

            testCase.verifyEqual(animalName, expectedName);
        end

        function wrongArguments(testCase)
            testCase.verifyError(@()data.getAnimalName('first'), 'BNT:arg');
        end

        function secondLevel(testCase)
            data.loadSessions(fullfile(testCase.DataFolder, 'input-axona-name-test.txt'));
            expectedName = '11138';
            animalName = data.getAnimalName(2);

            testCase.verifyEqual(animalName, expectedName);
        end
        
        function neuralynxFormat(testCase)
            data.loadSessions(fullfile(testCase.DataFolder, 'input-neuralynxNoCut.txt'));
            expectedName = 'Ivan';
            depth = 2;

            animalName = data.getAnimalName(depth);
            testCase.verifyEqual(animalName, expectedName);
            
            animalName = data.getAnimalName(1, 2);
            testCase.verifyEqual(animalName, expectedName);
        end
    end
end