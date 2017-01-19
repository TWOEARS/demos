function execTestScenario2_20170119()

startAMLTTP;
flAlarm = fullfile( pwd, 'alarm_2017.flist' );
flFire = fullfile( pwd, 'fire_2017.flist' );
flFemale = fullfile( pwd, 'female.flist' );
flFScream = fullfile( pwd, 'fScream.flist' );
flBaby = fullfile( pwd, 'baby.flist' );
flPiano = fullfile( pwd, 'piano.flist' );
flPhone = fullfile( pwd, 'phone.flist' );
flMale = fullfile( pwd, 'male.flist' );
flMScream = fullfile( pwd, 'mScream.flist' );
flKnock = fullfile( pwd, 'knock.flist' );
flGeneral = fullfile( pwd, 'general.flist' );
flFootsteps = fullfile( pwd, 'footsteps.flist' );
flEngine = fullfile( pwd, 'engine.flist' );
flDog = fullfile( pwd, 'dog.flist' );

% alarm from 2 + fire from 1
scDef = struct();
scDef.s4.flist = {{flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}};
scDef.s4.onsetDelay = {1.0; 1.0; 1.0; 1.0; 1.0; 1.0};
scDef.s4.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0; 0.0; 0.0};

% scDef.s2.flist = {{flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}};
% scDef.s2.onsetDelay = {1.0; 1.0; 1.0; 1.0};
% scDef.s2.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0};
scDef.s1.flist = {{flMale}; {flMale}; {flMale}; {flMale}};
scDef.s1.onsetDelay = {1.0; 1.0; 1.0; 1.0};
scDef.s1.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0};
scDef.length = 120; % seconds

scenario = produceScenario( scDef );
% save('scenarios/Sc2_01_alarm_fire_2017.mat', 'scenario');
save('scenarios/Sc2_01_male_alarm_2017.mat', 'scenario');

% alarm + speech + fire
% alarm from 2 + fire from 1
scDef = struct();
scDef.s2.flist = {{flFire}; {flFire}; {flFire}; {flFire}; {flFire}; {flFire}};
scDef.s2.onsetDelay = {1.0; 1.0; 1.0; 1.0; 1.0; 1.0};
scDef.s2.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0; 0.0; 0.0};

scDef.s4.flist = {{flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}};
scDef.s4.onsetDelay = {1.0; 1.0; 1.0; 1.0; 1.0; 1.0};
scDef.s4.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0; 0.0; 0.0};

scDef.s1.flist = {{flMale}; {flMale}; {flMale}; {flMale}};
scDef.s1.onsetDelay = {1.0; 1.0; 1.0; 1.0};
scDef.s1.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0};
scDef.length = 120; % seconds

scenario = produceScenario( scDef );
save('scenarios/Sc2_02_alarm_fire_male_2017.mat', 'scenario');

end
