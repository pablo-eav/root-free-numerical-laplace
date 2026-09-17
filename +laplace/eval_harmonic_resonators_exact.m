function f_vals = eval_harmonic_resonators_exact(N, z_grid)
% EVAL_HARMONIC_RESONATORS_EXACT Analytical Dirichlet closed-form solution
%
%   f_vals = laplace.eval_harmonic_resonators_exact(N, z_grid)
%
%   Evaluates f(z) = sum_{k=1}^N sin(k*z) in O(1) time per point using
%   the exact trigonometric Dirichlet kernel identity:
%
%       f(z) = sin(N * z / 2) * sin((N + 1) * z / 2) / sin(z / 2)
%
%   With l'Hopital limit handling at z = 2 * pi * m:
%       f(2*pi*m) = 0.
%
%   Inputs:
%       N      - Number of harmonics (positive integer)
%       z_grid - Evaluation time points
%
%   Outputs:
%       f_vals - Exact analytical values matching size of z_grid
%
%   Part of the Root-Free Laplace Inversion Toolbox.

N = round(double(N));
z_arr = double(z_grid);
f_vals = zeros(size(z_arr));

half_z = z_arr / 2.0;
sin_half = sin(half_z);

% Mask for points where sin(z/2) != 0
nz_mask = abs(sin_half) >= 1e-12;

f_vals(nz_mask) = sin(N .* half_z(nz_mask)) .* sin((N + 1) .* half_z(nz_mask)) ./ sin_half(nz_mask);
f_vals(~nz_mask) = 0.0; % Closed form limit at multiples of 2*pi

end
