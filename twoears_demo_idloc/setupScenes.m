function [sourceSets, sourceVolumes] = setupScenes

sourceSets{1} = {'alarm'};
sourceVolumes{1} = [0.3];
sourceSets{2} = {'fire'};
sourceVolumes{2} = [1];
sourceSets{3} = {'alarm', 'fire'};
sourceVolumes{3} = [0.3 1];
