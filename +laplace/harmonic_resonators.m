function pf = harmonic_resonators(N)
% HARMONIC_RESONATORS Generates PartialFractions for N undamped resonators
%
%   pf = laplace.harmonic_resonators(N)
%
%   Constructs the exact modal decomposition for the transfer function:
%       Q(s) = prod_{k=1}^N (s^2 + omega_k^2),  omega_k = k
%       F(s) = sum_{k=1}^N k / (s^2 + k^2)
%
%   Modal decomposition:
%       k / (s^2 + k^2) = (-0.5j) / (s - j*k) + (0.5j) / (s + j*k)
%   Exact time response:
%       f(z) = sum_{k=1}^N sin(k*z)
%
%   Inputs:
%       N  - Number of resonators (default: 5000, total degree = 2*N = 10,000)
%
%   Outputs:
%       pf - Instance of laplace.PartialFractions
%
%   Part of the Root-Free Laplace Inversion Toolbox.

if nargin < 1 || isempty(N)
    N = 5000;
end

N = round(double(N));
k = (1:N).';

poles = zeros(2 * N, 1);
residues = zeros(2 * N, 1);

poles(1:2:end) = 1j * k;
poles(2:2:end) = -1j * k;

residues(1:2:end) = -0.5j;
residues(2:2:end) = 0.5j;

pf = laplace.PartialFractions(poles, residues);

end
