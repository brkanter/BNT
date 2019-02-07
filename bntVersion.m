% Version information for BNT
%
% Returns a string containing BNT version. Empty string is returned if no version information
% is available.
%
function vv = bntVersion()
    bntGitFolder = fullfile(helpers.bntRoot, '.git');
    vv = git(sprintf('--git-dir "%s" describe --long --tags --match v*', bntGitFolder));
    if ~isempty(strfind(lower(vv), 'fatal'))
        vv = '';
    end
end