function execTestScenario6()

flAlarm = fullfile( pwd, 'alarm.flist' );
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

% scenario6 S&R mode: robot moves freely around the environment, 
% prioritising sources that are of key interest (child, screams) 
% but also mapping other sounds (speech, alarm)
scDef = struct();
scDef.s1.flist = {{flBaby}, {flBaby}};
scDef.s1.onsetDelay = {1.0; 4.0};
scDef.s1.inbetweenFilesGap = {2.0; 2.0};
scDef.s2.flist = {{flFScream};{flMScream}; {flFScream}};
scDef.s2.onsetDelay = {30.0; 60.0; 1.0};
scDef.s2.inbetweenFilesGap = {0.0; 0.0; 1.0};
scDef.s3.flist = {{flFemale}; {flFemale}};
scDef.s3.onsetDelay = {0.0; 100.0};
scDef.s3.inbetweenFilesGap = {5.0; 5.0};
scDef.s4.flist = {{flMale}; {flMale}};
scDef.s4.onsetDelay = {10.0; 90.0};
scDef.s4.inbetweenFilesGap = {0.0; 0.0};
scDef.length = 180; % seconds

scenario = produceScenario( scDef );
save('scenario6.mat', 'scenario');

end
