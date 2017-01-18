function execTestScenario1_2017()

startAMLTTP;
flAlarm = fullfile( pwd, 'alarm_2017.flist' );
flFire = fullfile( pwd, 'fire.flist' );
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

scDef = struct();
scDef.s1.flist = {{flMale}; {flMale}; {flMale}; {flMale}};
scDef.s1.onsetDelay = {1.0; 0.0; 0.0; 0.0};
scDef.s1.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0};
scDef.length = 120; % seconds

scenario = produceScenario( scDef );
save('scenarios/01_scenario1_maleSp1_2017.mat', 'scenario');

scDef = struct();
scDef.s2.flist = {{flMale}; {flMale}; {flMale}; {flMale}; {flMale}; {flMale}};
scDef.s2.onsetDelay = {1.0; 0.0; 0.0; 0.0; 0.0; 0.0};
scDef.s2.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0; 0.0; 0.0};
scDef.length = 120; % seconds

scenario = produceScenario( scDef );
save('scenarios/02_scenario1_maleSp2_2017.mat', 'scenario');

scDef = struct();
scDef.s1.flist = {{flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}};
scDef.s1.onsetDelay = {1.0; 0.0; 0.0; 0.0; 0.0; 0.0};
scDef.s1.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0; 0.0; 0.0};
scDef.length = 120; % seconds

scenario = produceScenario( scDef );
save('scenarios/03_scenario1_alarmSp1_2017.mat', 'scenario');

scDef = struct();
scDef.s2.flist = {{flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}; {flAlarm}};
scDef.s2.onsetDelay = {1.0; 0.0; 0.0; 0.0; 0.0; 0.0};
scDef.s2.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0; 0.0; 0.0};
scDef.length = 120; % seconds

scenario = produceScenario( scDef );
save('scenarios/04_scenario1_alarmSp2_2017.mat', 'scenario');

end
