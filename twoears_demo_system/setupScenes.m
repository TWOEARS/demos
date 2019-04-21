function [sourceSets, sourceVolumes] = setupScenes

%% TRAIN SET

sourceSets{1} = {'signal_f1_mini';'signal_f2_mini'};
sourceVolumes{1} = [1 1];
sourceSets{2} = {'signal_f1_mini';'signal_f2_mini';'signal_f6_mini'};
sourceVolumes{2} = [1 1 1];
sourceSets{3} = {'signal_f1_mini';'signal_f2_mini';'signal_f6_mini';'signal_f3_mini'};
sourceVolumes{3} = [1 1 1 1];


%% TEST SET -- DO NOT USE FOR PARAMETER ADAPTATION, FINDING THE BEST BLACKBOARD SYSTEM, ETC!
% sourceSets{1} = {'signal_f7';'signal_f8'};
% sourceVolumes{1} = [1 1];
% sourceSets{2} = {'signal_f7';'signal_f8';'signal_f7_v2'};
% sourceVolumes{2} = [1 1 1];
% sourceSets{3} = {'signal_f7';'signal_f8';'signal_f7_v2';'signal_f8_v2'};
% sourceVolumes{3} = [1 1 1 1];
