function [mask, logLikelihood] = estimate_mask_GMM(data, gmm_x, gmm_n)
% estimate_mask_GMM   Estimate a soft mask using source GMMs
%
% 
%USAGE  
%  [mask, logLikelihood] = estimate_mask_GMM(data, gmm_x, gmm_n)
%
%INPUT ARGUMENTS
%           data : Observed spectral data [nChannels x nFrames]
%          gmm_x : Target model (Netlab-format GMM)
%          gmm_n : Background noise model (Netlab-format GMM)
%
%OUTPUT ARGUMENTS
%           mask : Estimated soft mask [nDim x nFrames]
%  logLikelihood : Log likelihood
%
%
%The probability that the observed y_d belongs to Sx and not Sn is given by
%P(x_d=y_d|y) = P(x_d>n_d|y)
%
%             = \sum_{k_x,k_n} P(k_x,k_n|y) P(x_d>n_d|y_d,k_x,k_n)      (1)
%
%
%                Px(k_x) Pn(k_n) P(y|k_x,k_n)
%P(k_x,k_n|y) = ------------------------------
%                           P(y)
%
%                Px(k_x) Pn(k_n) \prod_d P(y_d|k_x,k_n)
%             = ----------------------------------------                (2)
%                                P(y)

%
%                          P(x_d=y_d,n_d<y_d|k_x,k_n)
%P(x_d>n_d|y_d,k_x,k_n) = ----------------------------
%                                P(y_d|k_x,k_n)
%
%                          Px(y_d|k_x) Cn(y_d|k_n)
%                       = -------------------------                     (3)
%                               P(y_d|k_x,k_n)
%
%Thus (1) becomes
%
%                                            Px(y_d|k_x) Cn(y_d|k_n)
%P(x_d=y_d|y) = \sum_{k_x,k_n} P(k_x,k_n|y) ------------------------- 
%                                                 P(y_d|k_x,k_n)
%
%                   Px(k_x) Pn(k_n) \prod_d P(y_d|k_x,k_n)   Px(y_d|k_x) Cn(y_d|k_n)
% = \sum_{k_x,k_n} ---------------------------------------- -------------------------  (4)
%                                  P(y)                          P(y_d|k_x,k_n)
%
%where
%P(y_d|k_x,k_n) = Px(y_d|k_x) Cy(y_d|k_n) + Cx(y_d|k_x) Py(y_d|k_n)     (5)
%
%

% Compute probabilities for the speech model Sx
[Px_y, Cx_y] = compute_likelihood_marginals(data, gmm_x);

% Compute probabilities for the noise model Sn
[Pn_y, Cn_y] = compute_likelihood_marginals(data, gmm_n);


Py = 0;
p = 0;
for kx = 1:gmm_x.ncentres
    
    for kn = 1:gmm_n.ncentres
       
        % p1 = Px(y_d|k_x) Cn(y_d|k_n)
        p1 = Px_y(:,:,kx) .* Cn_y(:,:,kn);
        
        % Py_kx_kn = P(y_d|k_x,k_n)
        Py_kx_kn = p1 + Cx_y(:,:,kx) .* Pn_y(:,:,kn);
        
        % p2 = Px(k_x) Pn(k_n) \prod_d P(y_d|k_x,k_n) 
        p2 = gmm_x.priors(kx) * gmm_n.priors(kn) .* prod(Py_kx_kn,1);
       
        % Accumulate p2 .* p1 ./ Py_kx_kn
        p = p + bsxfun(@times, p1 ./ Py_kx_kn, p2);
        
        % Accumulate p2 for P(y)
        Py = Py + p2;
        
    end
    
end
mask = bsxfun(@times, p, 1./Py);
figure(1);
subplot(211); imagesc(data); axis xy;
subplot(212); imagesc(mask); axis xy;
mask(isnan(mask) | isinf(mask)) = 1;
logLikelihood = sum(log(Py));




%--------------------------------------------------------------------------
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


%--------------------------------------------------------------------------
function p = probability(x, x_mu, x_var)
invs = 1./sqrt(x_var);
z = invs.*(x-x_mu);
p = normpdf(z).*invs;


%--------------------------------------------------------------------------
function P = probabilityMat(X, X_mu, X_var)
Invs = 1./sqrt(X_var);
Z = (X-X_mu).*Invs;
P = normpdf(Z).*Invs;


%--------------------------------------------------------------------------
function p = cumulativeProb(x, x_mu, x_var)
z = (x-x_mu)./sqrt(x_var);
p = normcdf(z);


%--------------------------------------------------------------------------
function C= cumulativeProbMat(X, X_mu, X_var)
Z = (X-X_mu)./sqrt(X_var);
C = normcdf(Z);
