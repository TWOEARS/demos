function trunc_mean = mean_truncated_gaussian(Y, mean_x, var_x, Px_y, Cx_y)
% truncated_mean= Integral_{-Inf->Y} x p(x) dx = mean + sigma*P(z)/C(z), where
% z is the standardized data
Q = Px_y./Cx_y;
Q(isnan(Q) | isinf(Q)) = 0;
%Q is multiplied by var_x instead of sqrt(var_x) because Px_y is the probability for the
%original data. 
trunc_mean = bsxfun(@plus, bsxfun(@times, -Q, var_x), mean_x);
trunc_mean = min(trunc_mean, Y);
