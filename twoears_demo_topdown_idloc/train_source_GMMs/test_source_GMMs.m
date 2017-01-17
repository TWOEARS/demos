function test_source_GMMs

NetlabPath = '/Users/ning/work/TwoEars/twoears-git/blackboard-system/src/tools/GMM_Netlab';
if exist(NetlabPath, 'dir')
    rmpath(NetlabPath);
end

% Install software 
% 
% Get to correct directory and add working directories to path
gitRoot = fileparts(fileparts(mfilename('fullpath')));

% Add TwoEars WP1 functionality
addpath(genpath(fullfile(gitRoot, 'local', 'binaural-simulator', 'src')));

% Add TwoEars AFE functionality
addpath(genpath(fullfile(gitRoot, 'local', 'auditory-front-end', 'src')));

% Add local tools
addpath Tools

% Add common scripts
addpath(genpath(fullfile(gitRoot, 'local', 'common')));

% Experimental parameters
%
ftrType = 'ratemap';

% Request cues being extracted from the noisy mixture
AFE_request = {ftrType};

% Frequency range and number of channels
AFE_param = initialise_AFE_parameters;

% Use clean models for source combination
preset = 'JIDO-REC';

wavDir = 'Jido_recordings';

ratefn = 'jido_rec_rate32_mixed.mat';
if exist(ratefn, 'file')
    load(ratefn);
else
    [sig,fsHz] = audioread(fullfile(wavDir, 'jido_rec_mixed.wav'));

    dObj = dataObject(sig, fsHz, floor(size(sig,1)/fsHz), 2);
    mObj = manager(dObj, AFE_request, AFE_param);
    mObj.processSignal();

    ratemap = (dObj.ratemap{1}.Data(:) + dObj.ratemap{2}.Data(:)) ./ 2;
    clear sig dObj mObj

    % Make sure ratemap is positive
    ratemap = max(ratemap, eps);

    % log compression of ratemaps
    ratemap = log(ratemap);
    save(ratefn, 'ratemap');
end

strSourceGMMs = sprintf('SourceGMMs_%s_%s', preset, ftrType);
load(strSourceGMMs)

% sourceList = {'telephone', 'alarm', 'fire', 'baby', 'speech'};

figure(1);
% speech + fire
ratemap_mix = ratemap(10:310,:)';
s1 = 5; s2 = 3;
subplot(311); imagesc(ratemap_mix); axis xy;
title(sprintf('%s + %s', C.sourceList{s1}, C.sourceList{s2}));
mask1 = estimate_mask_GMM2(ratemap_mix, C.sourceGMMs{s1}, C.UBM);
subplot(312); imagesc(mask1); axis xy;
title(sprintf('%s mask', C.sourceList{s1}));
mask2 = estimate_mask_GMM2(ratemap_mix, C.sourceGMMs{s2}, C.UBM);
subplot(313); imagesc(mask2); axis xy;
title(sprintf('%s mask', C.sourceList{s2}));

figure(2);
% baby + fire
ratemap_mix = ratemap(7110:7410,:)';
s1 = 4; s2 = 3;
subplot(311); imagesc(ratemap_mix); axis xy;
title(sprintf('%s + %s', C.sourceList{s1}, C.sourceList{s2}));
mask1 = estimate_mask_GMM2(ratemap_mix, C.sourceGMMs{s1}, C.sourceGMMs{s2});
subplot(312); imagesc(mask1); axis xy;
title(sprintf('%s mask', C.sourceList{s1}));
mask2 = estimate_mask_GMM2(ratemap_mix, C.sourceGMMs{s2}, C.sourceGMMs{s1});
subplot(313); imagesc(mask2); axis xy;
title(sprintf('%s mask', C.sourceList{s2}));

figure(3);
% telephone + speech
ratemap_mix = ratemap(11300:11400,:)';
s1 = 1; s2 = 5;
subplot(311); imagesc(ratemap_mix); axis xy;
title(sprintf('%s + %s', C.sourceList{s1}, C.sourceList{s2}));
mask1 = estimate_mask_GMM2(ratemap_mix, C.sourceGMMs{s1}, C.UBM);
subplot(312); imagesc(mask1); axis xy;
title(sprintf('%s mask', C.sourceList{s1}));
mask2 = estimate_mask_GMM2(ratemap_mix, C.sourceGMMs{s2}, C.UBM);
subplot(313); imagesc(mask2); axis xy;
title(sprintf('%s mask', C.sourceList{s2}));


figure(4);
% telephone + speech
ratemap_mix = ratemap(11290:11470,:)';
s1 = 1; s2 = 5;
subplot(121); imagesc(ratemap_mix); axis xy;
title(sprintf('%s + %s', C.sourceList{s1}, C.sourceList{s2}), 'FontSize', 14);
set(gca,'XTick', 0:40:160, 'XTickLabel',0:0.4:1.6, 'YTick', [1 8 16 24 32], 'YTickLabel', {'80','420','1300', '3300', '8000'}, 'FontSize', 12);
ylabel('Centre Frequency [Hz]', 'FontSize', 14);
xlabel('Time [s]');

mask2 = estimate_mask_GMM2(ratemap_mix, C.sourceGMMs{s2}, C.UBM);
subplot(122); image(mask2>=0.5); axis xy;
title('Segregation mask', 'FontSize', 14);
set(gca,'XTick', 0:40:160, 'XTickLabel',0:0.4:1.6, 'YTick', [1 8 16 24 32], 'YTickLabel', {'80','420','1300', '3300', '8000'}, 'FontSize', 12);
ylabel('Centre Frequency [Hz]', 'FontSize', 14);
xlabel('Time [s]');


cm = colormap;
cm(1,:) = [1 1 1];
cm(2,:) = [0 0 0];
colormap(cm);

