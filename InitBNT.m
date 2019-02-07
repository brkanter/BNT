% Initializae Behavioral Neurology Toolbox to run on this computer
%
% Initialize the toolbox and return a flag that indicates whther the
% toolbox had been updated. This flag can be used to stop any
% parent script execution.
%
%  USAGE
%   updated = InitBNT(<options>)
%   <options>       optional list of property-value pairs (see table below)
%
%   =========================================================================
%    Properties    Values
%   -------------------------------------------------------------------------
%    'force'      'on' if you want to force BNT update check, 'off' otherwise.
%                  Default is 'off'.
%    'cleanPath'   true or false. Basiclly only true is useful. If provided,
%                  will remove all BNT ecxternals from Matlab's path.
%   =========================================================================
function updated = InitBNT(varargin)

    updated = false;

    p = mfilename('fullpath');
    bntfolder = fileparts(p);

    % TODO: move away from globals to something else.
    % Say we have two versions of BNT on path: BNT1 and BNT2. We were in
    % BNT1, run InitBNT, then switched to BNT2 and run InitBNT again. It
    % will not actually initializy BNT2, it will just quit, cause gBntInit
    % have been set by BNT1.

    global gBntInit;
    if isempty(gBntInit)
        gBntInit = false;
    end

    % Set UTF-8 encoding
    feature('DefaultCharacterSet', 'UTF8');

    if isempty(getenv('home'))
        % this is needed for further SSH/Git usage
        setenv('home', getenv('userprofile'));
    end

    inp = inputParser;
    defaultForce = 'off';
    defaultCleanPath = false;

    checkForce = @(x) strcmpi(x, 'on') || strcmpi(x, 'off');

    % NB! A hack for users that must have a Matlab version prior to R2014b.
    % addParameter was introduced in R2014b.
    if exist(fullfile(bntfolder, 'pre2014b'), 'file') ~= 0
        addParamValue(inp, 'force', defaultForce, checkForce);
        addParamValue(inp, 'cleanPath', defaultCleanPath, @islogical);
    else
        addParameter(inp, 'force', defaultForce, checkForce);
        addParameter(inp, 'cleanPath', defaultCleanPath, @islogical);
    end
    parse(inp, varargin{:});
    forceUpdate = strcmpi(inp.Results.force, 'on');
    doCleanPath = inp.Results.cleanPath;

    externals = {
        'CircStat2012a'
        'xlswrite'
        'replaceinfile'
        'export_fig'
        'geom2d'
        'parfor_progress'
        'peakfinder'
        'normxcorr2_general'
        'git'
        'kalman'
        'DataHash'
        'Tang2014'
    };
    extFolder = fullfile(bntfolder, 'externals');

    %% check case when toolbox have already been added through another location
    allLocations = which('InitBNT', '-all');
    for i = 1:length(allLocations)
        % let's remove another instance of BNT from the path
        otherBntPath = fileparts(allLocations{i});
        if ~strcmpi(otherBntPath, bntfolder)
            rmpath(otherBntPath);

            otherExtFolder = fullfile(otherBntPath, 'externals');
            for j = 1:length(externals)
                curFolder = fullfile(otherExtFolder, externals{j});
                rmpath(curFolder)
            end
            
            if ~doCleanPath
                gBntInit = false;
            end
        end
    end
    
    if doCleanPath
        % only clean the path and return
        for i = 1:length(externals)
            curFolder = fullfile(extFolder, externals{i});
            if ~isempty(strfind(path, curFolder))
                rmpath(curFolder);
            end
        end
        return;
    end

    if gBntInit == true
        try
            updated = helpers.runGitUpdate('BNT', helpers.bntRoot(), forceUpdate);
            updatedScripts = false;
            scriptsPath = fullfile(helpers.bntRoot(), '+scripts');
            if exist(scriptsPath, 'dir') ~= 0
                updatedScripts = helpers.runGitUpdate('bnt-scripts', scriptsPath, forceUpdate);
            end
            updated = updated || updatedScripts;
        catch exc %#ok<NASGU>
            warning('BNT:updateFailed', 'Failed to autoupdate BNT');
        end
        % make sure that externals are still there
        addExternals(extFolder, externals);        
        disp('Behavioral Neurology Toolbox is already initialized');
        return;
    end

    %%
    if isempty(strfind(path, bntfolder))
        addpath(bntfolder);
    end

    addExternals(extFolder, externals);

    try
        updated = helpers.runGitUpdate('BNT', helpers.bntRoot(), forceUpdate);
        updatedScripts = false;
        scriptsPath = fullfile(helpers.bntRoot(), '+scripts');
        if exist(scriptsPath, 'dir') ~= 0
            updatedScripts = helpers.runGitUpdate('bnt-scripts', scriptsPath, forceUpdate);
        end
        updated = updated || updatedScripts;
    catch exc %#ok<NASGU>
        warning('BNT:updateFailed', 'Failed to autoupdate BNT');
    end

    % Let's be sure XPDF is there
    path_ = user_string('pdftops');
    haveXPDF =  check_xpdf_path(path_);
    if ~haveXPDF
        path_ = fullfile(helpers.bntRoot, 'externals', 'xpdf', computer('arch'), 'pdftops');
        if ~check_store_xpdf_path(path_)
            warning('BNT:noXPDF', 'Failed to find XPDF. Figure exporting might be broken.');
        end
    end

    warning('on', 'BNT:cutLengthInvalid');

    gBntInit = true;

    disp('Behavioral Neurology Toolbox has been initialized');
end

function good = check_xpdf_path(path_)
    % Check the path is valid
    [~, message] = system(sprintf('"%s" -h', path_));

    % system returns good = 1 even when the command runs
    % Look for something distinct in the help text
    good = ~isempty(strfind(message, 'PostScript'));
end

function good = check_store_xpdf_path(path_)
    % Check the path is valid
    good = check_xpdf_path(path_);
    if ~good
        return
    end
    % Update the current default path to the path found
    if ~user_string('pdftops', path_)
        warning('Path to pdftops executable could not be saved. Enter it manually in pdftops.txt.');
    end
end

function addExternals(extFolder, externals)
    for i = 1:length(externals)
        curFolder = fullfile(extFolder, externals{i});
        if isempty(strfind(path, curFolder))
            addpath(curFolder);
        end
    end
end