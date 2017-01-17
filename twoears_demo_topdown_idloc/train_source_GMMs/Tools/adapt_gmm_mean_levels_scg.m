function gmm_x_new = adapt_gmm_mean_levels_scg(data, gmm_x, gmm_n, iters, init_value)
% adapt_gmm_mean_levels_scg   Adapt the mean vectors of gmm_x by estimating an
% offset value which is added to the means to reduce the level mismatches w.r.t. the obseved data.
%
% 
%USAGE  
%  gmm_x_new = adapt_gmm_mean_levels_scg(data, gmm_x, gmm_n, iters)
%
%INPUT ARGUMENTS
%             data : Observed spectral data [nChannels x nFrames]
%            gmm_x : Target model to be adapted (Netlab-format GMM)
%            gmm_n : Interferer model (Netlab-format GMM)
%            iters : No of iterations (Optional. Default: 20).
%       init_value : Initial value of the offset level.
% 
%
%OUTPUT ARGUMENTS
%        gmm_x_new : Adapted target model (Netlab-format GMM)
%

STOP_CRIT_LL = 1e-4;

if nargin < 4
    iters = 20;
end

if nargin < 5
    % Initialise the mean offset.
    %init_value = 0;
    
    % Better initialisation??
    mask = estimate_mask_GMM2(data, gmm_x, gmm_n);  % Here, n is the target signal (speech) and x the interferer signal (noise)
    x_est = exp(data+eps) .* mask; % estimated noise
    x_est = log(max(mean(x_est,2))); % take the mean over time, and take the loudest frequency channel as noise estimation
    
    x_gmm = log(max(exp(gmm_x.priors * gmm_x.centres)));
    
    %init_value = mean(n_reliable) - mean(x_reliable)
    init_value = x_est - x_gmm;
    %
    % subplot(211), imagesc(data), axis xy
    % subplot(212), imagesc(mask), axis xy
end

% Compute the log-likelihood of the initial models
mean_offset_old = init_value;
[pn_y, Cn_y] = compute_likelihood_marginals(data, gmm_n);

% Optimize the mean offset using scaled conjugate gradient optimisation
% Optimisation options for NetLab
options = zeros(1, 18);
options(1) = 0;
options(2) = STOP_CRIT_LL;
options(3) = STOP_CRIT_LL;
options(9) = 0;
options(14) = iters;
mean_offset_new = scg(@logLikelihoodObjective, mean_offset_old, options, @logLikelihoodGradient, data, gmm_x, pn_y, Cn_y, gmm_n.priors);

% options = optimoptions('fminunc', 'Algorithm', 'trust-region', 'GradObj', 'on',  'Diagnostics', 'on', 'Display', 'iter-detailed');
% fun = @(x) logLikelihoodObjectiveGrad(x,  data, gmm_x, pn_y, Cn_y, gmm_n.priors);
% mean_offset_new = fminunc(fun, mean_offset_old, options);

%fprintf('[GMM mean adaptation] Initial offset value: %.4f, final offset value: %.4f\n', init_value, mean_offset_new);

gmm_x_new = gmm_x;
gmm_x_new.centres = gmm_x_new.centres + mean_offset_new;


%--------------------------------------------------------------------------
function [ll, g] = logLikelihoodObjectiveGrad(mean_offset, data, gmm_x, pn_y, Cn_y, pi_n)
ll = logLikelihoodObjective(mean_offset, data, gmm_x, pn_y, Cn_y, pi_n);
g = logLikelihoodGradient(mean_offset, data, gmm_x, pn_y, Cn_y, pi_n);


%--------------------------------------------------------------------------
function ll = logLikelihoodObjective(mean_offset, data, gmm_x, pn_y, Cn_y, pi_n)
gmm_x_new = gmm_x;
gmm_x_new.centres = gmm_x_new.centres + mean_offset;
[px_y, Cx_y] = compute_likelihood_marginals(data, gmm_x_new);
ll = -logLikeMaskingModel(px_y, Cx_y, gmm_x_new.priors, pn_y, Cn_y, pi_n);


%--------------------------------------------------------------------------
function g = logLikelihoodGradient(mean_offset, data, gmm_x, pn_y, Cn_y, pi_n)
gmm_x_new = gmm_x;
gmm_x_new.centres = gmm_x_new.centres + mean_offset;
[Xest, W, postProb] = Estep(data, gmm_x_new, pn_y, Cn_y, pi_n);
g = -computeGradient(mean_offset, data, gmm_x, Xest, W, postProb);


