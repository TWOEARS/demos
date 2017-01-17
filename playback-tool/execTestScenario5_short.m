function execTestScenario5_short()

flAlarm = fullfile( pwd, 'alarm.flist' );
flFire = fullfile( pwd, 'fire.flist' );
flFemale = fullfile( pwd, 'female_short.flist' );
flFScream = fullfile( pwd, 'fScream.flist' );
flBaby = fullfile( pwd, 'baby.flist' );
flPiano = fullfile( pwd, 'piano_short.flist' );
flPhone = fullfile( pwd, 'phone_short.flist' );
flMale = fullfile( pwd, 'male_short.flist' );
flMScream = fullfile( pwd, 'mScream.flist' );
flKnock = fullfile( pwd, 'knock.flist' );
flGeneral = fullfile( pwd, 'general.flist' );
flFootsteps = fullfile( pwd, 'footsteps.flist' );
flEngine = fullfile( pwd, 'engine.flist' );
flDog = fullfile( pwd, 'dog.flist' );

% scenario5: Source properties now change to crying/screams for help: robot switches into S&R mode:
% Piano -> Fire
% Telephone -> Alarm
% Male speech -> Baby
% Female speech -> Scream
scDef = struct();
scDef.s1.flist = {{flPiano};{flFire}};
scDef.s1.onsetDelay = {2.0;5.0};
scDef.s1.inbetweenFilesGap = {1.0;0.5};
scDef.s2.flist = {{flPhone};{flAlarm}};
scDef.s2.onsetDelay = {8.0; 0.0};
scDef.s2.inbetweenFilesGap = {10.0; 2.0};
scDef.s3.flist = {{flMale}; {flBaby}};
scDef.s3.onsetDelay = {11.0; 1.0};
scDef.s3.inbetweenFilesGap = {7.0;4.0};
scDef.s4.flist = {{flFemale};{flFScream}};
scDef.s4.onsetDelay = {1.0;30.0};
scDef.s4.inbetweenFilesGap = {4.0;7.0};
scDef.length = 140; % seconds

scenario = produceScenario( scDef );
save('scenarios/scenario5_short.mat', 'scenario');

end
