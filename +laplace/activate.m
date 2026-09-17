function success = activate(key, email)
% ACTIVATE Activates a commercial license key for the Root-Free Laplace Toolbox
%
% Syntax:
%   laplace.activate('SU-CLAVE-DE-PRODUCTO')
%   laplace.activate('SU-CLAVE-DE-PRODUCTO', 'su-email@empresa.com')
%
% Part of the Root-Free Laplace Inversion Toolbox.

if nargin < 1 || isempty(key)
    fprintf('===============================================================================\n');
    fprintf(' ACTIVACIÓN DE LICENCIA COMERCIAL - ROOT-FREE LAPLACE TOOLBOX                  \n');
    fprintf('===============================================================================\n');
    fprintf(' Uso: laplace.activate(''CLAVE-PRODUCTO'', ''su-email@empresa.com'')          \n');
    fprintf(' Su Host ID actual: %s\n', laplace.LicenseManager.get_host_id());
    fprintf('===============================================================================\n');
    success = false;
    return;
end

if nargin < 2
    email = '';
end

success = laplace.LicenseManager.activate(key, email);

end
