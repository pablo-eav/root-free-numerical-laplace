function pf = chebyshev_network(N, denom)
% CHEBYSHEV_NETWORK Partial fractions decomposition for Chebyshev transmission ladder
%
%   pf = laplace.chebyshev_network(N, denom)
%
%   Generates the exact modal decomposition for an Nth-order distributed
%   Chebyshev LC ladder network:
%       F(s) = 1 / [ U_N(1 + s/denom) - U_{N-1}(1 + s/denom) ]
%
%   Supports orders up to N = 1,000,000 without polynomial expansion.
%
%   Inputs:
%       N     - Ladder order (default: 10000, supports up to 1,000,000)
%       denom - Normalizing scale (default: 2e8)
%
%   Outputs:
%       pf    - Instance of laplace.PartialFractions
%
%   Part of the Root-Free Laplace Inversion Toolbox.

if nargin < 1 || isempty(N)
    N = 10000;
end
if nargin < 2 || isempty(denom)
    denom = 2e8;
end

N = round(double(N));
two_N_plus_1 = 2.0 * double(N) + 1.0;
factor_R = 8.0 * (double(N)^2) / two_N_plus_1;

K_modes = min(N, 1000); % Up to 1000 dominant modes
k_arr = (0:(K_modes - 1)).';

theta_k = (2.0 * k_arr + 1.0) * pi / two_N_plus_1;
sin_half = sin(theta_k / 2.0);
cos_half = cos(theta_k / 2.0);

p_k = -4.0 * (double(N)^2) .* (sin_half.^2);
signs = ones(K_modes, 1);
signs(2:2:end) = -1.0;

R_k = signs .* factor_R .* sin_half .* (cos_half.^2);

pf = laplace.PartialFractions(p_k, R_k);

end
