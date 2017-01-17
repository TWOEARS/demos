function mix= gmm_init(dim, ncentres, covar_type)

if ncentres < 1
    error('Number of centres must be greater than zero')
end

mix.type= 'gmm';
mix.nin= dim;
mix.ncentres= ncentres;

vartypes = {'spherical', 'diag', 'full'};
if sum(strcmp(covar_type, vartypes)) == 0
    error('Undefined covariance type')
else
    mix.covar_type= covar_type;
end

% Initialise priors to be equal and summing to one
mix.priors= ones(1,mix.ncentres) ./ mix.ncentres;

% Initialise centres
mix.centres= randn(mix.ncentres, mix.nin);

% Initialise all the variances to unity
switch mix.covar_type    
    case 'spherical'
        mix.covars= ones(1, mix.ncentres);
    case 'diag'
        % Store diagonals of covariance matrices as rows in a matrix
        mix.covars= ones(mix.ncentres, mix.nin);
    case 'full'
        % Store covariance matrices in a row vector of matrices
        mix.covars= repmat(eye(mix.nin), [1 1 mix.ncentres]);
end