%--------------------------------------------------------------------------
function varargout = Estep(data, gmm_x_new, Pn_y, Cn_y, pi_n)

REG_VAL= 1e-10;

[Px_y, Cx_y] = compute_likelihood_marginals(data, gmm_x_new);

[nChannels, nFrames] = size(Px_y(:,:,1));
K_x= gmm_x_new.ncentres;
K_n= length(pi_n);

like = zeros(K_x * K_n, nFrames);
W = zeros(nChannels, nFrames, K_x, K_n);
Xest = zeros(nChannels, nFrames, K_x);
for kx= 1:K_x
    % Estimation of the target signal T-F bins assuming that all are masked
    % by the interferer signal
    Xest(:,:,kx)= mean_truncated_gaussian(data, gmm_x_new.centres(kx,:)', gmm_x_new.covars(kx,:)', Px_y(:,:,kx), Cx_y(:,:,kx));
    
    % p1 = Px(y_d|k_x) Cn(y_d|k_n)
    p1 = bsxfun(@times, Cn_y, Px_y(:,:,kx)) + REG_VAL;
    % p2 = Pn(y_d|k_n) Cx(y_d|k_x)
    p2 = bsxfun(@times, Pn_y, Cx_y(:,:,kx)) + REG_VAL;
     
    %p(y|kx,kn)= px(y|kx)Cn(n<=y|kn) + pn(y|kn)Cx(x<=y|kx)
    obsProb = p1 + p2;
    
    %p(y|kx,kn)*Px(k_x)*Pn(k_n)
    like(kx:K_x:K_x*K_n,:) = bsxfun(@times, squeeze(prod(obsProb))', gmm_x_new.priors(kx)*pi_n');
    
    %w_d^{kx,kn}= Px(y_d|k_x)*Cn(y_d|k_n)/p(y_d)
    w = p1 ./ obsProb;
    w(isnan(w) | isinf(w)) = 0.5;  
    W(:,:,kx,:) = w;
end

varargout{1} = Xest;
varargout{2} = W;
varargout{3} = bsxfun(@times, like, 1./sum(like));  % posterior probability, i.e. P(kx,kn|y_t)
if nargout > 4
    %Log-likelihood
    varargout{4} = sum(log(sum(like)));
end


%--------------------------------------------------------------------------
function g = computeGradient(mean_offset, data, gmm_x, Xest, W, postProb)

[nChannels, nFrames] = size(data);
K_x = gmm_x.ncentres;

Mu_x = repmat(reshape(gmm_x.centres', nChannels, 1, K_x), 1, nFrames, 1);  % size(Mu_x) = (nChannels, nFrames, K_x)
InvVar_x = repmat(reshape(1./gmm_x.covars', nChannels, 1, K_x), 1, nFrames, 1);  % size(InvVar_x) = (nChannels, nFrames, K_x)

% size(W)= (nChannels, nFrames, Kx, Kn) & size(Xest)= (nChannels, nFrames,KX)
%E_xest= sum_{i=1->nChannels} w^{kx,kn}_{t,i}*Xest^{kx}_{t,i}
Xest_weighted = bsxfun(@times, W, Xest);

% Compute the total energy per frame of data averaged by their reliability (1-W). 
% size(W)= (nChannels, nFrames, Kx, Kn) & size(data)= (nChannels, nFrames)
Data_weighted = bsxfun(@times, 1-W, data);

Level_diff = bsxfun(@minus, Xest_weighted+Data_weighted, Mu_x);
% Level_diff_var = bsxfun(@times, Level_diff, InvVar_x);
Level_diff_var = bsxfun(@times, Level_diff-mean_offset, InvVar_x);
E_diff = squeeze(sum(Level_diff_var));
E_diff_2d = reshape(permute(E_diff, [2 3 1]), [], nFrames);
E_diff_weighted = sum(reshape(postProb.*E_diff_2d, [], 1));

% % gamma_kx = sum_{k_n} sum_{t} P(kx,kn|y_t)
% gamma_kx_kn = sum(postProb, 2);
% gamma_kx = sum(reshape(gamma_kx_kn, K_x, []), 2);
% 
% % Energy of the inverse variances weighted by the posterior probabilities
% E_invvar = sum(1./gmm_x.covars');
% E_invar_weighted = sum(gamma_kx.*E_invvar(:));

% g = E_diff_weighted - mean_offset*E_invar_weighted;
g = E_diff_weighted;
