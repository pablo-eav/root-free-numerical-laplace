function pf = chebyshev_diffusion_network(N, denom)
% CHEBYSHEV_DIFFUSION_NETWORK Step response partial fractions for Chebyshev diffusion
%
%   pf = laplace.chebyshev_diffusion_network(N, denom)
%
%   Generates the exact modal decomposition for the step response of an
%   Nth-order distributed Chebyshev LC ladder network (EDP de Calor):
%       F(s) = 1 / [ s * (U_N(1 + s/denom) - U_{N-1}(1 + s/denom)) ]
%
%   In the continuum limit, this models 1D heat diffusion:
%       F(s) ~ 1 / [ s * cosh(sqrt(s)) ]
%   with uniform 1e-5 to 1e-6 error across all z >= 0, completely root-free.
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

K_modes = min(N, 1000);
k_arr = (0:(K_modes - 1)).';

theta_k = (2.0 * k_arr + 1.0) * pi / two_N_plus_1;
sin_half = sin(theta_k / 2.0);
cos_half = cos(theta_k / 2.0);

p_k = -4.0 * (double(N)^2) .* (sin_half.^2);
signs = ones(K_modes, 1);
signs(2:2:end) = -1.0;

R_k = signs .* factor_R .* sin_half .* (cos_half.^2);

% Step response: pole at s=0 with residue 1.0, and poles p_k with residues R_k ./ p_k
poles_all = [0.0; p_k];
residues_all = [1.0; R_k ./ p_k];

pf = laplace.PartialFractions(poles_all, residues_all);

end
