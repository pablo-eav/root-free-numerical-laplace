function c_n = extract_mobius_laguerre_coeffs(a_input, b_input, a_param, N_terms)
% EXTRACT_MOBIUS_LAGUERRE_COEFFS Deconvolution in conformal Möbius space
%
%   c_n = laplace.extract_mobius_laguerre_coeffs(a_input, b_input, a_param, N_terms)
%
%   Extracts the orthogonal Laguerre coefficients c_n from the rational fraction
%   F(s) = A(s) / B(s) mapped under the conformal transformation:
%       s = a * (1 + w) / (1 - w)
%       G(w) = (2*a / (1 - w)) * F(a*(1+w)/(1-w)) = sum_{n=0}^{N-1} c_n * w^n
%
%   Supports:
%       - Dense monomial polynomials A(s), B(s)
%       - Factored FactorPoly representations with logarithmic underflow protection
%       - Exact modal PartialFractions
%
%   Inputs:
%       a_input - Numerator (vector, FactorPoly, or scalar)
%       b_input - Denominator (vector, FactorPoly, or PartialFractions)
%       a_param - Conformal scaling parameter (positive scalar)
%       N_terms - Number of coefficients to extract
%
%   Outputs:
%       c_n     - Array of N_terms orthogonal Laguerre expansion coefficients
%
%   Part of the Root-Free Laplace Inversion Toolbox.

a_param = double(a_param);
N_terms = round(double(N_terms));

if isa(b_input, 'laplace.PartialFractions')
    poles = b_input.poles;
    residues = b_input.residues;
    weights = 2.0 * a_param * residues ./ (a_param - poles);
    lambdas = (poles + a_param) ./ (poles - a_param);
    c_n = zeros(N_terms, 1);
    for n = 0:(N_terms - 1)
        c_n(n + 1) = real(sum(weights .* (lambdas .^ n)));
    end
    return;
end

is_b_factored = isa(b_input, 'laplace.FactorPoly');
is_a_factored = isa(a_input, 'laplace.FactorPoly');

if is_b_factored
    deg_B = b_input.degree();
    if is_a_factored
        deg_A = a_input.degree();
    elseif isnumeric(a_input)
        deg_A = max(0, length(a_input) - 1);
    else
        deg_A = 0;
    end
    
    K = deg_B;
    M = deg_A;
    
    % Convolve B(w) factor by factor with log scaling
    log_scale_B = 0.0;
    poly_B_w = 1.0;
    
    if ~isempty(b_input.roots)
        for i = 1:length(b_input.roots)
            rk = b_input.roots(i);
            c0 = a_param - rk;
            c1 = a_param + rk;
            m_val = max(abs(c0), abs(c1));
            if m_val > 1e-300
                log_scale_B = log_scale_B + log(m_val);
                factor = [c0 / m_val, c1 / m_val];
            else
                factor = [c0, c1];
            end
            poly_B_w = conv(poly_B_w, factor);
            if length(poly_B_w) > N_terms
                poly_B_w = poly_B_w(1:N_terms);
            end
        end
    end
    
    if ~isempty(b_input.quad_coeffs)
        for i = 1:size(b_input.quad_coeffs, 1)
            b_q = b_input.quad_coeffs(i, 1);
            c_q = b_input.quad_coeffs(i, 2);
            A_q = a_param^2 + b_q * a_param + c_q;
            B_q = 2.0 * (a_param^2 - c_q);
            C_q = a_param^2 - b_q * a_param + c_q;
            m_val = max([abs(A_q), abs(B_q), abs(C_q)]);
            if m_val > 1e-300
                log_scale_B = log_scale_B + log(m_val);
                factor = [A_q / m_val, B_q / m_val, C_q / m_val];
            else
                factor = [A_q, B_q, C_q];
            end
            poly_B_w = conv(poly_B_w, factor);
            if length(poly_B_w) > N_terms
                poly_B_w = poly_B_w(1:N_terms);
            end
        end
    end
    
    % Convolve A(w)
    log_scale_A = 0.0;
    poly_A_w = 1.0;
    
    if is_a_factored
        if ~isempty(a_input.roots)
            for i = 1:length(a_input.roots)
                rk = a_input.roots(i);
                c0 = a_param - rk;
                c1 = a_param + rk;
                m_val = max(abs(c0), abs(c1));
                if m_val > 1e-300
                    log_scale_A = log_scale_A + log(m_val);
                    factor = [c0 / m_val, c1 / m_val];
                else
                    factor = [c0, c1];
                end
                poly_A_w = conv(poly_A_w, factor);
                if length(poly_A_w) > N_terms
                    poly_A_w = poly_A_w(1:N_terms);
                end
            end
        end
        if ~isempty(a_input.quad_coeffs)
            for i = 1:size(a_input.quad_coeffs, 1)
                b_q = a_input.quad_coeffs(i, 1);
                c_q = a_input.quad_coeffs(i, 2);
                A_q = a_param^2 + b_q * a_param + c_q;
                B_q = 2.0 * (a_param^2 - c_q);
                C_q = a_param^2 - b_q * a_param + c_q;
                m_val = max([abs(A_q), abs(B_q), abs(C_q)]);
                if m_val > 1e-300
                    log_scale_A = log_scale_A + log(m_val);
                    factor = [A_q / m_val, B_q / m_val, C_q / m_val];
                else
                    factor = [A_q, B_q, C_q];
                end
                poly_A_w = conv(poly_A_w, factor);
                if length(poly_A_w) > N_terms
                    poly_A_w = poly_A_w(1:N_terms);
                end
            end
        end
    elseif isnumeric(a_input) && length(a_input) > 1
        a_lead = double(a_input(1));
        if abs(a_lead) > 1e-300
            a_monic = double(a_input) / a_lead;
        else
            a_monic = double(a_input);
        end
        poly_A_w = laplace.mobius_conformal(a_monic, a_param, M);
        if length(poly_A_w) > N_terms
            poly_A_w = poly_A_w(1:N_terms);
        end
    else
        poly_A_w = 1.0;
    end
    
    extra_powers = max(0, K - 1 - M);
    for k = 1:min(extra_powers, N_terms)
        poly_A_w = conv(poly_A_w, [1.0, -1.0]);
        if length(poly_A_w) > N_terms
            poly_A_w = poly_A_w(1:N_terms);
        end
    end
    
    if is_a_factored
        gain_A = a_input.gain;
    elseif isnumeric(a_input) && ~isempty(a_input)
        gain_A = double(a_input(1));
    else
        gain_A = 1.0;
    end
    gain_B = b_input.gain;
    
    if abs(gain_A) < 1e-300
        c_n = zeros(N_terms, 1);
        return;
    end
    
    net_log_gain = log(2.0 * a_param) + log(abs(gain_A)) - log(abs(gain_B)) + log_scale_A - log_scale_B;
    if net_log_gain < -700.0
        c_n = zeros(N_terms, 1);
        return;
    elseif net_log_gain > 700.0
        scale_fac = sign(gain_A) * sign(gain_B) * realmax;
    else
        scale_fac = exp(net_log_gain) * sign(gain_A) * sign(gain_B);
    end
    
    P_w = poly_A_w * scale_fac;
    Q_w = poly_B_w;

