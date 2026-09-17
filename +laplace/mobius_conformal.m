function Q = mobius_conformal(coeffs, a, K_target)
% MOBIUS_CONFORMAL Conformal polynomial transformation s -> w = (s-a)/(s+a)
%
%   Q = laplace.mobius_conformal(coeffs, a, K_target)
%
%   Computes the polynomial Q(w) in ASCENDING powers of w:
%       Q(w) = (1 - w)^K_target * P(a * (1 + w) / (1 - w))
%
%   where P(s) has coefficients in DESCENDING powers of s:
%       P(s) = coeffs(1)*s^deg + coeffs(2)*s^(deg-1) + ... + coeffs(deg+1)
%
%   Inputs:
%       coeffs   - Row or column vector of polynomial coefficients in s
%       a        - Positive scaling parameter
%       K_target - Target degree (>= deg(P))
%
%   Outputs:
%       Q        - Vector of length (K_target + 1) representing
%                  ascending powers of w: [w^0, w^1, w^2, ..., w^K_target]
%
%   Part of the Root-Free Laplace Inversion Toolbox.

coeffs = double(coeffs(:).');
% Remove leading zeros
first_nz = find(coeffs ~= 0, 1, 'first');
if isempty(first_nz)
    Q = zeros(1, K_target + 1);
    return;
end
coeffs = coeffs(first_nz:end);

deg = length(coeffs) - 1;
if K_target < deg
    error('K_target (%d) cannot be smaller than polynomial degree (%d).', K_target, deg);
end

Q = zeros(1, K_target + 1);

% Base factors for (1 + w) and (1 - w) in ascending powers of w
p_plus = [1.0, 1.0];   % 1 + w
p_minus = [1.0, -1.0]; % 1 - w

for j = 1:length(coeffs)
    c = coeffs(j);
    if c == 0.0
        continue;
    end
    m = deg - (j - 1); % Power of s
    
    % Convolve (1 + w)^m
    poly_term = 1.0;
    for k = 1:m
        poly_term = conv(poly_term, p_plus);
    end
    % Convolve (1 - w)^(K_target - m)
    for k = 1:(K_target - m)
        poly_term = conv(poly_term, p_minus);
    end
    
    % Pad if necessary to length K_target + 1
    if length(poly_term) < K_target + 1
        poly_term = [poly_term, zeros(1, (K_target + 1) - length(poly_term))];
    end
    
    Q = Q + (c * (a^m)) * poly_term;
end

end
