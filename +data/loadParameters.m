% Load parameters for the analysis
%
%  USAGE
%   p = data.loadParameters(filename)
%   filename        Full path to settings file.
%   p               Structure with loaded parameters
%
function p = loadParameters(filename)
    p = io.readParamFile(filename);
    p = helpers.checkParameters(p);
end
