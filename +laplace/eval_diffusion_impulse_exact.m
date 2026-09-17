function res = eval_diffusion_impulse_exact(z_grid)
% EVAL_DIFFUSION_IMPULSE_EXACT Exact analytical impulse response for 1D diffusion
%
%   res = laplace.eval_diffusion_impulse_exact(z_grid)
%
%   Evaluates the exact inverse Laplace transform of:
%       F(s) = 1 / cosh(sqrt(s))
%
%   Uses the exact modal Fourier expansion:
%       f(t) = pi * sum_{m=0}^{inf} (-1)^m * (2*m + 1) * exp(-(2*m + 1)^2 * pi^2 * t / 4)
%
%   Part of the Root-Free Laplace Inversion Toolbox.

z_arr = double(z_grid);
res = zeros(size(z_arr));

for i = 1:numel(z_arr)
    t = z_arr(i);
    if t <= 1e-12
        res(i) = 0.0;
        continue;
    end
    
    s_val = 0.0;
    for m = 0:250
        factor = 2.0 * double(m) + 1.0;
        term = ((-1.0)^m) * factor * exp(-(factor^2) * (pi^2) * t / 4.0);
        s_val = s_val + term;
        if abs(term) < 1e-17
            break;
        end
    end
    res(i) = pi * s_val;
end

end
