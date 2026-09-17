function Ln = eval_laguerre(n, x)
% EVAL_LAGUERRE Vectorized evaluation of ordinary Laguerre polynomial L_n(x)
%
%   Ln = laplace.eval_laguerre(n, x)
%
%   Evaluates L_n(x) using Favard's three-term stable recurrence relation:
%       L_0(x) = 1
%       L_1(x) = 1 - x
%       (k + 1)*L_{k+1}(x) = (2*k + 1 - x)*L_k(x) - k*L_{k-1}(x)
%
%   Inputs:
%       n - Polynomial degree (non-negative integer)
%       x - Evaluation points (scalar, vector, or matrix)
%
%   Outputs:
%       Ln - Value of L_n(x) matching the dimensions of x.
%
%   Example:
%       y = laplace.eval_laguerre(5, linspace(0, 10, 100));
%
%   Part of the Root-Free Laplace Inversion Toolbox.

n = round(double(n));
if n < 0
    error('Laguerre degree n must be non-negative.');
end

% Accelerated compiled MEX dispatch (Level 3 protection & speed)
persistent has_mex;
if isempty(has_mex)
    has_mex = (exist('laplace.eval_laguerre_mex', 'file') == 3) || ...
              (exist('eval_laguerre_mex', 'file') == 3);
end
if has_mex
    try
        Ln = laplace.eval_laguerre_mex(n, x);
        return;
    catch
        has_mex = false;
    end
end

if n == 0
    Ln = ones(size(x));
    return;
elseif n == 1
    Ln = 1.0 - double(x);
    return;
end

L0 = ones(size(x));
L1 = 1.0 - double(x);

for k = 1:(n - 1)
    L_next = ((2.0 * k + 1.0 - x) .* L1 - k .* L0) / double(k + 1);
    L0 = L1;
    L1 = L_next;
end

Ln = L1;

end
