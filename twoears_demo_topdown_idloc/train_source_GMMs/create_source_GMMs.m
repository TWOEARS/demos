function create_source_GMMs

rmpath /Users/ning/work/TwoEars/twoears-git/blackboard-system/src/tools/GMM_Netlab/

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

sourceList = {'telephone', 'alarm', 'fire', 'baby', 'speech'};
nMixSources = [2 3 7 16 32];
nSources = numel(sourceList);
covarType = 'diag';

% Initialise classifier
C = struct('ftrType', ftrType, ...
           'covarType',covarType, ...
           'AFE_param', AFE_param, ...
           'AFE_request', {AFE_request}, ...
           'nSources', nSources, ...
           'sourceList', {sourceList});
sourceGMMs = cell(nSources, 1);

for n=1:nSources
    
    nMix = nMixSources(n);
    
    fprintf('\n---- Generating %s features for source: %s\n', ftrType, sourceList{n})
    ratefn = sprintf('jido_rec_rate32_%s.mat', sourceList{n});
    if exist(ratefn, 'file')
        load(ratefn);
    else
        [sig,fsHz] = audioread(fullfile(wavDir, sprintf('jido_rec_%s.wav', sourceList{n})));

        dObj = dataObject(sig, fsHz, floor(size(sig,1)/fsHz), 2);
        mObj = manager(dObj, AFE_request, AFE_param);
        mObj.processSignal();

        ratemap = (dObj.ratemap{1}.Data(:) + dObj.ratemap{2}.Data(:)) ./ 2;

        % Make sure ratemap is positive
        ratemap = max(ratemap, eps);

        % log compression of ratemaps
        ratemap = log(ratemap);
        
        % Save ratemap
        save(ratefn, 'ratemap');
    end
    
    % Train GMM
    fprintf('\n---- Training %d mix GMM for source: %s\n', nMix, sourceList{n});
    sourceGMMs{n} = gmm_train(ratemap, nMix, covarType);
end

C.sourceGMMs = sourceGMMs;

% Pool all source models to form a universal background model
C.UBM = sourceGMMs{1};
for n = 2:nSources
    C.UBM.ncentres = C.UBM.ncentres + sourceGMMs{n}.ncentres;
    C.UBM.priors = [C.UBM.priors sourceGMMs{n}.priors];
    C.UBM.centres = [C.UBM.centres; sourceGMMs{n}.centres];
    C.UBM.covars = [C.UBM.covars; sourceGMMs{n}.covars];
end
C.UBM.priors = C.UBM.priors ./ sum(C.UBM.priors);
C.UBM.nwts = C.UBM.ncentres + C.UBM.ncentres*C.UBM.nin*2;

% Save model name
strSourceGMMs = sprintf('SourceGMMs_%s_%s', preset, ftrType);

save(strSourceGMMs, 'C');
