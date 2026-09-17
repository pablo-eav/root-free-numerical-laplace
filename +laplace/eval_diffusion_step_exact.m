function res = eval_diffusion_step_exact(z_grid)
% EVAL_DIFFUSION_STEP_EXACT Exact analytical step response for 1D diffusion
%
%   res = laplace.eval_diffusion_step_exact(z_grid)
%
%   Evaluates the exact inverse Laplace transform of:
%       F(s) = 1 / [ s * cosh(sqrt(s)) ]
%
%   Combines the short-time complementary error function expansion (t < 0.08)
%   and the long-time modal Fourier series expansion (t >= 0.08) to achieve
%   uniform 1e-15 accuracy across all t in [0, inf).
%
%   Part of the Root-Free Laplace Inversion Toolbox.

z_arr = double(z_grid);
res = zeros(size(z_arr));

for i = 1:numel(z_arr)
    t = z_arr(i);
    if t <= 1e-14
        res(i) = 0.0;
        continue;
    end
    
    if t < 0.08
        sqt = sqrt(t);
        s_val = 0.0;
        for n = 0:14
            arg = (2.0 * double(n) + 1.0) / (2.0 * sqt);
            if arg > 10.0
                break;
            end
            term = ((-1.0)^n) * erfc(arg);
            s_val = s_val + term;
            if abs(term) < 1e-17
                break;
            end
        end
        res(i) = 2.0 * s_val;
    else
        s_val = 0.0;
        for m = 0:250
            factor = 2.0 * double(m) + 1.0;
            term = ((-1.0)^m / factor) * exp(-(factor^2) * (pi^2) * t / 4.0);
            s_val = s_val + term;
            if abs(term) < 1e-17
                break;
            end
        end
        res(i) = 1.0 - (4.0 / pi) * s_val;
    end
end

end
