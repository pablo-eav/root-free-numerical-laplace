function lic_info = license_status()
% LICENSE_STATUS Displays the current licensing status, tier, and days remaining
%
% Syntax:
%   laplace.license_status
%   info = laplace.license_status
%
% Part of the Root-Free Laplace Inversion Toolbox.

if nargout > 0
    [~, lic_info] = laplace.LicenseManager.check_status();
else
    laplace.LicenseManager.display_status();
end

end
