classdef PartialFractions
% PARTIALFRACTIONS Exact modal partial fractions representation
%
%   F(s) = sum_{k=1}^K R_k / (s - p_k)
%
%   Enables exact representation and instantaneous evaluation of distributed
%   networks, transmission lines, and harmonic resonators up to K = 1,000,000
%   without expanding polynomials or computing roots.
%
%   Properties:
%       poles    - Vector of poles (real or complex)
%       residues - Vector of residues (real or complex)
%
%   Methods:
%       degree()               - Number of modal poles
%       spectral_radius()      - Max pole magnitude max(|p_k|)
%       evaluate_modal(z_grid) - Vectorized exact analytical evaluation
%
%   Part of the Root-Free Laplace Inversion Toolbox.

    properties
        poles = []
        residues = []
    end
    
    methods
        function obj = PartialFractions(poles, residues)
            if nargin == 0
                return;
            end
            obj.poles = poles(:);
            obj.residues = residues(:);
            if length(obj.poles) ~= length(obj.residues)
                error('Poles and residues vectors must have the same length.');
            end
        end
        
        function d = degree(obj)
            d = length(obj.poles);
        end
        
        function l = length(obj)
            l = length(obj.poles) + 1;
        end
        
        function r_max = spectral_radius(obj)
            if isempty(obj.poles)
                r_max = 1.0;
            else
                r_max = double(max(abs(obj.poles)));
            end
        end
        
        function f_vals = evaluate_modal(obj, z_grid)
            % EVALUATE_MODAL Exact modal evaluation: f(z) = sum_{k=1}^K R_k * exp(p_k * z)
            z_arr = double(z_grid(:).');
            M = length(z_arr);
            K = length(obj.poles);
            
            f_vals = zeros(size(z_arr));
            
            % Block matrix multiplication to optimize cache and memory
            % If K is up to 5000, we can evaluate in single matrix multiplication
            if K <= 10000 && M <= 10000
                % [K x 1] * [1 x M] -> [K x M]
                pz = obj.poles * z_arr;
                exp_pz = exp(pz);
                f_vals = real(obj.residues.' * exp_pz);
            else
                % Chunked evaluation for huge K (e.g. K = 1,000,000)
                chunk_size = 5000;
                for k_start = 1:chunk_size:K
                    k_end = min(k_start + chunk_size - 1, K);
                    pk = obj.poles(k_start:k_end);
                    Rk = obj.residues(k_start:k_end);
                    pz = pk * z_arr;
                    f_vals = f_vals + real(Rk.' * exp(pz));
                end
            end
            
            % Reshape to match input z_grid
            f_vals = reshape(f_vals, size(z_grid));
        end
    end
end
