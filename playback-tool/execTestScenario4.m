function execTestScenario()

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

% scDef = struct();
% scDef.s1.flist = {{flPiano};{flAlarm};{flAlarm}};
% scDef.s1.onsetDelay = {1.0;5.0;0.0};
% scDef.s1.inbetweenFilesGap = {2.0;0.5;0.5};
% scDef.s2.flist = {{flFire}};
% scDef.s2.onsetDelay = {155.0};
% scDef.s2.inbetweenFilesGap = {0.0};
% scDef.s3.flist = {{flDog,flDog}};
% scDef.s3.onsetDelay = {[10.0,165.0]};
% scDef.s3.inbetweenFilesGap = {[15.0,0.0]};
% scDef.s4.flist = {{flFemale,flMale};{flFScream,flBaby};{flBaby}};
% scDef.s4.onsetDelay = {[0.0,1.0];[0.0,3.0];0.0};
% scDef.s4.inbetweenFilesGap = {[6.0,4.5];[3.0,0.0];0.0};
% scDef.length = 400; % seconds

% scenario 4: Dynamic analysis mode: robot follows predefined path around the environment and maps the sources and their characteristics
% Piano, telephone ring, male speech, female speech
scDef = struct();
scDef.s1.flist = {{flPiano}};
scDef.s1.onsetDelay = {1.0};
scDef.s1.inbetweenFilesGap = {2.0};
scDef.s2.flist = {{flPhone};{flPhone}};
scDef.s2.onsetDelay = {5.0; 5.0};
scDef.s2.inbetweenFilesGap = {0.0; 0.0};
scDef.s3.flist = {{flFemale}; {flFemale}};
scDef.s3.onsetDelay = {10.0; 10.0};
scDef.s3.inbetweenFilesGap = {5.0; 5.0};
scDef.s4.flist = {{flMale}; {flMale}};
scDef.s4.onsetDelay = {0.0; 0.0};
scDef.s4.inbetweenFilesGap = {0.0; 0.0};
scDef.length = 180; % seconds

scenario = produceScenario( scDef );
save('scenario4.mat', 'scenario');

end
