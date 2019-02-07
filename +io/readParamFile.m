% Read parameters from file
%
%  USAGE
%   p = data.readParamFile(filename)
%   filename        Full path to settings file.
%   p               Structure with loaded parameters
%
function p = readParamFile(filename)
    str = fileread(filename);
    eval(str);
end
