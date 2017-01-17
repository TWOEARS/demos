function P = probabilityMat(X, X_mu, X_var)
Invs = 1./sqrt(X_var);
Z = (X-X_mu).*Invs;
P = normpdf(Z).*Invs;
