function [sourceSets, sourceVolumes] = setupScenes

% 'alarm'   'baby'  'fire'  'femaleSpeech'   'maleSpeech' 
% 31        17      16      21               24


sourceSets{1} = {'femaleSpeech'};
sourceVolumes{1} = [21];
sourceSets{2} = {'alarm'};
sourceVolumes{2} = [31];
sourceSets{3} = {'alarm', 'femaleSpeech'};
sourceVolumes{3} = [31 21];