else
    % Standard canonical polynomials: F(s) = A(s) / B(s)
    if isempty(a_input)
        a_arr = 1.0;
    else
        a_arr = double(a_input(:).');
    end
    b_arr = double(b_input(:).');
    
    % Strip leading zeros
    nz_b = find(abs(b_arr) > 1e-300, 1, 'first');
    if isempty(nz_b)
        error('El denominador B(s) no puede ser idénticamente nulo.');
    end
    b_arr = b_arr(nz_b:end);
    
    nz_a = find(abs(a_arr) > 1e-300, 1, 'first');
    if isempty(nz_a)
        a_arr = 0.0;
    else
        a_arr = a_arr(nz_a:end);
    end
    
    deg_B = length(b_arr) - 1;
    deg_A = length(a_arr) - 1;
    
    if deg_A >= deg_B && any(a_arr ~= 0)
        error('La función de transferencia F(s) = A(s)/B(s) debe ser estrictamente propia: grado(A) < grado(B).');
    end
    
    % Ensure monic B(s)
    b_lead = b_arr(1);
    b_clean = b_arr / b_lead;
    a_clean = a_arr / b_lead;
    
    K = deg_B;
    Q_w = laplace.mobius_conformal(b_clean, a_param, K);
    if all(a_clean == 0)
        P_w = zeros(1, K);
    else
        P_w = 2.0 * a_param * laplace.mobius_conformal(a_clean, a_param, K - 1);
    end
end

% Synthetic deconvolution P(w) / Q(w)
% Accelerated compiled MEX dispatch (Level 3 protection & speed)
persistent has_mex;
if isempty(has_mex)
    has_mex = (exist('laplace.deconv_synthetic_mex', 'file') == 3) || ...
              (exist('deconv_synthetic_mex', 'file') == 3);
end
if has_mex
    try
        c_n = laplace.deconv_synthetic_mex(P_w, Q_w, N_terms);
        return;
    catch
        has_mex = false;
    end
end

c_n = zeros(N_terms, 1);
q0 = Q_w(1);
if abs(q0) < 1e-300
    q0 = 1.0;
end

len_P = length(P_w);
len_Q = length(Q_w);

for n = 0:(N_terms - 1)
    if n < len_P
        p_val = P_w(n + 1);
    else
        p_val = 0.0;
    end
    
    sum_qc = 0.0;
    max_k = min(n, len_Q - 1);
    for k = 1:max_k
        sum_qc = sum_qc + Q_w(k + 1) * c_n(n - k + 1);
    end
    c_n(n + 1) = (p_val - sum_qc) / q0;
end

end
