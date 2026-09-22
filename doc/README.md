# Root-Free Numerical Laplace Inversion Toolbox for MATLAB

[![View Root-Free Laplace on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://es.mathworks.com/matlabcentral/fileexchange/184728-root-free-numerical-laplace)
[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-blue.svg)](https://github.com/pablo-eav/root-free-numerical-laplace)

> 🔗 **Official MATLAB Central File Exchange Entry (ID: 184728)**:  
> [https://es.mathworks.com/matlabcentral/fileexchange/184728-root-free-numerical-laplace](https://es.mathworks.com/matlabcentral/fileexchange/184728-root-free-numerical-laplace)

A high-performance MATLAB toolbox for **Root-Free Numerical Laplace Inversion** supporting orders from $K = 1$ to $K = 1,000,000$ in standard IEEE 754 double precision (`float64`).

---

## 🌟 Key Capabilities

- **100% Root-Free (`roots`-free):** Never computes roots, eigenvalues, or matrix factorizations of denominator polynomials.
- **Immunity to the Taylor Hump:** Standard Taylor expansions fail catastrophic cancellation for $K > 30$ because coefficients grow like $\sim 10^{30}$. This toolbox uses:
  1. **Log-space Laurent-Stirling recursion** ($\ln\Gamma$ evaluation) for $z \le z_{\text{fuj}}$.
  2. **Möbius-Laguerre orthogonal projection** on $L^2[0, \infty)$ with conformal scale tuning $a \approx R_{\text{fuj}} / 2$.
  3. **Adaptive Taylor prolongation** with overlapping arcs for diffusion and boundary layers.
- **Orders up to $K = 1,000,000$:** Utilizing `FactorPoly` and `PartialFractions` representations.
- **Pure MATLAB (R2018b+ Compatible):** Zero external C/MEX compiler dependencies, zero proprietary toolboxes required.
- **Interactive GUI Studio (`LaplaceGUI`):** Dual real-time plotting of time response and absolute error, catalog of presets, and export to Workspace/CSV.

---

## 🚀 Quick Start

### 1. Installation
In MATLAB, navigate to the `root_free_laplace` directory and execute:
```matlab
>> start_toolbox
```
This automatically registers the namespace `+laplace`, examples, tests, and GUI into your MATLAB path.

### 2. Inversion of a Transfer Function
```matlab
% Invert F(s) = 1 / (s^2 + 2*s + 2)
z = linspace(0, 10, 500);
[f_vals, info] = laplace.invert([1], [1, 2, 2], z);

% Plot
plot(z, f_vals);
xlabel('Time z (s)'); ylabel('f(z)');
```

### 3. Factored Massive Cascade ($K = 100$)
```matlab
% F(s) = 1 / (s + 1)^100
B = laplace.FactorPoly('roots', -ones(100, 1));
z = linspace(0, 150, 500);
[f_vals, info] = laplace.invert(1, B, z);
```

### 4. 5000 Resonators / 10,000 Undamped Modes
```matlab
% Q(s) = prod_{k=1}^5000 (s^2 + k^2)
pf = laplace.harmonic_resonators(5000);
z = linspace(1e-5, 0.02, 1000);
[f_vals, info] = laplace.invert([], pf, z);
```

### 5. Launch the Graphical Desktop Studio
```matlab
>> LaplaceGUI
```

---

## 📁 Repository Structure

```
root_free_laplace/
│
├── start_toolbox.m              # Master initialization & path configuration
│
├── +laplace/                    # Toolbox Package Namespace
│   ├── fujiwara_bound.m         # O(K) spectral radius bound & safe horizon z_fuj
│   ├── stirling_gamma.m         # Log-space asymptotic Stirling ln(Gamma(x))
│   ├── eval_laguerre.m          # Vectorized Favard 3-term recurrence for L_n(x)
│   ├── eval_laguerre_exact.m    # O(K) exact damped Laguerre evaluator
│   ├── mobius_conformal.m       # Conformal Möbius mapping s -> w = (s-a)/(s+a)
│   ├── extract_mobius_laguerre_coeffs.m # Synthetic deconvolution in w-space
│   ├── extract_unified_laurent_coeffs.m # Laurent coefficients with dynamic scaling
│   ├── FactorPoly.m             # Factored polynomial class (up to K=10^6)
│   ├── PartialFractions.m       # Modal partial fractions class
│   ├── chebyshev_network.m      # Chebyshev ladder generator (N=10^6)
│   ├── harmonic_resonators.m    # 5000 harmonic resonators generator
│   ├── eval_harmonic_resonators_exact.m # O(1) Dirichlet kernel analytical solution
│   ├── eval_chebyshev_ladder_exact.m    # Exact Chebyshev ladder benchmark
│   ├── eval_diffusion_step_exact.m      # Exact diffusion step response (erfc + Fourier)
│   ├── eval_diffusion_impulse_exact.m   # Exact diffusion impulse response
│   ├── EngineStirling.m         # Laurent-Stirling Float64 engine
│   ├── EngineLaguerre.m         # Orthogonal Möbius-Laguerre Float64 engine
│   ├── EngineTaylorAdaptive.m   # Overlapping Taylor arc prolongation engine
│   ├── EngineHybrid.m           # Intelligent autonomous dispatcher
│   └── invert.m                 # Top-level API entry point
│
├── examples/                    # Ready-to-run engineering scripts
│   ├── ex01_basic_rational.m    # Standard 2nd order underdamped system
│   ├── ex02_harmonic_5000.m     # 5000 harmonic resonators (K=10,000)
│   ├── ex03_chebyshev_1000000.m # Chebyshev transmission ladder (N=1,000,000)
│   └── ex04_diffusion_step.m    # 1D heat conduction step response
│
├── tests/                       # Automated validation suite
│   ├── run_all_tests.m          # Master test runner
│   ├── test_fujiwara.m          # Spectral bound tests
│   ├── test_stirling.m          # Log-gamma precision tests
│   ├── test_laguerre.m          # Orthogonality & recurrence tests
│   ├── test_massive_orders.m    # K=10,000 and K=1,000,000 benchmarks
│   └── test_hybrid_inversion.m  # Accuracy verification tests
│
├── app/
│   └── LaplaceGUI.m             # Interactive visualization and studio
│
└── doc/
    ├── README.md                # This manual
    └── TECHNICAL_MANUAL.md      # Detailed mathematical derivations
```

---

## 🧪 Running the Test Suite

Execute in MATLAB:
```matlab
>> run_all_tests
```
Expected output:
```
=================================================================
   ROOT-FREE NUMERICAL LAPLACE TOOLBOX - COMPREHENSIVE TEST SUITE
=================================================================

Running test_fujiwara... PASSED.
Running test_stirling... PASSED.
Running test_laguerre... PASSED.
Running test_massive_orders... PASSED.
Running test_hybrid_inversion... PASSED.

-----------------------------------------------------------------
SUCCESS: All 5 test suites passed cleanly.
=================================================================
```
