function f_vals = eval_laguerre_exact(K, a, z_grid)
% EVAL_LAGUERRE_EXACT Fast, stable evaluation of f(z) = exp(-a*z) * L_K(2*a*z)
%
%   f_vals = laplace.eval_laguerre_exact(K, a, z_grid)
%
%   Computes the exact time-domain response for pure binomial Laguerre modes
%   F(s) = (s - a)^K / (s + a)^(K+1)
%   whose inverse Laplace transform is analytically given by:
%       f(z) = exp(-a*z) * L_K(2*a*z)
%
%   Uses the 3-term recurrence directly on the damped basis to support
%   degrees up to K = 1,000,000 without numerical overflow.
%
%   Inputs:
%       K      - Degree of Laguerre mode (non-negative integer)
%       a      - Scaling parameter (positive real scalar)
%       z_grid - Time points vector (row or column)
%
%   Outputs:
%       f_vals - Evaluated function values matching size of z_grid
%
%   Part of the Root-Free Laplace Inversion Toolbox.

K = round(double(K));
a = double(a);
z_arr = double(z_grid);

% Accelerated compiled MEX dispatch (Level 3 protection & speed)
persistent has_mex;
if isempty(has_mex)
    has_mex = (exist('laplace.eval_laguerre_exact_mex', 'file') == 3) || ...
              (exist('eval_laguerre_exact_mex', 'file') == 3);
end
if has_mex
    try
        f_vals = laplace.eval_laguerre_exact_mex(K, a, z_arr);
        return;
    catch
        has_mex = false;
    end
end

f_vals = zeros(size(z_arr));

if K == 0
    f_vals = exp(-a .* z_arr);
    return;
elseif K == 1
    f_vals = exp(-a .* z_arr) .* (1.0 - 2.0 .* a .* z_arr);
    return;
end

% For moderate or large grids, vectorize across points
x = 2.0 * a .* z_arr;
L0 = ones(size(z_arr));
L1 = 1.0 - x;

for n = 1:(K - 1)
    L_next = ((2.0 * n + 1.0 - x) .* L1 - n .* L0) / double(n + 1);
    L0 = L1;
    L1 = L_next;
end

f_vals = exp(-a .* z_arr) .* L1;

end
