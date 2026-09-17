function [c_k, rel_deg] = extract_unified_laurent_coeffs(a_input, b_input, max_terms, scale)
% EXTRACT_UNIFIED_LAURENT_COEFFS Normalized Laurent series extraction
%
%   [c_k, rel_deg] = laplace.extract_unified_laurent_coeffs(a_input, b_input, max_terms, scale)
%
%   Extracts the normalized Laurent series expansion:
%       F(s) = sum_{k=0}^{max_terms-1} c_k * s^{-(rel_deg + k)}
%
%   where rel_deg = deg(B) - deg(A) >= 1.
%   Uses dynamic scaling s = scale * \tilde{s} to prevent exponential
%   overflow in float64 during high-order recursive extraction.
%
%   Supports:
%       - Factored FactorPoly representations (via Newton-Girard power sums)
%       - Standard monomial polynomial vectors
%
%   Inputs:
%       a_input   - Numerator polynomial or FactorPoly
%       b_input   - Denominator polynomial or FactorPoly
%       max_terms - Number of Laurent terms to extract (default: 150)
%       scale     - Dynamic scaling factor (default: 1.0)
%
%   Outputs:
%       c_k       - Vector of Laurent coefficients [c_0, c_1, ..., c_{max_terms-1}]
%       rel_deg   - Relative degree delta >= 1
%
%   Part of the Root-Free Laplace Inversion Toolbox.

if nargin < 3 || isempty(max_terms)
    max_terms = 150;
end
if nargin < 4 || isempty(scale)
    scale = 1.0;
end

max_terms = round(double(max_terms));
scale_val = double(scale);
if scale_val <= 0
    scale_val = 1.0;
end

is_b_factored = isa(b_input, 'laplace.FactorPoly');
is_a_factored = isa(a_input, 'laplace.FactorPoly');

if is_b_factored
    deg_b = b_input.degree();
    if is_a_factored
        deg_a = a_input.degree();
    elseif isnumeric(a_input)
        deg_a = max(0, length(a_input) - 1);
    else
        deg_a = 0;
    end
    rel_deg = max(1, deg_b - deg_a);
    
    % Newton-Girard power sums
    S_B = b_input.compute_power_sums(max_terms, scale_val);
    if is_a_factored
        S_A = a_input.compute_power_sums(max_terms, scale_val);
    else
        S_A = zeros(max_terms + 1, 1);
    end
    S = S_B - S_A;
    
    if is_a_factored
        gain_A = a_input.gain;
    elseif isnumeric(a_input) && ~isempty(a_input)
        gain_A = double(a_input(1));
    else
        gain_A = 1.0;
    end
    gain_B = b_input.gain;
    K_lead = gain_A / gain_B;
    
    c_k = zeros(max_terms, 1);
    c_k(1) = K_lead;
    for k = 1:(max_terms - 1)
        s_val = 0.0;
        for j = 1:k
            s_val = s_val + c_k(k - j + 1) * S(j + 1);
        end
        c_k(k + 1) = s_val / double(k);
    end

else
    % Monomial representation
    b_arr = double(b_input(:).');
    a_arr = double(a_input(:).');
    
    % Strip leading zeros
    nz_b = find(b_arr ~= 0, 1, 'first');
    if isempty(nz_b)
        error('Denominator cannot be zero.');
    end
    b_arr = b_arr(nz_b:end);
    
    nz_a = find(a_arr ~= 0, 1, 'first');
    if isempty(nz_a)
        a_arr = 0.0;
    else
        a_arr = a_arr(nz_a:end);
    end
    
    deg_b = length(b_arr) - 1;
    deg_a = length(a_arr) - 1;
    
    if deg_a >= deg_b
        error('Improper rational fraction rejected: deg(A) >= deg(B).');
    end
    
    rel_deg = deg_b - deg_a;
    b_lead = b_arr(1);
    b_clean = b_arr / b_lead;
    a_clean = a_arr / b_lead;
    
    K = deg_b;
    b_norm = b_clean(2:end); % Coefficients of s^(K-1), ..., s^0
    
    % Pad numerator to length K
    r_norm = zeros(1, K);
    r_norm((K - deg_a):K) = a_clean;
    
    log_scale = log(scale_val);
    total_steps = max_terms + rel_deg - 1;
    
    r_scaled = zeros(1, total_steps);
    for i = 1:min(K, total_steps)
        if r_norm(i) ~= 0.0
            r_scaled(i) = r_norm(i) * exp(-i * log_scale);
        end
    end
    
    b_scaled = zeros(1, K);
    for j = 1:K
        if b_norm(j) ~= 0.0
            b_scaled(j) = b_norm(j) * exp(-j * log_scale);
        end
    end
    
    C_full = zeros(1, total_steps);
    for m = 1:total_steps
        rm = r_scaled(m);
        L = min(m - 1, K);
        s_sum = 0.0;
        for j = 1:L
            s_sum = s_sum + b_scaled(j) * C_full(m - j);
        end
        C_full(m) = rm - s_sum;
    end
    
    c_k = C_full(rel_deg : (rel_deg + max_terms - 1)).';
end

end
