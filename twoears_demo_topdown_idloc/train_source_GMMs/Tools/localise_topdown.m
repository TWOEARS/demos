function [azEst,prob_AFN_F,ratemap,mask] = localise_topdown(sig, fsHz, C, gmm_x, gmm_n, maskFloor, bAdaptNoiseMeans, bSmoothMask)
%localise_topdown   Localisation with top-down source models.
%
%USAGE
%   [azEst] = localise_topdown(sig, fsHz, C, gmm_x, gmm_n, maskFloor, bAdaptNoiseMeans, bSmoothMask)
%
%INPUT ARGUMENTS
%              sig : binaural input signal [nSamples x 2]
%             fsHz : sampling frequency in Hertz
%                C : classifier structure used for localisation
%            gmm_x : Target model (Netlab-format GMM)
%            gmm_n : Background noise model (Netlab-format GMM)
%        maskFloor : Mask values below this threshold will be set to zero
%  bAdaptNoiseMeans: Adapt the means of gmm_n to compensate for any level
%                    mismatch w.r.t. the observed data (Boolean, default:false).
%
%OUTPUT ARGUMENTS
%     azEst : estimated azimuths
% 
%
% Ning Ma, 14 Oct 2014
%   
%

bTopDown = true;
if nargin < 4
    bTopDown = false;
end
if nargin < 6
    maskFloor = 0.1;
end
if nargin < 7
    bAdaptNoiseMeans = false;
end
if nargin < 8
    bSmoothMask = false;
end


%% AFE processing
%
AFE_request_mix = C.AFE_request_mix;
if bTopDown
    AFE_request_mix = [AFE_request_mix {'ratemap'}];
end
dObj = dataObject(sig, fsHz);
mObj = manager(dObj, AFE_request_mix, C.AFE_param);
mObj.processSignal();

% Work out which features to use
features = strsplit(C.ftrType, '-');
bUseFeatures = false(4, 1); % ITD, ILD, CC, IC
for n = 1:length(features)
    switch lower(features{n})
        case 'itd'
            itd = dObj.itd{1}.Data(:);
            bUseFeatures(1) = true;
            nFrames = size(itd,1);
        case 'ild'
            ild = dObj.ild{1}.Data(:);
            bUseFeatures(2) = true;
            nFrames = size(ild,1);
        case 'cc'
            cc = dObj.crosscorrelation{1}.Data(:);
            % Use only -1ms to 1ms
            idx = ceil(size(cc,3)/2);
            mlag = ceil(fsHz/1000);
            cc = cc(:,:,idx-mlag:idx+mlag);
            bUseFeatures(3) = true;
            nFrames = size(cc,1);
        case 'ic'
            ic = dObj.ic{1}.Data(:);
            bUseFeatures(4) = true;
            nFrames = size(ic,1);
    end
end


%% Compute location posteriors
nChannels = numel(C.NNs);
chans = 1:nChannels;
nChannels = length(chans);

post = zeros(nFrames, C.nAzimuths, nChannels);
yy = zeros(nFrames, C.nAzimuths);

% Loop over number of Gammatone channels
for n = 1 : nChannels

    % Select features
    ch = chans(n);
    
    testFeatures = [];
    if bUseFeatures(1)
        testFeatures = [testFeatures itd(:,ch)];
    end
    if bUseFeatures(2)
        testFeatures = [testFeatures ild(:,ch)];
    end
    if bUseFeatures(3)
        testFeatures = [testFeatures squeeze(cc(:,ch,:))];
    end
    if bUseFeatures(4)
        testFeatures = [testFeatures ic(:,ch)];
    end
    
    % Normalise features
    testFeatures = testFeatures - repmat(C.normFactors{ch}(1,:),[size(testFeatures,1) 1]);
    testFeatures = testFeatures ./ sqrt(repmat(C.normFactors{ch}(2,:),[size(testFeatures,1) 1]));

    C.NNs{ch}.testing = 1;
    C.NNs{ch} = nnff(C.NNs{ch}, testFeatures, yy);
    post(:,:,n) = C.NNs{ch}.a{end} + eps;
    C.NNs{ch}.testing = 0;
    
    % % Normalize across all azimuth directions
    % post(:,:,ch) = post(:,:,ch) ./ repmat(sum(post(:,:,ch),2),[1 size(post(:,:,ch),2) 1]);
    
end

if bTopDown
    %% Estimate soft mask for the target source
    %
    % Compute average ratemaps
    ratemap = (dObj.ratemap{1}.Data(:)' + dObj.ratemap{2}.Data(:)') ./ 2;
    % log compression
    ratemap = log(max(ratemap, eps));
    % Estimate a mask
    mask = estimate_mask_GMM2(ratemap, gmm_x, gmm_n, bAdaptNoiseMeans);

    % Smooth the mask
    if bSmoothMask
        mask = smooth_mask(mask);
    end
    mask(mask<maskFloor) = 0;

    %subplot(211);imagesc(ratemap); axis xy
    %subplot(212);imagesc(mask); axis xy

    %% Apply the mask before integration
    mask2 = reshape(mask', size(mask,2), 1, size(mask,1));

    % Integrate probabilities across all frequency channel
    prob_AF = exp(squeeze(nansum(bsxfun(@times,log(post),mask2),3)));

    % Normalize such that probabilities sum up to one for each frame
    prob_AFN = transpose(prob_AF ./ repmat(sum(prob_AF,2),[1 C.nAzimuths]));

    % Integrate across all frames
    prob_AFN_F = nanmean(prob_AFN,2);
    %mask3 = sum(mask);
    %prob_AFN_F = nansum(bsxfun(@times,prob_AFN,mask3./sum(mask3)),2);
else
    % Integrate probabilities across all frequency channels
    prob_AF = exp(squeeze(nansum(log(post),3)));

    % Normalise each frame such that probabilities sum up to one
    prob_AFN = prob_AF ./ repmat(sum(prob_AF,2),[1 C.nAzimuths]);

    % Integrate probabilities acrros all time frames
    prob_AFN_F = nanmean(prob_AFN, 1);

end

% Find peaks, also consider endpoints as peak candidates
pIdx = findpeaks([0; prob_AFN_F(:); 0]);
pIdx = pIdx - 1;

% Rank peaks
[temp,idx] = sort(prob_AFN_F(pIdx),'descend'); %#ok

% Azimuth estimate: Take most significant peaks
nEst = 2;
azEst = C.azimuths(pIdx(idx(1:nEst)));

