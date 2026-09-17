function res = eval_chebyshev_ladder_exact(N, denom, z_grid)
% EVAL_CHEBYSHEV_LADDER_EXACT Exact analytical impulse response for Chebyshev ladder
%
%   res = laplace.eval_chebyshev_ladder_exact(N, denom, z_grid)
%
%   Evaluates:
%       f(z) = sum_{k=0}^{K-1} R_k * exp(p_k * z)
%
%   Inputs:
%       N      - Ladder order
%       denom  - Normalizing denominator (default: 2e8)
%       z_grid - Evaluation time points
%
%   Outputs:
%       res    - Exact analytical values
%
%   Part of the Root-Free Laplace Inversion Toolbox.

if nargin < 2 || isempty(denom)
    denom = 2e8;
end

pf = laplace.chebyshev_network(N, denom);
res = pf.evaluate_modal(z_grid);

end
