function [dataRoot] = get_data_root

[~,user] = system('whoami');

switch lower(strtrim(user))
    case {'ning'}
        dataRoot = '/Users/ning/work/TwoEars/data/topdown-localisation';
       
    case {'ac1nmx'}
        dataRoot = '/data/ac1nmx/data/topdown-localisation';
    otherwise
        error('Data root not defined for user %s', user);
end

