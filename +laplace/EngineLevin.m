classdef EngineLevin
% ENGINELEVIN Inversión Universal de Laplace Root-Free vía Levin AR(2) + Laurent
%
%   Implementa el algoritmo de inversión analítica libre de raíces (Root-Free):
%       1. División sintética formal O(K) de coeficientes A(s)/B(s) para
%          extraer la serie de Laurent {c_m}, SIN calcular raíces ni polos.
%       2. Estimación de cota espectral superior O(K) de Fujiwara R_pole.
%       3. Clasificador autorregresivo Prony AR(2) para selección óptima
%          de la variante de Levin ('u' o 't').
%       4. Evaluación en dominio dual:
%          - Tramo seguro [0, z_fuj]: Serie de potencias directa (Horner).
%          - Tramo acelerado (z_fuj, z_max]: Transformación no lineal de Levin
%            para neutralizar la cancelación catastrófica sin cálculo de polos.
%
%   Referencia:
%       P. E. Aballe Vázquez, "Clasificador de Fracciones Racionales Propias:
%       Aplicación de las Transformaciones No Lineales de Levin a la Serie
%       de Inversión de Laplace", 2026.
%
%   Parte de la Root-Free Laplace Inversion Toolbox.

    methods (Static)
        function [f_vals, info] = invert(a_input, b_input, z_grid, options)
            if nargin < 4 || isempty(options)
                options = struct();
            end
            
            % Parámetros de configuración
            if isfield(options, 'kl_order')
                kl_order = options.kl_order;
            else
                kl_order = 10;
            end
            if isfield(options, 'max_terms')
                max_terms = options.max_terms;
            else
                max_terms = 180;
            end
            if isfield(options, 'variant')
                user_variant = options.variant;
            else
                user_variant = 'auto';
            end
            
            z_arr = double(z_grid);
            M_pts = numel(z_arr);
            f_vals = zeros(size(z_arr));
            
            % 1. Extraer coeficientes polinomiales A(s) y B(s)
            [a_poly, b_poly] = laplace.EngineLevin.extract_poly_arrays(a_input, b_input);
            
            % 2. Análisis algebraico y Cota de Fujiwara O(K) sin raíces
            [r_norm, b_norm, r_pole, rel_deg] = laplace.EngineLevin.analyze_fraction(a_poly, b_poly);
            z_fuj = 35.0 / max(r_pole, 1e-4);
            
            % 3. Extracción de serie de Laurent mediante división sintética O(K*N)
            N_terms = max(max_terms, kl_order + 15);
            c_coeffs = laplace.EngineLevin.compute_laurent_recurrence(r_norm, b_norm, N_terms);
            
            % 4. Clasificador espectral AR(2) (Prony)
            [frac_type, auto_variant, r_prony, alpha_prony] = laplace.EngineLevin.classify_ar2(c_coeffs);
            
            if strcmp(user_variant, 'auto')
                variant = auto_variant;
            else
                variant = user_variant;
            end
            
            % 5. Factores alpha_n = c_{n+1} / n! en escala logarítmica segura
            alphas = laplace.EngineLevin.compute_alphas(c_coeffs);
            
            for i = 1:M_pts
                zv = z_arr(i);
                if zv <= 1e-15
                    f_vals(i) = alphas(1);
                    continue;
                end
                
                % Lazo de decisión: si zv <= z_fuj, Horner es exacto y ultra-estable
                if zv <= z_fuj
                    % Horner directo
                    val = alphas(N_terms);
                    for k = (N_terms - 1):-1:1
                        val = alphas(k) + zv * val;
                    end
                else
                    % Aceleración no lineal de Levin
                    val = laplace.EngineLevin.eval_levin_point(alphas, zv, variant, kl_order);
                end
                
                f_vals(i) = val;
            end
            
            info = struct('engine', sprintf('Levin AR(2) [%s, var: %s]', frac_type, variant), ...
                          'terms', N_terms, ...
                          'dps', 53, ...
                          'z_fuj', z_fuj, ...
                          'r_pole', r_pole, ...
                          'r_prony', r_prony, ...
                          'alpha_prony', alpha_prony, ...
                          'variant', variant, ...
                          'frac_type', frac_type);
        end
        
        function [a_poly, b_poly] = extract_poly_arrays(a_input, b_input)
            % Convierte entradas (vectores, FactorPoly) a vectores polinomiales
            if isa(b_input, 'laplace.FactorPoly')
                b_poly = b_input.to_poly();
            elseif isnumeric(b_input)
                b_poly = double(b_input(:).');
            else
                b_poly = [1, 1];
            end
            
            if isempty(a_input)
                a_poly = 1.0;
            elseif isa(a_input, 'laplace.FactorPoly')
                a_poly = a_input.to_poly();
            elseif isnumeric(a_input)
                a_poly = double(a_input(:).');
            else
                a_poly = 1.0;
            end
        end
        
        function [r_norm, b_norm, r_pole, rel_deg] = analyze_fraction(a_poly, b_poly)
            % Normalización formal O(K) sin raíces
            idx_b = find(abs(b_poly) > 1e-300, 1, 'first');
            if isempty(idx_b)
                error('El denominador B(s) no puede ser idénticamente nulo.');
            end
            b_clean = b_poly(idx_b:end);
            
            idx_a = find(abs(a_poly) > 1e-300, 1, 'first');
            if isempty(idx_a)
                a_clean = 0.0;
            else
                a_clean = a_poly(idx_a:end);
            end
            
            deg_b = length(b_clean) - 1;
            deg_a = length(a_clean) - 1;
            
            if deg_a >= deg_b && any(a_clean ~= 0)
                error('La fracción racional debe ser estrictamente propia: deg(A) < deg(B).');
            end
            
            rel_deg = max(1, deg_b - deg_a);
            K = deg_b;
            
            % Alinear numerador r_padded de longitud K
            r_padded = zeros(1, K);
            if any(a_clean ~= 0)
                len_a = length(a_clean);
                r_padded((K - len_a + 1):K) = a_clean;
            end
            
            bk = b_clean(1);
            b_norm = b_clean(2:end) / bk;
            r_norm = r_padded / bk;
            
            % Cota espectral de Fujiwara O(K)
            [r_pole, ~] = laplace.fujiwara_bound(b_clean);
        end
        
        function c_out = compute_laurent_recurrence(r_norm, b_norm, max_terms)
            % División sintética general recursiva: C_m = R_m - sum(B_j * C_{m-j})
            K = length(b_norm);
            len_r = length(r_norm);
            c_out = zeros(max_terms, 1);
            
            for m = 1:max_terms
                idx = m;
                if idx <= len_r
                    rm = r_norm(idx);
                else
                    rm = 0.0;
                end
                
                L = min(idx - 1, K);
                s = 0.0;
                for j = 1:L
                    s = s + b_norm(j) * c_out(idx - j);
                end
                c_out(idx) = rm - s;
            end
        end
        
        function [frac_type, levin_variant, r_prony, alpha_prony] = classify_ar2(c_coeffs)
            % Modelo autorregresivo Prony AR(2) sobre la cola asintótica de c_m
            M = length(c_coeffs);
            w = min(20, M);
            tail = c_coeffs((end - w + 1):end);
            
            rows = [];
            y_vals = [];
            for k = length(tail):-1:3
                rows(end + 1, :) = [tail(k - 1), tail(k - 2)]; %#ok<AGROW>
                y_vals(end + 1, 1) = -tail(k); %#ok<AGROW>
            end
            
            if size(rows, 1) < 2
                frac_type = 'real_monotono';
                levin_variant = 'u';
                r_prony = 1.0;
                alpha_prony = 1.0;
                return;
            end
            
            % Ajuste de mínimos cuadrados para gamma1, gamma2
            gamma = rows \ y_vals;
            gamma1 = gamma(1);
            gamma2 = gamma(2);
            delta = gamma1^2 - 4.0 * gamma2;
            
            if delta < 0
                % Par complejo conjugado dominante
                frac_type = 'complejos_dominantes';
                levin_variant = 't';
                r_prony = sqrt(abs(gamma2));
                alpha_prony = -gamma1 / 2.0;
            else
                % Polos reales
                r1 = (-gamma1 + sqrt(delta)) / 2.0;
                r2 = (-gamma1 - sqrt(delta)) / 2.0;
                if abs(r1) >= abs(r2)
                    r_prony = abs(r1);
                    alpha_prony = r1;
                else
                    r_prony = abs(r2);
                    alpha_prony = r2;
                end
                
                if alpha_prony < 0
                    frac_type = 'real_alternante';
                    levin_variant = 't';
                else
                    frac_type = 'real_monotono';
                    levin_variant = 'u';
                end
            end
        end
        
        function alphas = compute_alphas(c_coeffs)
            % Calcula alpha_n = c_{n+1} / n! en espacio logarítmico seguro
            N = length(c_coeffs);
            alphas = zeros(N, 1);
            for n = 0:(N - 1)
                cn = c_coeffs(n + 1);
                if abs(cn) < 1e-300
                    alphas(n + 1) = 0.0;
                    continue;
                end
                
                ln_fact = gammaln(n + 1); % ln(n!)
                ln_val = log(abs(cn)) - ln_fact;
                
                if ln_val > 709.0
                    alphas(n + 1) = sign(cn) * realmax;
                elseif ln_val < -745.0
                    alphas(n + 1) = 0.0;
                else
                    alphas(n + 1) = sign(cn) * exp(ln_val);
                end
            end
        end
        
        function val = eval_levin_point(alphas, z_val, variant, kl)
            % Evalúa la serie con aceleración de Levin (variante u o t)
            nz_idx = find(abs(alphas) > 1e-300);
            K_active = length(nz_idx);
            
            if K_active < kl + 2
                % Menos términos que el orden de Levin: evaluación estándar
                val = alphas(end);
                for k = (length(alphas) - 1):-1:1
                    val = alphas(k) + z_val * val;
                end
                return;
            end
            
            log_z = log(z_val);
            terms = zeros(K_active, 1);
            for k = 1:K_active
                n = nz_idx(k) - 1;
                ln_term = log(abs(alphas(nz_idx(k)))) + n * log_z;
                if ln_term > 700.0
                    terms(k) = sign(alphas(nz_idx(k))) * realmax;
                elseif ln_term < -700.0
                    terms(k) = 0.0;
                else
                    terms(k) = sign(alphas(nz_idx(k))) * exp(ln_term);
                end
            end
            
            S = cumsum(terms);
            [~, max_idx] = max(abs(terms));
            n0 = max(1, max_idx - floor(kl / 2));
            n0 = min(n0, K_active - kl);
            
            sub_S = S(n0 : (n0 + kl));
            sub_terms = terms(n0 : (n0 + kl));
            sub_idx = nz_idx(n0 : (n0 + kl)) - 1;
            
            if strcmp(variant, 'u')
                R = (sub_idx + 1.0) .* sub_terms;
            else
                R = sub_terms;
            end
            
            if any(abs(R) < 1e-250) || any(isnan(R)) || any(isinf(R))
                val = S(end);
                return;
            end
            
            num = 0.0;
            den = 0.0;
            comb = 1.0;
            for j = 0:kl
                if mod(j, 2) == 0
                    sign_j = 1.0;
                else
                    sign_j = -1.0;
                end
                scale = ((j + 1.0) / (kl + 1.0))^(kl - 1);
                wj = (sign_j * comb * scale) / R(j + 1);
                
                num = num + wj * sub_S(j + 1);
                den = den + wj;
                
                if j < kl
                    comb = comb * double(kl - j) / double(j + 1);
                end
            end
            
            if abs(den) < 1e-150 || isnan(den) || isinf(den)
                val = S(end);
            else
                val = num / den;
            end
        end
    end
end
