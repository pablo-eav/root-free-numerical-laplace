function obj = FactorPoly(varargin)
% FACTORPOLY Global constructor wrapper for laplace.FactorPoly
%   Permite invocar FactorPoly(...) directamente sin el prefijo laplace.
obj = laplace.FactorPoly(varargin{:});
end
