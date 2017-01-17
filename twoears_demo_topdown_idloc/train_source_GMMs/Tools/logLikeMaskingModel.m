function ll = logLikeMaskingModel(px_y, Cx_y, pi_x, pn_y, Cn_y, pi_n)

REG_VAL = 1e-10;

Kx = length(pi_x);
Kn = length(pi_n);
frames = size(px_y, 2);

log_pix = log(pi_x);
log_pin = log(pi_n);
% normP = zeros(1, frames);
like = zeros(Kx*Kn, frames);
for k= 1:Kn
    % -- Compute the posteriors P(kx,kn|y) for every pair of Gaussians (kx,kn)
    %p(y|kx,kn)= px(y|kx)Cn(n<=y|kn) + pn(y|kn)Cx(x<=y|kx)
    p1 = bsxfun(@times, px_y, Cn_y(:,:,k)) + REG_VAL;
    p2 = bsxfun(@times, Cx_y, pn_y(:,:,k)) + REG_VAL;
%     obsProb=  p1 + p2;
%     like= bsxfun(@times, prod(obsProb), reshape(pi_n(k)*pi_x,1,1,[]));
%     normP= normP + sum(like,3);
    obsProb=  log(p1 + p2);
    like((k-1)*Kx+1:k*Kx,:) = bsxfun(@plus, squeeze(sum(obsProb))', log_pix'+log_pin(k));    
end
% ll = sum(log(normP));

pmax = max(like);
ll = sum(pmax + log(sum(exp(bsxfun(@minus, like, pmax)))));
