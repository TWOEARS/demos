function [sourceSets, sourceVolumes] = setupScenes

sourceSets{1} = {'femaleSpeech'};
sourceVolumes{1} = [1];
sourceSets{2} = {'alarm'};
sourceVolumes{2} = [1];
sourceSets{3} = {'femaleSpeech', 'alarm'};
sourceVolumes{3} = [1 1];
