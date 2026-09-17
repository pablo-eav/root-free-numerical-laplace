classdef EngineLaguerre
% ENGINELAGUERRE Orthogonal Möbius-Laguerre spectral inversion engine
%
%   Computes the inverse Laplace transform via:
%       f(z) = exp(-a*z) * sum_{n=0}^{N-1} c_n * L_n(2*a*z)
%
%   Guarantees L^2 convergence on [0, inf) with ZERO Taylor-hump growth
%   in standard IEEE float64 precision.
%
%   Part of the Root-Free Laplace Inversion Toolbox.

    methods (Static)
        function [f_vals, info] = invert(a_input, b_input, z_grid, r_pole, max_terms, user_a)
            if nargin < 5 || isempty(max_terms)
                max_terms = 15000;
            end
            if nargin < 6
                user_a = [];
            end
            
            z_arr = double(z_grid);
            z_min = min(z_arr(:));
            z_max = max(z_arr(:));
            R = max(double(r_pole), 1e-4);
            z_fuj = 35.0 / R;
            
            % O(1) detection for pure binomial Laguerre modes: (s - a)^K / (s + a)^(K+1)
            if isa(b_input, 'laplace.FactorPoly') && isa(a_input, 'laplace.FactorPoly') && ...
               isempty(b_input.quad_coeffs) && isempty(a_input.quad_coeffs)
                roots_A = a_input.roots;
                roots_B = b_input.roots;
                if (length(roots_A) + 1 == length(roots_B)) && ~isempty(roots_A)
                    if all(abs(roots_A - roots_A(1)) < 1e-12) && ...
                       all(abs(roots_B - roots_B(1)) < 1e-12) && ...
                       abs(roots_A(1) + roots_B(1)) < 1e-12 && roots_A(1) > 0
                        a_0 = roots_A(1);
                        K_order = length(roots_A);
                        gain_fac = a_input.gain / b_input.gain;
                        f_vals = gain_fac * laplace.eval_laguerre_exact(K_order, a_0, z_grid);
                        info = struct('engine', 'Möbius-Laguerre (Pure Binomial Exact)', ...
                                      'terms', K_order, ...
                                      'a_param', a_0, ...
                                      'dps', 53, ...
                                      'z_fuj', Inf);
                        return;
                    end
                end
            end
            
            % Tune conformal scale 'a'
            if ~isempty(user_a) && double(user_a) > 0
                a_param = double(user_a);
            else
                window_len = max(z_max - z_min, 1e-9);
                a_window = 25.0 / window_len;
                if R <= 2.0
                    a_param = max(1e-6, R);
                else
                    a_param = max(1.0, min(R / 2.0, a_window));
                end
            end
            
            % Determine required terms
            if isa(b_input, 'laplace.FactorPoly') || isa(b_input, 'laplace.PartialFractions')
                deg_sys = b_input.degree();
            elseif isnumeric(b_input)
                deg_sys = length(b_input) - 1;
            else
                deg_sys = 50;
            end
            
            N_needed = min(max([40, min(deg_sys, 200) + 25]), max_terms);
            
            % Extract orthogonal coefficients
            c_n = laplace.extract_mobius_laguerre_coeffs(a_input, b_input, a_param, N_needed);
            
            % Evaluate orthogonal series using Favard 3-term recurrence
            f_vals = zeros(size(z_arr));
            for i = 1:numel(z_arr)
                zv = z_arr(i);
                x = 2.0 * a_param * zv;
                L0 = 1.0;
                L1 = 1.0 - x;
                acc = c_n(1) * L0;
                if N_needed > 1
                    acc = acc + c_n(2) * L1;
                    for n = 1:(N_needed - 2)
                        Ln = ((2.0 * n + 1.0 - x) * L1 - n * L0) / double(n + 1);
                        acc = acc + c_n(n + 2) * Ln;
                        L0 = L1;
                        L1 = Ln;
                    end
                end
                f_vals(i) = exp(-a_param * zv) * acc;
            end
            
            info = struct('engine', 'Möbius-Laguerre (Float64)', ...
                          'terms', N_needed, ...
                          'a_param', a_param, ...
                          'dps', 53, ...
                          'z_fuj', z_fuj);
        end
    end
end
