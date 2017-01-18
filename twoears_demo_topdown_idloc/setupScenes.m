function [sourceSets, sourceVolumes] = setupScenes

% 'alarm'   'baby'  'fire'  'femaleSpeech'   'maleSpeech' 
% 31        17      16      21               24

sourceSets{1} = {'alarm', 'femaleSpeech'};
sourceVolumes{1} = [31 21];

sourceSets{2} = {'alarm', 'femaleSpeech', 'baby'};
sourceVolumes{2} = [31 21 17];
