function res = eval_butterworth6_exact(z_grid)
% EVAL_BUTTERWORTH6_EXACT Exact analytical impulse response for 6th-order Butterworth filter
%
%   res = laplace.eval_butterworth6_exact(z_grid)
%
%   Evaluates the exact inverse Laplace transform of:
%       F(s) = 1 / B_6(s) = 1 / (s^6 + 3.8637*s^5 + 7.4641*s^4 + 9.1416*s^3 + 7.4641*s^2 + 3.8637*s + 1)
%
%   Part of the Root-Free Laplace Inversion Toolbox.

z_arr = double(z_grid);
res = zeros(size(z_arr));

% Poles of normalized Butterworth 6 in the left-half plane:
% s_k = exp(i * (2k+1)*pi / 12) for k = 3, 4, 5, 6, 7, 8
thetas = [(7*pi/12), (9*pi/12), (11*pi/12), (13*pi/12), (15*pi/12), (17*pi/12)];
roots_p = exp(1i * thetas);

% Residues R_k = 1 / prod_{j ~= k} (s_k - s_j)
residues = zeros(1, 6);
for k = 1:6
    rk = roots_p(k);
    prod_diff = 1.0;
    for j = 1:6
        if j ~= k
            prod_diff = prod_diff * (rk - roots_p(j));
        end
    end
    residues(k) = 1.0 / prod_diff;
end

for i = 1:numel(z_arr)
    zv = z_arr(i);
    if zv <= 1e-14
        res(i) = 0.0;
    else
        val = sum(residues .* exp(roots_p * zv));
        res(i) = real(val);
    end
end

end
