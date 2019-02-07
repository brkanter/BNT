% Batch process of script webGrid. Example of an input file is located in 'examples/list_of_files_to_process.txt'.
% In general input file should contain list of paths to files you want to submit to webGrid. 
% Any line that contains a '#' sign in it will be skipped.
function webGridBatch(filename)
    fid = fopen(filename);
    if fid == -1
        error('failed to open file %s', filename);
    end
    
    c = onCleanup(@() fclose(fid));

    while ~feof(fid)
        str = fgetl(fid);
        
        % skip empty strings
        if isempty(str)
            continue;
        end
        
        % skip lines with # in them
        if ~isempty(strfind(str, '#'))
            continue;
        end

        disp(['Processing file ' str]);
        webGrid(str);
    end
end