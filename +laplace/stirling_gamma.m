function val = stirling_gamma(x, order)
% STIRLING_GAMMA Stable asymptotic Stirling expansion for ln(Gamma(x))
%
%   val = laplace.stirling_gamma(x)
%   val = laplace.stirling_gamma(x, order)
%
%   Computes ln(Gamma(x)) in logarithmic space to prevent overflow for
%   large arguments (up to x = 1e7 and beyond).
%
%   Formula:
%     ln Gamma(x) ~ 0.5*ln(2*pi) + (x - 0.5)*ln(x) - x
%                   + 1/(12*x) - 1/(360*x^3) + 1/(1260*x^5) - 1/(1680*x^7)
%
%   For small arguments (x < 15), falls back to MATLAB's exact gammaln(x).
%
%   Inputs:
%       x     - Scalar or array of positive real numbers
%       order - Truncation order of asymptotic terms (default: 3, max: 4)
%
%   Outputs:
%       val   - ln(Gamma(x)) evaluated with machine-precision accuracy.
%
%   Example:
%       val = laplace.stirling_gamma(1000); % ln(Gamma(1000))
%
%   Part of the Root-Free Laplace Inversion Toolbox.

if nargin < 2 || isempty(order)
    order = 3;
end

% Accelerated compiled MEX dispatch (Level 3 protection & speed)
persistent has_mex;
if isempty(has_mex)
    has_mex = (exist('laplace.stirling_gamma_mex', 'file') == 3) || ...
              (exist('stirling_gamma_mex', 'file') == 3);
end
if has_mex
    try
        val = laplace.stirling_gamma_mex(double(x), order);
        return;
    catch
        has_mex = false;
    end
end

val = zeros(size(x));

% Mask for small vs large values
small_mask = (x < 15.0);
large_mask = ~small_mask;

if any(small_mask(:))
    val(small_mask) = gammaln(x(small_mask));
end

if any(large_mask(:))
    xl = x(large_mask);
    v = 0.5 * log(2.0 * pi) + (xl - 0.5) .* log(xl) - xl;
    if order >= 1
        v = v + 1.0 ./ (12.0 .* xl);
    end
    if order >= 2
        v = v - 1.0 ./ (360.0 .* (xl .^ 3));
    end
    if order >= 3
        v = v + 1.0 ./ (1260.0 .* (xl .^ 5));
    end
    if order >= 4
        v = v - 1.0 ./ (1680.0 .* (xl .^ 7));
    end
    val(large_mask) = v;
end

end
