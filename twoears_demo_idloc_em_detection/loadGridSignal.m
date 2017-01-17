function [sig, fsHz] = loadGridSignal(gridPath, durSec)
% Load random GRID signals of durSec long

nSpeakers = 34;
sigLen = 0;
sig = [];
while sigLen < durSec
    spkid = randi(nSpeakers);
    spkPath = fullfile(gridPath, sprintf('s%d', spkid));
    allFiles = dir(fullfile(spkPath, '*.wav'));
    nFiles = length(allFiles);
    if nFiles > 0
        uttid = randi(nFiles);
        [x, fsHz] = audioread(fullfile(spkPath, allFiles(uttid).name));
        sig = [sig; x];
        sigLen = sigLen + length(x)/fsHz;
    end
end

