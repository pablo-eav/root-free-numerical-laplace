function [f_vals, info] = invert(varargin)
% INVERT High-level root-free numerical Laplace inversion entry point
%
%   f_vals = laplace.invert(num, den, z_grid)
%   f_vals = laplace.invert(sys, z_grid)
%   [f_vals, info] = laplace.invert(..., options)
%
%   Inverts rational Laplace transforms F(s) = num(s) / den(s) strictly
%   without root-finding. Supports systems from degree 1 to 1,000,000.
%
%   Inputs:
%       num     - Numerator polynomial (descending powers of s), FactorPoly, or scalar
%       den     - Denominator polynomial, FactorPoly, or PartialFractions
%       sys     - Linear time-invariant system (tf or zpk object from Control System Toolbox)
%       z_grid  - Vector of time points z >= 0 where f(z) is evaluated
%       options - (Optional) Struct with configuration fields:
%                   .engine    - 'Auto' (default), 'Stirling', 'Laguerre', 'TaylorAdaptive'
%                   .max_terms - Maximum expansion terms (default: 15000)
%                   .user_a    - Conformal scale override 'a' (default: auto)
%                   .tol       - Local tolerance for adaptive engines (default: 1e-3)
%
%   Outputs:
%       f_vals  - Computed time response f(z) matching dimensions of z_grid
%       info    - Diagnostic struct containing:
%                   .engine  - Name of engine utilized
%                   .terms   - Number of expansion terms used
%                   .a_param - Conformal scaling parameter 'a' (if applicable)
%                   .z_fuj   - Safe causal horizon z_fuj = 35 / R_fuj
%                   .dps     - Effective precision in bits (53 for float64)
%
%   Examples:
%       % 1. Standard rational transfer function: F(s) = 1 / (s^2 + 2*s + 2)
%       z = linspace(0, 10, 200);
%       f = laplace.invert([1], [1, 2, 2], z);
%
%       % 2. Factored massive cascade: F(s) = 1 / (s + 1)^100
%       B = laplace.FactorPoly('roots', -ones(100, 1));
%       f = laplace.invert(1, B, linspace(0, 150, 300));
%
%       % 3. Harmonic resonators: 5000 undamped resonant modes
%       pf = laplace.harmonic_resonators(5000);
%       f = laplace.invert([], pf, linspace(0, 0.05, 500));
%
%   Part of the Root-Free Laplace Inversion Toolbox.

if nargin < 2
    error('Insufficient arguments. Usage: laplace.invert(num, den, z_grid, [options]) or laplace.invert(sys, z_grid, [options])');
end

% Verify active trial or commercial license
laplace.LicenseManager.verify();

options = struct();

% Check if first argument is a tf or zpk object
first_arg = varargin{1};
if isa(first_arg, 'tf')
    [num_cell, den_cell] = tfdata(first_arg);
    num = num_cell{1};
    den = den_cell{1};
    z_grid = varargin{2};
    if nargin >= 3 && isstruct(varargin{3})
        options = varargin{3};
    end
elseif isa(first_arg, 'zpk')
    [z_cell, p_cell, k_val] = zpkdata(first_arg);
    z_roots = z_cell{1};
    p_roots = p_cell{1};
    
    % If poles are all real or simple, we can construct FactorPoly
    den = laplace.FactorPoly('roots', p_roots, 'gain', 1.0);
    if isempty(z_roots)
        num = k_val;
    else
        num = laplace.FactorPoly('roots', z_roots, 'gain', k_val);
    end
    z_grid = varargin{2};
    if nargin >= 3 && isstruct(varargin{3})
        options = varargin{3};
    end
else
    % Standard call: laplace.invert(num, den, z_grid, [options])
    num = varargin{1};
    den = varargin{2};
    if nargin < 3
        error('Time vector z_grid is required.');
    end
    z_grid = varargin{3};
    if nargin >= 4 && isstruct(varargin{4})
        options = varargin{4};
    end
end

% Validate time grid
if any(z_grid < 0)
    warning('Laplace inversion is causal; negative time values will evaluate to 0 or unphysical values.');
end

% Dispatch through EngineHybrid
[f_vals, info] = laplace.EngineHybrid.invert(num, den, z_grid, options);

end
