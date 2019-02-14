function [sourceSets, sourceVolumes] = setupScenes

%% TRAIN SET

sourceSets{1} = {'signal_f1_mini';'signal_f2_mini'};
sourceVolumes{1} = [1 1];
sourceSets{2} = {'signal_f1_mini';'signal_f2_mini';'signal_f6_mini'};
sourceVolumes{2} = [1 1 1];


%% TEST SET -- DO NOT USE FOR PARAMETER ADAPTATION1, FINDING THE BEST BLACKBOARD SYSTEM, ETC!
% sourceSets{1} = {'signal_f7_mini';'signal_f8_mini'};
% sourceVolumes{1} = [1 1];
% sourceSets{1} = {'signal1','signal2','signal4','signal3'};
% sourceVolumes{1} = [1];
% sourceSets{2} = {'signal1','signal2';'signal4','signal3'};
% sourceVolumes{2} = [1 1];
% sourceSets{3} = {'signal1';'signal2';'signal4';'signal3'};
% sourceVolumes{3} = [1 1 1 1];
