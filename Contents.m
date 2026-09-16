% ROOT_FREE_LAPLACE Root-Free Numerical Laplace Inversion Toolbox
% Version 1.0.1 (Release 2026) 16-Sep-2026
%
% High-Order Spectral and Orthogonal Numerical Laplace Inversion
% Supporting Degrees from K = 1 to K = 1,000,000 strictly without root-finding.
%
% Universal Inversion Interface
%   laplace.invert                    - High-level root-free numerical inversion entry point
%   laplace.fujiwara_bound            - O(K) Fujiwara spectral bound and safe causal horizon
%
% Specialized Numerical Engines
%   laplace.EngineHybrid              - Autonomous intelligent engine dispatcher
%   laplace.EngineStirling            - Log-space Laurent-Stirling recursion (Float64)
%   laplace.EngineLaguerre            - Orthogonal Möbius-Laguerre projection (Float64)
%   laplace.EngineTaylorAdaptive      - Adaptive Taylor prolongation with generalized Laguerre arcs
%
% Massive Order Representations & Decomposition
%   laplace.FactorPoly                - Factored polynomial class with Newton-Girard power sums
%   laplace.PartialFractions          - Exact modal decomposition for distributed networks
%   laplace.chebyshev_network         - Chebyshev transmission ladder generator (up to N = 10^6)
%   laplace.harmonic_resonators       - 5000 harmonic resonators generator (Degree K = 10,000)
%
% Analytical Reference Benchmarks
%   laplace.eval_harmonic_resonators_exact - Analytical Dirichlet kernel closed form
%   laplace.eval_chebyshev_ladder_exact    - Exact Chebyshev modal response
%   laplace.eval_diffusion_step_exact      - Exact 1D diffusion step response (erfc + Fourier)
%   laplace.eval_diffusion_impulse_exact   - Exact 1D diffusion impulse response
%   laplace.eval_laguerre_exact            - Exact damped Laguerre evaluation up to K = 10^6
%
% Core Mathematical Kernels
%   laplace.stirling_gamma            - 5-term asymptotic log-space ln(Gamma(x))
%   laplace.eval_laguerre             - Vectorized Favard 3-term recurrence for L_n(x)
%   laplace.mobius_conformal          - Conformal polynomial mapping s -> w = (s-a)/(s+a)
%   laplace.extract_mobius_laguerre_coeffs - Deconvolution in conformal w-space
%   laplace.extract_unified_laurent_coeffs  - Laurent series coefficients with dynamic scaling
%
% Interactive Desktop Application
%   LaplaceGUI                        - Full graphical user interface studio
%
% Installation and Management
%   install_toolbox                   - Permanently install toolbox to MATLAB path
%   uninstall_toolbox                 - Remove toolbox from MATLAB path
%   start_toolbox                     - Session startup and path initializer
%   run_all_tests                     - Master test suite validation runner
%
% Copyright 2026 Root-Free Laplace Toolbox Team.
