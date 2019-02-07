% Return the path to test data
function folder = dataFolder()
    folder = fullfile(tempdir, 'bnt-data');
    if exist(folder, 'dir') == 0
        envVarName = 'BNT_TESTS_FOLDER';
        folder = getenv(envVarName);
        if isempty(folder)
            error('BNT:noFile', 'Didn''t find tests data. Check that it is in %s or set environment variable %s.', ...
                fullfile(tempdir, 'bnt-data'), envVarName);
        end
    end
end