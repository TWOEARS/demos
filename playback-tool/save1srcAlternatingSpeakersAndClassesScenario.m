function save1srcAlternatingSpeakersAndClassesScenario()

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

scDef = struct();
scDef.s1.flist = {{flFScream}};
scDef.s1.onsetDelay = {2.0};
scDef.s1.inbetweenFilesGap = {1.0};
scDef.s2.flist = {{flMale}};
scDef.s2.onsetDelay = {34.0};
scDef.s2.inbetweenFilesGap = {0.0};
scDef.s3.flist = {{flAlarm}};
scDef.s3.onsetDelay = {85.0};
scDef.s3.inbetweenFilesGap = {0.5};
scDef.s4.flist = {{flFire}};
scDef.s4.onsetDelay = {183.0};
scDef.s4.inbetweenFilesGap = {0.0};
scDef.length = 400; % seconds

%scenario = produceScenario( scDef );
%save('Sc1-OneSrcAltSpkrsClasses.mat', 'scenario');

scDef = struct();
scDef.s2.flist = {{flMale};{flFemale};{flMale};{flFemale};{flMale};{flFemale};{flMale};{flFemale};{flMale};{flFemale}};
scDef.s2.onsetDelay = {0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0};
scDef.s2.inbetweenFilesGap = {0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0};
scDef.length = 600; % seconds

scenario = produceScenario( scDef );
save('Sc1-SpeechSp2.mat', 'scenario');

scDef = struct();
scDef.s1.flist = {{flFire};{flFire}};
scDef.s1.onsetDelay = {0.0;0.0};
scDef.s1.inbetweenFilesGap = {0.0;0.0};
scDef.length = 600; % seconds

scenario = produceScenario( scDef );
save('Sc1-FireSp1.mat', 'scenario');

scDef = struct();
scDef.s2.flist = {{flAlarm};{flPhone};{flAlarm};{flPhone};{flAlarm};{flPhone}};
scDef.s2.onsetDelay = {0.0;0.0;0.0;0.0;0.0;0.0};
scDef.s2.inbetweenFilesGap = {0.0;0.0;0.0;0.0;0.0;0.0};
scDef.length = 600; % seconds

scenario = produceScenario( scDef );
save('Sc1-AlarmPhoneSp2.mat', 'scenario');

end
