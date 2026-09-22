classdef EngineHybrid
% ENGINEHYBRID Autonomous dispatcher for root-free Laplace inversion
%
%   Automatically selects the optimal mathematical engine based on:
%       - Fujiwara spectral radius R_fuj
%       - Safe causal horizon z_fuj = 35 / R_fuj
%       - Relative degree delta = deg(B) - deg(A)
%       - Time window [z_min, z_max]
%
%   Engines available:
%       - 'Auto'           : Intelligent autonomous selection
%       - 'Stirling'       : Laurent-Stirling log-space series (Float64)
%       - 'Laguerre'       : Möbius-Laguerre orthogonal projection (Float64)
%       - 'TaylorAdaptive' : Generalized Laguerre-Taylor prolongation
%
%   Part of the Root-Free Laplace Inversion Toolbox.

    methods (Static)
        function [f_vals, info] = invert(a_input, b_input, z_grid, options)
            if nargin < 4 || isempty(options)
                options = struct();
            end
            
            % Parse options
            if isfield(options, 'engine')
                engine_choice = options.engine;
            else
                engine_choice = 'Auto';
            end
            choice_str = lower(char(engine_choice));
            if isfield(options, 'max_terms')
                max_terms = options.max_terms;
            else
                max_terms = 15000;
            end
            if isfield(options, 'user_a')
                user_a = options.user_a;
            else
                user_a = [];
            end
            if isfield(options, 'tol')
                tol = options.tol;
            else
                tol = 1e-3;
            end
            
            % If b_input is PartialFractions and poles are purely imaginary,
            % modal summation is exact and O(K)
            if isa(b_input, 'laplace.PartialFractions')
                if strcmp(choice_str, 'auto') || ~isempty(strfind(choice_str, 'modal'))
                    f_vals = b_input.evaluate_modal(z_grid);
                    info = struct('engine', 'Descomposición Modal Exacta (PartialFractions)', ...
                                  'terms', length(b_input.poles), ...
                                  'dps', 53, ...
                                  'z_fuj', Inf);
                    return;
                end
            end
            
            % Compute Fujiwara bound
            [R_pole, z_fuj] = laplace.fujiwara_bound(b_input);
            z_arr = double(z_grid);
            z_max = max(z_arr(:));
            
            % Compute degrees and relative degree
            if isa(b_input, 'laplace.FactorPoly') || isa(b_input, 'laplace.PartialFractions')
                deg_sys = b_input.degree();
            elseif isnumeric(b_input)
                deg_sys = length(b_input) - 1;
            else
                deg_sys = 1;
            end
            
            if isa(a_input, 'laplace.FactorPoly')
                deg_a = a_input.degree();
            elseif isnumeric(a_input)
                deg_a = max(0, length(a_input) - 1);
            else
                deg_a = 0;
            end
            
            rel_deg = max(1, deg_sys - deg_a);
            
            if ~isempty(strfind(choice_str, 'levin'))
                selected = 'levin';
            elseif ~isempty(strfind(choice_str, 'prolong')) || ~isempty(strfind(choice_str, 'taylor'))
                selected = 'taylor';
            elseif ~isempty(strfind(choice_str, 'stirling')) || ~isempty(strfind(choice_str, 'laurent'))
                selected = 'stirling';
            elseif ~isempty(strfind(choice_str, 'laguerre'))
                selected = 'laguerre';
            else
                % AUTO SELECTION LOGIC (Root-Free Universal)
                if isa(b_input, 'laplace.FactorPoly') && ~isempty(b_input.roots) && ...
                   isempty(b_input.quad_coeffs) && deg_a == 0 && all(abs(b_input.roots - b_input.roots(1)) < 1e-12)
                    % Pure cascade (s + a)^K where Laurent-Stirling is exact O(1)
                    selected = 'stirling';
                elseif isnumeric(b_input) && (isnumeric(a_input) || isempty(a_input))
                    % Canonical rational fractions A(s)/B(s): Möbius-Laguerre is unconditionally stable (zero Taylor hump)
                    selected = 'laguerre';
                else
                    selected = 'laguerre';
                end
            end
            
            switch selected
                case 'levin'
                    [f_vals, info] = laplace.EngineLevin.invert(a_input, b_input, z_grid, options);
                case 'stirling'
                    [f_vals, info] = laplace.EngineStirling.invert(a_input, b_input, z_grid, R_pole, min(max_terms, 250));
                    info.z_fuj = z_fuj;
                case 'laguerre'
                    [f_vals, info] = laplace.EngineLaguerre.invert(a_input, b_input, z_grid, R_pole, max_terms, user_a);
                case 'taylor'
                    [f_vals, info] = laplace.EngineTaylorAdaptive.invert(a_input, b_input, z_grid, R_pole, max_terms, user_a, 12, tol);
                otherwise
                    [f_vals, info] = laplace.EngineLevin.invert(a_input, b_input, z_grid, options);
            end
        end
    end
end
