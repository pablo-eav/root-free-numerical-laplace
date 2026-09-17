function [r_pole, z_fuj] = fujiwara_bound(b_input)
% FUJIWARA_BOUND Calcula la cota espectral superior O(K) de Fujiwara
% para las raices de un polinomio denominador B(s), sin calcular raices.
%
% Sintaxis:
%   [r_pole, z_fuj] = laplace.fujiwara_bound(b_input)
%
% Entradas:
%   b_input - Vector de coeficientes canónicos [b_0, b_1, ..., b_K] en
%             potencias descendentes de s, objeto laplace.FactorPoly,
%             o laplace.PartialFractions.
%
% Salidas:
%   r_pole  - Radio espectral acotado que contiene a todos los polos (rad/s).
%   z_fuj   - Limite temporal causal seguro z_fuj = 35 / r_pole (segundos).
%
% Referencia:
%   M. Fujiwara, "Uber die obere Schranke des absoluten Betrages der
%   Wurzeln einer algebraischen Gleichung", Tohoku Math. J., 10, 1916.

    if isa(b_input, 'laplace.FactorPoly') || isa(b_input, 'laplace.PartialFractions')
        r_pole = b_input.spectral_radius();
    elseif isnumeric(b_input)
        % Accelerated compiled MEX dispatch (Level 3 protection & speed)
        persistent has_mex;
        if isempty(has_mex)
            has_mex = (exist('laplace.fujiwara_bound_mex', 'file') == 3) || ...
                      (exist('fujiwara_bound_mex', 'file') == 3);
        end
        if has_mex
            try
                if nargout > 1
                    [r_pole, z_fuj] = laplace.fujiwara_bound_mex(double(b_input));
                else
                    r_pole = laplace.fujiwara_bound_mex(double(b_input));
                    z_fuj = 35.0 / r_pole;
                end
                return;
            catch
                has_mex = false;
            end
        end

        b_clean = b_input(:).'; % Vector fila
        % Eliminar ceros iniciales
        idx_nz = find(abs(b_clean) > 1e-300, 1, 'first');
        if isempty(idx_nz)
            r_pole = 1.0;
            z_fuj = Inf;
            return;
        end
        b_clean = b_clean(idx_nz:end);
        K = length(b_clean) - 1;
        if K <= 0
            r_pole = 1.0;
            z_fuj = Inf;
            return;
        end

        b_lead = b_clean(1);
        b_norm = abs(b_clean(2:end) ./ b_lead);

        % Vectorizacion O(K) de la cota de Fujiwara
        % Fujiwara (1916): R = 2 * max( |b_1/2|, |b_2|^(1/2), ..., |b_{K-1}|^(1/(K-1)), |b_K/2|^(1/K) )
        indices = 1:K;
        scaled_b = b_norm;
        if K == 1
            scaled_b(1) = scaled_b(1) / 2.0;
        else
            scaled_b(1) = scaled_b(1) / 2.0;
            scaled_b(K) = scaled_b(K) / 2.0;
        end

        % Evitar desbordamiento en potencias fraccionarias de valores cero
        mask = scaled_b > 1e-300;
        if any(mask)
            terms = zeros(1, K);
            terms(mask) = scaled_b(mask) .^ (1.0 ./ indices(mask));
            r_fuj = 2.0 * max(terms);
        else
            r_fuj = 1.0;
        end

        % Cota combinada de Cauchy como salvaguarda
        r_cauchy = 1.0 + max(b_norm);
        r_pole = max(1e-4, min(r_fuj, r_cauchy));
    else
        error('laplace:fujiwara_bound:InvalidInput', 'Tipo de entrada no soportado.');
    end

    if r_pole > 1e-4
        z_fuj = 35.0 / r_pole;
    else
        z_fuj = Inf;
    end
end
