function C= cumulativeProbMat(X, X_mu, X_var)
Z = (X-X_mu)./sqrt(X_var);
C = normcdf(Z);
