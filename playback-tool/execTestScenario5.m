function execTestScenario5()

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

% scenario5: Source properties now change to crying/screams for help: robot switches into S&R mode:
% Piano -> Fire
% Telephone -> Alarm
% Male speech -> Baby
% Female speech -> Scream
scDef = struct();
scDef.s1.flist = {{flPiano};{flFire}};
scDef.s1.onsetDelay = {1.0;5.0};
scDef.s1.inbetweenFilesGap = {2.0;0.5};
scDef.s2.flist = {{flPhone};{flAlarm}};
scDef.s2.onsetDelay = {15.0; 30.0};
scDef.s2.inbetweenFilesGap = {0.0; 2.0};
scDef.s3.flist = {{flMale}; {flMale}; {flBaby}};
scDef.s3.onsetDelay = {10.0; 2.0; 30.0};
scDef.s3.inbetweenFilesGap = {1.0;0.0;1.0};
scDef.s4.flist = {{flFemale};{flFemale};{flFScream};{flFScream}};
scDef.s4.onsetDelay = {1.0;3.0;0.0;1.0};
scDef.s4.inbetweenFilesGap = {6.0;3.0;0.0;2.0};
scDef.length = 400; % seconds

scenario = produceScenario( scDef );
save('scenario5.mat', 'scenario');

end
