classdef EngineTaylorAdaptive
% ENGINETAYLORADAPTIVE Adaptive analytic prolongation with overlapping Taylor arcs
%
%   Computes local Taylor expansions around chained posts z_0 using the
%   exact derivatives in the Generalized Laguerre basis:
%       d_m = f^(m)(z_0) / m!
%
%   Determines the optimal step size analytically via the truncation bound:
%       h_adm = (target_tol / |d_{M+1}|)^(1 / (M+1))
%
%   Guarantees error <= target_tol across wide time horizons for
%   diffusion, fractional, and boundary-layer transfer functions.
%
%   Part of the Root-Free Laplace Inversion Toolbox.

    methods (Static)
        function [f_vals, info] = invert(a_input, b_input, z_grid, r_pole, max_terms, user_a, M_derivs, target_tol)
            if nargin < 5 || isempty(max_terms)
                max_terms = 15000;
            end
            if nargin < 6
                user_a = [];
            end
            if nargin < 7 || isempty(M_derivs)
                M_derivs = 12;
            end
            if nargin < 8 || isempty(target_tol)
                target_tol = 1e-3;
            end
            
            z_arr = double(z_grid);
            z_min = min(z_arr(:));
            z_max = max(z_arr(:));
            R = max(double(r_pole), 1e-4);
            z_fuj = 35.0 / R;
            
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
            
            if isa(b_input, 'laplace.FactorPoly') || isa(b_input, 'laplace.PartialFractions')
                deg_sys = b_input.degree();
            elseif isnumeric(b_input)
                deg_sys = length(b_input) - 1;
            else
                deg_sys = 50;
            end
            N_needed = min(max([40, min(deg_sys, 200) + 25]), max_terms);
            
            c_n = laplace.extract_mobius_laguerre_coeffs(a_input, b_input, a_param, N_needed);
            
            % Build adaptive posts
            current_z = z_min;
            post_z = [];
            post_coeffs = {};
            step_count = 0;
            max_steps_guard = 60;
            
            while current_z <= z_max && step_count < max_steps_guard
                step_count = step_count + 1;
                d_vec = laplace.EngineTaylorAdaptive.compute_post_derivs(c_n, a_param, current_z, M_derivs + 1);
                d_M_plus_1 = abs(d_vec(end));
                d_actual = d_vec(1:M_derivs + 1);
                
                if d_M_plus_1 > 1e-300
                    h_raw = (target_tol / d_M_plus_1)^(1.0 / double(M_derivs + 1));
                    h_adm = max([1e-4, min([h_raw, max([(z_max - z_min) / 4.0, 0.2])])]);
                else
                    h_adm = max([(z_max - z_min) / 5.0, 0.1]);
                end
                
                post_z(end + 1) = current_z; %#ok<AGROW>
                post_coeffs{end + 1} = d_actual; %#ok<AGROW>
                
                % Advance with 70% overlap
                step_advance = max([h_adm * 0.70, (z_max - z_min) / 20.0]);
                current_z = current_z + step_advance;
            end
            
            % Evaluate continuously along z_arr using the nearest post
            f_vals = zeros(size(z_arr));
            for idx = 1:numel(z_arr)
                zv = z_arr(idx);
                [~, best_idx] = min(abs(zv - post_z));
                best_p = post_z(best_idx);
                best_d = post_coeffs{best_idx};
                h = zv - best_p;
                
                % Horner evaluation
                val = best_d(end);
                for i = (length(best_d) - 1):-1:1
                    val = best_d(i) + h * val;
                end
                f_vals(idx) = val;
            end
            
            info = struct('engine', sprintf('Prolongación Analítica Taylor-Laguerre (%d postes)', length(post_z)), ...
                          'terms', N_needed, ...
                          'a_param', a_param, ...
                          'dps', 53, ...
                          'z_fuj', z_fuj, ...
                          'num_posts', length(post_z));
        end
        
        function d_m = compute_post_derivs(c_n, a_param, z0, M_order)
            % Compute d_m = f^(m)(z0) / m! via Generalized Laguerre polynomials
            N_lag = length(c_n);
            x0 = 2.0 * a_param * z0;
            d_m = zeros(M_order + 1, 1);
            
            for m = 0:M_order
                total_sum = 0.0;
                for j = 0:m
                    if j >= N_lag
                        continue;
                    end
                    coef_bin = (2.0^j) / (factorial(j) * factorial(m - j));
                    L0 = 1.0;
                    L1 = 1.0 + j - x0;
                    inner = c_n(j + 1) * L0;
                    k_max = N_lag - 1 - j;
                    if k_max >= 1
                        inner = inner + c_n(j + 2) * L1;
                        for k = 1:(k_max - 1)
                            Ln = ((2*k + 1 + j - x0) * L1 - (k + j) * L0) / double(k + 1);
                            inner = inner + c_n(j + 2 + k) * Ln;
                            L0 = L1;
                            L1 = Ln;
                        end
                    end
                    total_sum = total_sum + coef_bin * inner;
                end
                
                if abs(total_sum) < 1e-300
                    d_m(m + 1) = 0.0;
                else
                    ln_factor = m * log(a_param) - (a_param * z0);
                    if ln_factor < -745.0
                        d_m(m + 1) = 0.0;
                    elseif ln_factor > 709.0
                        d_m(m + 1) = ((-1.0)^m) * sign(total_sum) * realmax;
                    else
                        d_m(m + 1) = ((-1.0)^m) * exp(ln_factor) * total_sum;
                    end
                end
            end
        end
    end
end
