function [post] = compute_posteriors_DNN(sig, fsHz, C)
%compute_posteriors_DNN   DNN-based localisation module.
%
%USAGE
%  [post] = compute_posteriors_DNN(sig, fsHz, C)
%
%INPUT ARGUMENTS
%          sig : binaural input signal [nSamples x 2]
%         fsHz : sampling frequency in Hertz
%            C : classifier structure used for localisation
%
%OUTPUT ARGUMENTS
%         post : posterior probabilities [nFrames, nAzimuths, nChannels]
% 
%
% Ning Ma, 29 Jan 2015
% n.ma@sheffield.ac.uk
%   
%

 
% AFE processing
dObj = dataObject(sig, fsHz);
mObj = manager(dObj, C.AFE_request_mix, C.AFE_param);
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

nChannels = numel(C.NNs);
chans = 1:nChannels;
nChannels = length(chans);

post = zeros(nFrames, C.nAzimuths, nChannels);
yy = zeros(nFrames, C.nAzimuths);

for n = 1:nChannels
    c = chans(n);
    
    testFeatures = [];
    if bUseFeatures(1)
        testFeatures = [testFeatures itd(:,c)];
    end
    if bUseFeatures(2)
        testFeatures = [testFeatures ild(:,c)];
    end
    if bUseFeatures(3)
        testFeatures = [testFeatures squeeze(cc(:,c,:))];
    end
    if bUseFeatures(4)
        testFeatures = [testFeatures ic(:,c)];
    end
   
    % Normalise features
    testFeatures = testFeatures - repmat(C.normFactors{c}(1,:),[size(testFeatures,1) 1]);
    testFeatures = testFeatures ./ sqrt(repmat(C.normFactors{c}(2,:),[size(testFeatures,1) 1]));

    C.NNs{c}.testing = 1;
    C.NNs{c} = nnff(C.NNs{c}, testFeatures, yy);
    post(:,:,n) = C.NNs{c}.a{end} + eps;
    C.NNs{c}.testing = 0;
end
