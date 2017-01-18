
recPath = '/Users/ning/work/TwoEars/sheffield-git/topdown-localisation/train_source_GMMs/Jido_recordings';

soundList = {'alarm', 'baby', 'fire', 'femaleSpeech', 'maleSpeech', 'telephone'};
volumeList = zeros(length(soundList), 1);
for n = 1:length(soundList)

    if strfind(soundList{n}, 'Speech') > 0
        soundType = 'speech';
    else
        soundType = soundList{n};
    end
    
    [rec,fsHz] = audioread(sprintf('%s/jido_rec_%s.wav', recPath, soundType));
    rms_rec = mean(rms(rec));
    
    vol = 1;
    [sig, fsHz_sim] = testToulouseBRIRs(soundList(n), vol);
    sig = resample(sig, fsHz, fsHz_sim);
    rms_sim = mean(rms(sig));
    
    volumeList(n) = rms_rec/rms_sim;
    fprintf('%s vol: %d\n', soundList{n}, volumeList(n));
end

