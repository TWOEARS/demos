function execTestScenario6_baby_2017()

startAMLTTP;
flAlarm = fullfile( pwd, 'alarm_2017.flist' );
flFire = fullfile( pwd, 'fire.flist' );
flFemale = fullfile( pwd, 'female.flist' );
flFScream = fullfile( pwd, 'fScream.flist' );
flBaby = fullfile( pwd, 'baby_single.flist' );
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
scDef.s1.flist = {{flBaby}; {flBaby}; {flBaby}; {flBaby}};
scDef.s1.onsetDelay = {1.0; 0.0; 0.0; 0.0};
scDef.s1.inbetweenFilesGap = {0.0; 0.0; 0.0; 0.0};
scDef.length = 240; % seconds

scenario = produceScenario( scDef );
save('scenarios/Sc6_baby_2017.mat', 'scenario');

end
