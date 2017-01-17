function gmm_x_new = adapt_gmm_mean_levels_vts_scg(data, gmm_x, gmm_n, iters, init_value)
% adapt_gmm_mean_levels_scg   Adapt the mean vectors of gmm_x by estimating an
% offset value which is added to the means to reduce the level mismatches w.r.t. the obseved data.
%
% 
%USAGE  
%  gmm_x_new = adapt_gmm_mean_levels_scg(data, gmm_x, gmm_n, iters, init_value)
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

STOP_CRIT_LL = 1e-6;

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

mean_offset_old = init_value;

% Optimize the mean offset using scaled conjugate gradient optimisation
% Optimisation options for NetLab
options = zeros(1, 18);
options(1) = 0;
options(2) = STOP_CRIT_LL;
options(3) = STOP_CRIT_LL;
options(9) = 0;
options(14) = iters;
mean_offset_new = scg(@logLikelihoodObjective, mean_offset_old, options, @logLikelihoodGradient, data, gmm_x, gmm_n);

% fprintf('[GMM mean adaptation] Initial offset value: %.4f, final offset value: %.4f\n', init_value, mean_offset_new);

gmm_x_new = gmm_x;
gmm_x_new.centres = gmm_x_new.centres + mean_offset_new;


%--------------------------------------------------------------------------
function ll = logLikelihoodObjective(mean_offset, data, gmm_x, gmm_n)
gmm_x_new = gmm_x;
gmm_x_new.centres = gmm_x_new.centres + mean_offset;
gmm_y = vtsAdaptation(gmm_x_new, gmm_n);

p_y = compute_gmm_likelihood(data, gmm_y);
like = bsxfun(@plus, log(p_y), log(gmm_y.priors'));

pmax = max(like);
ll = -sum(pmax + log(sum(exp(bsxfun(@minus, like, pmax)))));


%--------------------------------------------------------------------------
function gmm_y = vtsAdaptation(gmm_x, gmm_n)
nChannels = size(gmm_x.centres, 2);
Kx = gmm_x.ncentres;
Kn = gmm_n.ncentres;
Ky = Kx*Kn;

gmm_y = gmm_n;
gmm_y.ncentres = Ky;
gmm_y.priors = zeros(1, Ky);
gmm_y.centres = zeros(Ky, nChannels);
gmm_y.covars = zeros(Ky, nChannels);
Mn = gmm_n.centres;
Sn = gmm_n.covars;
Wn = gmm_n.priors;
for kx= 1:Kx
    mx = gmm_x.centres(kx,:);
    sx = gmm_x.covars(kx,:);
    wx = gmm_x.priors(kx);
    
    F0 = 1 + exp(bsxfun(@minus,Mn,mx));
    G0 = log(F0);
    Jx = 1./F0;
    Jn = 1-Jx;
    My = bsxfun(@plus, G0, mx);
    Sy = bsxfun(@times, Jx.^2, sx) + (Jn.^2 .* Sn);
    Wy = Wn*wx;
    
    gmm_y.priors((kx-1)*Kn+1:kx*Kn) = Wy;
    gmm_y.centres((kx-1)*Kn+1:kx*Kn,:) = My;
    gmm_y.covars((kx-1)*Kn+1:kx*Kn,:) = Sy;
end


%--------------------------------------------------------------------------
function like = compute_gmm_likelihood(data, gmm)
REG_VAL = 1e-10;
nFrames = size(data, 2);
K = gmm.ncentres;
like = zeros(K, nFrames);
for k = 1:K
    Mu = repmat(gmm.centres(k,:)', 1, nFrames);
    if strcmp(gmm.covar_type,'diag')
        InvS = repmat(1./sqrt(gmm.covars(k,:))', 1, nFrames);
    else
        InvS = repmat(1./sqrt(diag(gmm.covars(:,:,k))), 1, nFrames);
    end
    
    Z = InvS.*(data-Mu);
    like(k,:) = prod(normpdf(Z).*InvS) + REG_VAL;
end


%--------------------------------------------------------------------------
function g = logLikelihoodGradient(mean_offset, data, gmm_x, gmm_n)
gmm_x_new = gmm_x;
gmm_x_new.centres = gmm_x_new.centres + mean_offset;
gmm_y = vtsAdaptation(gmm_x_new, gmm_n);

Ky = gmm_y.ncentres;
nFrames = size(data, 2);

p_y = compute_gmm_likelihood(data, gmm_y);
like = bsxfun(@times, p_y, gmm_y.priors');
postProb = bsxfun(@times, like, 1./sum(like));

Delta = zeros(Ky, nFrames);
for k= 1:Ky
    d1 = bsxfun(@minus, data, gmm_y.centres(k,:)') - mean_offset;
    Delta(k,:) = sum(bsxfun(@times, d1, 1./gmm_y.covars(k,:)'));
end

S = postProb.*Delta;
g = -sum(S(:));
