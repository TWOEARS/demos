function createSimulatedSounds

soundList = {'alarm', 'baby', 'fire', 'speech', 'telephone'};

for n = 1:length(soundList)
    [sig, fsHz] = testToulouseBRIRs(soundList(n), [1]);
    wavfn = sprintf('train_source_GMMs/simulated_sounds/simulated_%s.wav', soundList{n});
    if exist(wavfn, 'file') > 0
        sig2 = audioread(wavfn);
        sig = [sig; sig2];
    end
    audiowrite(wavfn, sig, fsHz);
    fprintf('%s\n', soundList{n});
end

[sig, fsHz] = testToulouseBRIRs({'maleSpeech','alarm'}, [1 1]);
audiowrite(sprintf('train_source_GMMs/simulated_sounds/simulated_mixed.wav'), sig, fsHz);
    