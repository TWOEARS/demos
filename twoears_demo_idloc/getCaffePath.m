function [ genomixPath ] = getCaffePath

[~,user] = system('whoami');

switch lower(strtrim(user))
    case {'kashefy'}
        genomixPath = '/home/kashefy/src/caffe/matlab';
    case {'xxx'}
        genomixPath = 'genomix-path';
    otherwise
        error('genomix path not defined for user %s', user);
end

