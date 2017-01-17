function gmm_x_new = adapt_gmm_mean_levels_em(data, gmm_x, gmm_n, iters, init_value)
% adapt_gmm_mean_levels_em   Adapt the mean vectors of gmm_x by estimating an
% offset value which is added to the means to reduce the level mismatches w.r.t. the obseved data.
%
% 
%USAGE  
%  gmm_x_new = adapt_gmm_mean_levels(data, gmm_x, gmm_n, iters)
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
DO_BACKOFF = true;

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
gmm_x_new = gmm_x;
gmm_x_new.centres = gmm_x_new.centres + mean_offset_old;
[px_y, Cx_y] = compute_likelihood_marginals(data, gmm_x_new);
[pn_y, Cn_y] = compute_likelihood_marginals(data, gmm_n);
ll_old = logLikeMaskingModel(px_y, Cx_y, gmm_x_new.priors, pn_y, Cn_y, gmm_n.priors);
disp(['It 0: ' num2str(ll_old)]);

% Main loop of the EM algorithm
difLL= Inf;
i= 1;
while i<=iters && difLL>STOP_CRIT_LL   
    [Xest, W, postProb] = Estep(data, gmm_x_new, pn_y, Cn_y, gmm_n.priors);
    mean_offset_new = Mstep(data, gmm_x, Xest, W, postProb);
    
    gmm_x_new.centres = gmm_x.centres + mean_offset_new;
    [px_y, Cx_y] = compute_likelihood_marginals(data, gmm_x_new);
    ll_new = logLikeMaskingModel(px_y, Cx_y, gmm_x_new.priors, pn_y, Cn_y, gmm_n.priors);
    
    if ll_new<ll_old && DO_BACKOFF
        disp(['Backoff 1: ' num2str(ll_new) ' vs. ' num2str(ll_old)]);
        [mean_offset_new, ll_new]= backoff(data, gmm_x, mean_offset_old, mean_offset_new, pn_y, Cn_y, gmm_n.priors, ll_old);
    end

    disp(['It ' num2str(i) ': ' num2str(ll_new)]);
    mean_offset_old = mean_offset_new;
    gmm_x_new.centres = gmm_x.centres + mean_offset_new;
    difLL = abs(ll_new-ll_old);    
    ll_old = ll_new;
    i = i+1;
end

fprintf('[GMM mean adaptation] Initial offset value: %.4f, final offset value: %.4f\n', init_value, mean_offset_new);

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
function mean_offset = Mstep(data, gmm_x, Xest, W, postProb)

[nChannels, nFrames] = size(data);
K_x = gmm_x.ncentres;

Mu_x = repmat(reshape(gmm_x.centres', nChannels, 1, K_x), 1, nFrames, 1);  % size(Mu_x) = (nChannels, nFrames, K_x)
InvVar_x = repmat(reshape(1./gmm_x.covars', nChannels, 1, K_x), 1, nFrames, 1);  % size(InvVar_x) = (nChannels, nFrames, K_x)

% Compute the total energy per frame of Xest averaged by their reliability W. 
% size(W)= (nChannels, nFrames, Kx, Kn) & size(Xest)= (nChannels, nFrames,KX)
%E_xest= sum_{i=1->nChannels} w^{kx,kn}_{t,i}*Xest^{kx}_{t,i}
Xest_weighted = bsxfun(@times, W, Xest);
% Xest_weighted_var = bsxfun(@times, Xest_weighted, InvVar_x);
% % Sum across all channels
% E_xest = sum(Xest_weighted_var);

% Compute the total energy per frame of data averaged by their reliability (1-W). 
% size(W)= (nChannels, nFrames, Kx, Kn) & size(data)= (nChannels, nFrames)
Data_weighted = bsxfun(@times, 1-W, data);
% Data_weighted_var = bsxfun(@times, Data_weighted, InvVar_x);
% E_data = sum(Data_weighted_var);

% % Compute the Total energy of Xest plus data weighted by the posterior
% % probabilities
% E_xest_data = squeeze(E_xest + E_data);
% E_xest_data_2d = reshape(permute(E_xest_data, [2 3 1]), [], nFrames);  % size(E_xest_data_2d) = (K_x*K_n, nFrames)
% % Multiply by the posterior prob. and sum all the elements
% E_xest_data_weighted = sum(reshape(postProb.*E_xest_data_2d, [], 1));

% Compute the energy of the GMM means weighted by the posterior
% probabilities
% gamma_kx = sum_{k_n} sum_{t} P(kx,kn|y_t)
gamma_kx_kn = sum(postProb, 2);
gamma_kx = sum(reshape(gamma_kx_kn, K_x, []), 2);
% E_means = sum(gmm_x.centres' ./ gmm_x.covars');
% E_means_weighted = sum(gamma_kx.*E_means(:));

Level_diff = bsxfun(@minus, Xest_weighted+Data_weighted, Mu_x);
Level_diff_var = bsxfun(@times, Level_diff, InvVar_x);
E_diff = squeeze(sum(Level_diff_var));
E_diff_2d = reshape(permute(E_diff, [2 3 1]), [], nFrames);
E_diff_weighted = sum(reshape(postProb.*E_diff_2d, [], 1));

% Energy of the inverse variances weighted by the posterior probabilities
E_invvar = sum(1./gmm_x.covars');
E_invar_weighted = sum(gamma_kx.*E_invvar(:));

%mean_offset = (E_xest_data_weighted-E_means_weighted)/E_invar_weighted;
mean_offset = E_diff_weighted/E_invar_weighted;


%--------------------------------------------------------------------------
function [mean_offset_backoff, ll_new] = backoff(data, gmm_x, mean_offset_old, mean_offset_new, pn_y, Cn_y, pi_n, ll_old)

MAX_ITERS = 10;
ALPHA = 0.5;

nu = 1;
k = 1;
ll_new = -Inf;
while ll_new<ll_old && k<=MAX_ITERS
    %Interpolate the old and new mean_offset values
    nu = nu*ALPHA;
    mean_offset_backoff =  nu*mean_offset_new  + (1-nu)*mean_offset_old;
    
    %Recompute the log-likelihood of the observed data
    gmm_x_new = gmm_x;
    gmm_x_new.centres = gmm_x_new.centres + mean_offset_backoff;
    [px_y, Cx_y] = compute_likelihood_marginals(data, gmm_x_new);    
    ll_new = logLikeMaskingModel(px_y, Cx_y, gmm_x_new.priors, pn_y, Cn_y, pi_n);
    disp(['Backoff ' num2str(k) ': ' num2str(ll_new) ' vs. ' num2str(ll_old)]);
    
    k= k+1;
end

if k>MAX_ITERS && ll_new<ll_old
    mean_offset_backoff = mean_offset_old;
    ll_new = ll_old;
end
