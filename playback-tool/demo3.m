%% Initialisation
addpath('/home/kashefy/twoears/AMLTTP/'); addpath('/home/kashefy/twoears/main'); addpath('/home/kashefy/twoears/stream-segregation-training-pipeline'); addpath('/home/kashefy/src/playrec/');
cd /home/kashefy/twoears/demos/playback-tool/
deviceId = 1;

%% Scenario 1 run 1/4
load('scenarios/01_scenario1_maleSp1_2017.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);

%% Scenario 1 run 2/4
load('scenarios/02_scenario1_maleSp2_2017.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);

%% Scenario 1 run 3/4
load('scenarios/03_scenario1_alarmSp1_2017.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);

%% Scenario 1 run 4/4
load('scenarios/04_scenario1_alarmSp2_2017.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);

%% Scenario 2 run 1/2
load('scenarios/Sc2_01_male_alarm_2017.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);

%% Scenario 2 run 2/2
% load('scenarios/Sc2_02_alarm_fire_female_2017.mat');
load('scenarios/Sc2_02_alarm_fire_male_2017.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);

%% Scenario 5 run 1/1
% Emergency detection
load('scenarios/Sc5_short.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);

%% Scenario 6 run 1/1
% find the baby
load('scenarios/Sc6_baby_2017.mat');
%%
playbackScenario(scenario, 44100, deviceId, 1:4);