classdef FactorPoly
% FACTORPOLY Factored polynomial representation for massive degrees (up to 1,000,000)
%
%   Represents a polynomial in factored form:
%       P(s) = gain * prod(s - r_k) * prod(s^2 + b_j*s + c_j)
%
%   Avoids catastrophic monomial coefficient expansion (which fails for
%   K > 50 in standard floating point due to combinatoric binomial coefficients).
%
%   Properties:
%       roots       - Array of real roots
%       quad_coeffs - [N x 2] matrix of quadratic factors [b_j, c_j]
%       gain        - Scalar leading gain
%
%   Methods:
%       degree()               - Total polynomial degree
%       spectral_radius()      - Exact/upper bound on max root magnitude O(K)
%       compute_power_sums(M)  - Power sums S_m = sum(r_k^m) via Newton-Girard
%
%   Part of the Root-Free Laplace Inversion Toolbox.

    properties
        roots = []
        quad_coeffs = zeros(0, 2)
        gain = 1.0
    end
    
    methods
        function obj = FactorPoly(varargin)
            % Constructor:
            %   FactorPoly('roots', r, 'quad_coeffs', q, 'gain', g)
            %   FactorPoly(roots, quad_coeffs, gain)
            if nargin == 0
                return;
            end
            
            if ischar(varargin{1}) || isstring(varargin{1})
                p = inputParser;
                addParameter(p, 'roots', []);
                addParameter(p, 'quad_coeffs', zeros(0, 2));
                addParameter(p, 'gain', 1.0);
                parse(p, varargin{:});
                obj.roots = double(p.Results.roots(:));
                obj.quad_coeffs = double(p.Results.quad_coeffs);
                obj.gain = double(p.Results.gain);
            else
                if nargin >= 1 && ~isempty(varargin{1})
                    obj.roots = double(varargin{1}(:));
                end
                if nargin >= 2 && ~isempty(varargin{2})
                    obj.quad_coeffs = double(varargin{2});
                end
                if nargin >= 3 && ~isempty(varargin{3})
                    obj.gain = double(varargin{3});
                end
            end
            
            if ~isempty(obj.quad_coeffs) && size(obj.quad_coeffs, 2) ~= 2
                error('quad_coeffs must have 2 columns: [b, c] representing s^2 + b*s + c.');
            end
        end
        
        function d = degree(obj)
            % Total degree: linear roots + 2 * quadratic factors
            n_lin = length(obj.roots);
            n_quad = size(obj.quad_coeffs, 1);
            d = n_lin + 2 * n_quad;
        end
        
        function l = length(obj)
            l = obj.degree() + 1;
        end
        
        function r_max = spectral_radius(obj)
            % O(K) exact spectral radius without polynomial expansion
            r_max = 0.0;
            if ~isempty(obj.roots)
                r_max = max(r_max, max(abs(obj.roots)));
            end
            if ~isempty(obj.quad_coeffs)
                b = obj.quad_coeffs(:, 1);
                c = obj.quad_coeffs(:, 2);
                disc = b.^2 - 4.0 .* c;
                complex_mask = (disc < 0);
                if any(complex_mask)
                    r_max = max(r_max, max(sqrt(max(c(complex_mask), 0.0))));
                end
                if any(~complex_mask)
                    r_real = (abs(b(~complex_mask)) + sqrt(disc(~complex_mask))) / 2.0;
                    r_max = max(r_max, max(r_real));
                end
            end
            r_max = max(r_max, 1e-4);
        end
        
        function S = compute_power_sums(obj, M, scale)
            % COMPUTE_POWER_SUMS Newton-Girard power sums: S_m = sum_{k=1}^K s_k^m
            %   with scaling s -> s / scale to prevent overflow.
            if nargin < 3 || isempty(scale)
                scale = 1.0;
            end
            
            S = zeros(M + 1, 1);
            
            % Contribution from linear roots
            if ~isempty(obj.roots)
                roots_scaled = obj.roots / scale;
                for j = 1:M
                    S(j + 1) = S(j + 1) + sum(roots_scaled .^ j);
                end
            end
            
            % Contribution from quadratic factors via 2-term recurrence
            N_q = size(obj.quad_coeffs, 1);
            if N_q > 0
                b = obj.quad_coeffs(:, 1) / scale;
                c = obj.quad_coeffs(:, 2) / (scale^2);
                
                w_prev2 = 2.0 * ones(N_q, 1); % w_0 = lambda_1^0 + lambda_2^0 = 2
                w_prev1 = -b;                 % w_1 = lambda_1 + lambda_2 = -b
                S(2) = S(2) + sum(w_prev1);
                
                for m = 2:M
                    w_curr = -b .* w_prev1 - c .* w_prev2;
                    S(m + 1) = S(m + 1) + sum(w_curr);
                    w_prev2 = w_prev1;
                    w_prev1 = w_curr;
                end
            end
        end
        
        function res = mpower(obj, n)
            % Power of FactorPoly: P(s)^n
            n = round(double(n));
            if n < 1
                error('Exponent must be a positive integer.');
            end
            new_roots = repmat(obj.roots, n, 1);
            new_quads = repmat(obj.quad_coeffs, n, 1);
            new_gain = obj.gain ^ n;
            res = laplace.FactorPoly('roots', new_roots, 'quad_coeffs', new_quads, 'gain', new_gain);
        end
        
        function res = mtimes(a, b)
            % Multiplication of FactorPoly objects or FactorPoly with scalar
            if isnumeric(a) && isscalar(a)
                res = b;
                res.gain = res.gain * double(a);
                return;
            elseif isnumeric(b) && isscalar(b)
                res = a;
                res.gain = res.gain * double(b);
                return;
            end
            
            if isa(a, 'laplace.FactorPoly') && isa(b, 'laplace.FactorPoly')
                res = laplace.FactorPoly(...
                    'roots', [a.roots; b.roots], ...
                    'quad_coeffs', [a.quad_coeffs; b.quad_coeffs], ...
                    'gain', a.gain * b.gain);
            else
                error('Multiplication supported between FactorPoly and scalar or FactorPoly.');
            end
        end
    end
end
