classdef EngineStirling
% ENGINESTIRLING Inversion via Laurent series with Stirling log-space scaling
%
%   Computes the inverse Laplace transform via:
%       f(z) = z^(delta - 1) * sum_{n=0}^{N-1} alpha_n * z^n
%
%   where alpha_n = c_n / Gamma(delta + n) is evaluated in logarithmic space
%   using laplace.stirling_gamma to completely avoid float64 overflow and
%   Taylor-hump roundoff errors.
%
%   Part of the Root-Free Laplace Inversion Toolbox.

    methods (Static)
        function [f_vals, info] = invert(a_input, b_input, z_grid, r_pole, max_terms)
            if nargin < 5 || isempty(max_terms)
                max_terms = 150;
            end
            
            z_arr = double(z_grid);
            f_vals = zeros(size(z_arr));
            
            % O(1) detection for pure single pole cascades: A / (s + a)^K
            if isa(b_input, 'laplace.FactorPoly') && ~isempty(b_input.roots) && isempty(b_input.quad_coeffs)
                deg_B = b_input.degree();
                if isa(a_input, 'laplace.FactorPoly')
                    deg_A = a_input.degree();
                elseif isnumeric(a_input)
                    deg_A = max(0, length(a_input) - 1);
                else
                    deg_A = 0;
                end
                
                if deg_A == 0
                    r0 = b_input.roots(1);
                    if all(abs(b_input.roots - r0) < 1e-12)
                        if isa(a_input, 'laplace.FactorPoly')
                            gain_A = a_input.gain;
                        elseif isnumeric(a_input) && ~isempty(a_input)
                            gain_A = double(a_input(1));
                        else
                            gain_A = 1.0;
                        end
                        gain_B = b_input.gain;
                        K_lead = gain_A / gain_B;
                        K = deg_B;
                        pole = r0; % Root is r0, pole is at r0 (factor is s - r0)
                        
                        ln_gamma_K = laplace.stirling_gamma(double(K));
                        
                        for i = 1:numel(z_arr)
                            zv = z_arr(i);
                            if zv <= 0.0
                                if K == 1
                                    f_vals(i) = K_lead;
                                else
                                    f_vals(i) = 0.0;
                                end
                            else
                                ln_f = log(abs(K_lead)) + (K - 1) * log(zv) - ln_gamma_K + pole * zv;
                                if ln_f < -745.0
                                    f_vals(i) = 0.0;
                                elseif ln_f > 709.0
                                    f_vals(i) = sign(K_lead) * realmax;
                                else
                                    f_vals(i) = sign(K_lead) * exp(ln_f);
                                end
                            end
                        end
                        
                        info = struct('engine', 'Laurent-Stirling (Pure Cascade)', ...
                                      'terms', K, ...
                                      'dps', 53, ...
                                      'rel_deg', K);
                        return;
                    end
                end
            end
            
            scale_R = max(double(r_pole), 1.0);
            log_S = log(scale_R);
            
            [c_k, rel_deg] = laplace.extract_unified_laurent_coeffs(a_input, b_input, max_terms, scale_R);
            actual_terms = length(c_k);
            alphas = zeros(actual_terms, 1);
            
            for n = 0:(actual_terms - 1)
                cn = c_k(n + 1);
                if abs(cn) > 1e-300
                    m = rel_deg - 1 + n;
                    ln_fact = laplace.stirling_gamma(m + 1.0);
                    ln_alpha = log(abs(cn)) + (m + 1) * log_S - ln_fact;
                    if ln_alpha > 709.0
                        alphas(n + 1) = sign(cn) * realmax;
                    elseif ln_alpha < -745.0
                        alphas(n + 1) = 0.0;
                    else
                        alphas(n + 1) = sign(cn) * exp(ln_alpha);
                    end
                end
            end
            
            shift = rel_deg - 1;
            for j = 1:numel(z_arr)
                zv = z_arr(j);
                if zv == 0.0
                    if shift == 0
                        f_vals(j) = alphas(1);
                    else
                        f_vals(j) = 0.0;
                    end
                    continue;
                end
                
                % Horner evaluation: val = sum(alphas[i] * zv^i)
                val = alphas(end);
                for i = (actual_terms - 1):-1:1
                    val = val * zv + alphas(i);
                end
                
                if shift > 0
                    ln_pow = shift * log(zv);
                    if ln_pow < -700.0
                        f_vals(j) = 0.0;
                    else
                        f_vals(j) = val * exp(ln_pow);
                    end
                else
                    f_vals(j) = val;
                end
            end
            
            info = struct('engine', 'Laurent-Stirling (Float64)', ...
                          'terms', actual_terms, ...
                          'dps', 53, ...
                          'rel_deg', rel_deg);
        end
    end
end
