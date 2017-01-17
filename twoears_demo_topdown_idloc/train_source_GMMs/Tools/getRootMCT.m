function rootDir = getRoot
%getRootMCT   Return user-specific root directories.
%   
%USAGE
%      rootDir = getRootMCT
%
%OUTPUT ARGUMENTS
%      rootDir : user-specific root diretory


%   Developed with Matlab 8.3.0.532 (R2014a). Please send bug reports to:
%   
%   Author  :  Tobias May, © 2013
%              Technical University of Denmark
%              tobmay@elektro.dtu.dk
%
%   History :
%   v.0.1   2014/07/24
%   ***********************************************************************


%% ***********************  CHECK INPUT ARGUMENTS  ************************
% 
% 
% Check for proper input arguments
if nargin ~= 0
    help(mfilename);
    error('Wrong number of input arguments!')
end


%% *****************  GET USER-SPECIFIC ROOT DIRECTORIES  *****************
% 
% 
% Select user-dependent root directory for the audio files
switch(upper(getUser))
    case 'ELEK-D0170'
        rootDir = 'M:\Research\Matlab\Projects\MCT';
    case 'NING'
        rootDir = '/Users/ning/work/TwoEars/data/MCT';
    otherwise
        error('Root directory is not specified for ''%s'' ! Edit the root entry in ''%s.m''.',upper(getUser),mfilename)
end

