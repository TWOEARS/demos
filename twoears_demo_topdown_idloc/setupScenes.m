function [sourceSets, sourceVolumes] = setupScenes

% 'alarm'   'baby'  'fire'  'femaleSpeech'   'maleSpeech' 
% 31        17      16      21               24

sourceSets{1} = {'alarm', 'fire'};
sourceVolumes{1} = [31 16];

sourceSets{2} = {'alarm', 'femaleSpeech'};
sourceVolumes{2} = [31 21];
