function [Px_y, Cx_y] = compute_likelihood_marginals(data, gmm)
[nChannels, nFrames] = size(data);
nMix = gmm.ncentres;
Px_y = zeros(nChannels, nFrames, nMix); %Px(y|k)
Cx_y = zeros(nChannels, nFrames, nMix); %Px(x<=y|k)
for k = 1:nMix
    mu_k = repmat(gmm.centres(k,:)', 1, nFrames);
    if strcmp(gmm.covar_type,'diag')
        var_k = repmat(gmm.covars(k,:)', 1, nFrames);
    else
        var_k = repmat(diag(gmm.covars(:,:,k)), 1, nFrames);
    end
    
    Px_y(:,:,k) = probabilityMat(data, mu_k, var_k);
    Cx_y(:,:,k) = cumulativeProbMat(data, mu_k, var_k);
end