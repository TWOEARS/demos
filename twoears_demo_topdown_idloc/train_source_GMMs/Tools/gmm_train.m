function mix= gmm_train(data, ngauss, covType, maxIter, initMix)

if nargin < 4
    maxIter= 100;
end

%Initiliase the GMM using the k-means algorithm
if nargin < 5    
    %Step 1: execute the kmeans algorithm and assign each data point to one
    %cluster
    disp('Initialising the GMM with the k-means algorithm');
    options= statset('Display','final', 'MaxIter', 20);
    startGMM= kmeans(data, ngauss, 'emptyaction', 'singleton', 'options', options);
    
%Refine the GMM initMix
else
    disp('Estimating the GMM parameters with the EM algorithm');
    initObj= gmdistribution(initMix.centres,initMix.covars, initMix.priors);
    startGMM= struct('PComponents',initObj.PComponents,'mu',initObj.mu,'Sigma',initObj.Sigma);
end

%Step 2: execute the EM algorithm to estimate the GMM parameters using
%the k-means results as an starting point
disp('Estimating the GMM parameters with the EM algorithm');
options= statset('Display','final', 'MaxIter', maxIter);

if strcmp(covType, 'diag')
    ctype= 'diagonal';
else
    ctype= 'full';
end

regVal= 1e-4;
success= false;
while ~success
    try
        mixObj= gmdistribution.fit(data, ngauss, 'CovType', ctype, 'Start', startGMM, 'Regularize', regVal, 'Options', options);
        success= true;
%         if mixObj.NlogL > 0
%             success= true;
%         else
%             regVal= regVal * 10;
%         end
    catch err
        disp(['EM algorithm exception: ' err.message]);
        regVal= regVal * 10;
    end
end

mix= gmm_init(size(data, 2), ngauss, covType);
mix.priors= mixObj.PComponents;
mix.centres= mixObj.mu;
if strcmp(covType, 'full')
    mix.covars= mixObj.Sigma;
else
    mix.covars= squeeze(mixObj.Sigma)';
end
