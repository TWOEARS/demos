function saveSc2Scenarios()

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
flFMspeech = fullfile( pwd, 'fmSpeech.flist' );
flNingPhone = fullfile( pwd, 'ningsParticularPhone.flist' );

scDef = struct();
scDef.s1.flist = {{flNingPhone};{flNingPhone};{flNingPhone};{flNingPhone};{flNingPhone};{flNingPhone};{flNingPhone};{flNingPhone};{flNingPhone};{flNingPhone}};
scDef.s1.onsetDelay = {0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0};
scDef.s1.inbetweenFilesGap = {0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0};
scDef.s2.flist = {{flFMspeech};{flFMspeech};{flFMspeech};{flFMspeech};{flFMspeech};{flFMspeech};{flFMspeech};{flFMspeech};{flFMspeech};{flFMspeech}};
scDef.s2.onsetDelay = {0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0};
scDef.s2.inbetweenFilesGap = {0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0};
scDef.length = 60; % seconds

scenario = produceScenario( scDef );
save('Sc2-SpeechVsPhone-TopDown.mat', 'scenario');

scDef = struct();
scDef.s1.flist = {{flFire};{flFire}};
scDef.s1.onsetDelay = {0.0;0.0};
scDef.s1.inbetweenFilesGap = {0.0;0.0};
scDef.s2.flist = {{flFemale}};
scDef.s2.onsetDelay = {0.0};
scDef.s2.inbetweenFilesGap = {0.0};
scDef.s3.flist = {{flBaby}};
scDef.s3.onsetDelay = {54.0};
scDef.s3.inbetweenFilesGap = {0.0};
scDef.s4.flist = {{flPhone}};
scDef.s4.onsetDelay = {267.0};
scDef.s4.inbetweenFilesGap = {0.0};
scDef.length = 400;

scenario = produceScenario( scDef );
save('Sc2-1spFixedFire-1spAlternating.mat', 'scenario');

end
