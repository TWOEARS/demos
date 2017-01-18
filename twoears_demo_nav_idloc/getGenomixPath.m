function [ genomixPath ] = getGenomixPath

[~,user] = system('whoami');

switch lower(strtrim(user))
    case {'ning'}
        genomixPath = '/Users/ning/work/TwoEars/twoears-git/genomix-path';
    case {'kashefy'}
        genomixPath = '/home/kashefy/openrobots/lib/matlab';
    case {'botein\ivot'}
        genomixPath = 'C:\projekte\twoEars\matlab-genomix';
    case {'christopher'}
        genomixPath = '/home/christopher/Git/Twoears/matlab-genomix1.5.1/lib/matlab';
    case {'xxx'}
        genomixPath = 'genomix-path';
    otherwise
        error('genomix path not defined for user %s', user);
end

