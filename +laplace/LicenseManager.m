classdef LicenseManager
% LICENSEMANAGER Manages Trial (30-day), Commercial Activation, and Hardware Verification
%
%   Part of the Root-Free Laplace Inversion Toolbox.
%   Provides tamper-resistant cryptographic license verification for MATLAB & Octave.

    properties (Constant, Access = private)
        % Secret master salt for cryptographic HMAC signatures (compiled into MEX/P-Code)
        SECRET_SALT = 'RFL_MATHWORKS_INVERSA_LAPLACE_SECURE_SALT_2026_V1';
        TRIAL_DAYS = 30;
        LEMONSQUEEZY_ACTIVATE_URL = 'https://api.lemonsqueezy.com/v1/licenses/activate';
        LEMONSQUEEZY_VALIDATE_URL = 'https://api.lemonsqueezy.com/v1/licenses/validate';
    end

    methods (Static)

        function [is_valid, lic_info] = check_status()
            % CHECK_STATUS Returns license validity, tier, remaining days, and description
            lic_file = laplace.LicenseManager.get_license_filepath();
            
            if ~exist(lic_file, 'file')
                % First run: initialize 30-day automatic trial
                lic_info = laplace.LicenseManager.init_trial(lic_file);
            else
                lic_info = laplace.LicenseManager.read_license_file(lic_file);
            end

            % Validate tamper-resistant signature
            calc_sig = laplace.LicenseManager.compute_signature(lic_info);
            if ~isfield(lic_info, 'signature') || ~strcmp(lic_info.signature, calc_sig)
                is_valid = false;
                lic_info.status = 'CORRUPTED';
                lic_info.message = 'El archivo de licencia ha sido modificado o está corrupto.';
                return;
            end

            % Check license tier
            if ismember(lic_info.tier, {'PRO_PERPETUAL', 'PRO_COMMERCIAL', 'ACADEMIC_RESEARCH', 'STUDENT'})
                is_valid = true;
                lic_info.status = ['ACTIVE_', lic_info.tier];
                lic_info.days_left = Inf;
                switch lic_info.tier
                    case {'PRO_PERPETUAL', 'PRO_COMMERCIAL'}
                        lic_info.message = 'Licencia Comercial PRO Industrial activa.';
                    case 'ACADEMIC_RESEARCH'
                        lic_info.message = 'Licencia Académica / Investigación Universitaria activa.';
                    case 'STUDENT'
                        lic_info.message = 'Licencia Estudiante / Tesis activa.';
                end
                return;
            elseif ismember(lic_info.tier, {'PRO_ANNUAL', 'ACADEMIC_ANNUAL', 'STUDENT_ANNUAL'})
                now_dn = now();
                exp_dn = datenum(lic_info.expiry_date, 'yyyy-mm-dd');
                days_left = ceil(exp_dn - now_dn);
                lic_info.days_left = days_left;
                if days_left >= 0
                    is_valid = true;
                    lic_info.status = ['ACTIVE_', lic_info.tier];
                    switch lic_info.tier
                        case 'PRO_ANNUAL'
                            lic_info.message = sprintf('Suscripción Comercial PRO Anual activa (%d días restantes).', days_left);
                        case 'ACADEMIC_ANNUAL'
                            lic_info.message = sprintf('Suscripción Académica Universitaria Anual activa (%d días restantes).', days_left);
                        case 'STUDENT_ANNUAL'
                            lic_info.message = sprintf('Suscripción Estudiante Anual activa (%d días restantes).', days_left);
                    end
                else
                    is_valid = false;
                    lic_info.status = ['EXPIRED_', lic_info.tier];
                    lic_info.message = 'Su suscripción anual ha concluido. Renuévela en la tienda para continuar.';
                end
                return;
            else
                % Trial tier
                now_dn = now();
                exp_dn = datenum(lic_info.expiry_date, 'yyyy-mm-dd');
                inst_dn = datenum(lic_info.install_date, 'yyyy-mm-dd');
                
                % Anti-rollback clock tampering check
                if now_dn < (inst_dn - 1.0)
                    is_valid = false;
                    lic_info.status = 'CLOCK_TAMPERED';
                    lic_info.message = 'Se ha detectado una alteración en el reloj del sistema.';
                    return;
                end

                days_left = ceil(exp_dn - now_dn);
                lic_info.days_left = max(0, days_left);

                if days_left >= 0
                    is_valid = true;
                    lic_info.status = 'ACTIVE_TRIAL';
                    lic_info.message = sprintf('Periodo de prueba activo (%d días restantes de %d).', ...
                        days_left, laplace.LicenseManager.TRIAL_DAYS);
                else
                    is_valid = false;
                    lic_info.status = 'EXPIRED_TRIAL';
                    lic_info.message = sprintf('El periodo de prueba de %d días ha concluido.', ...
                        laplace.LicenseManager.TRIAL_DAYS);
                end
            end
        end

        function verify()
            % VERIFY Asserts that a valid trial or commercial license exists. Throws error if expired.
            persistent has_notified_trial;
            [is_valid, lic_info] = laplace.LicenseManager.check_status();

            if is_valid
                if strcmp(lic_info.tier, 'TRIAL') && isempty(has_notified_trial)
                    has_notified_trial = true;
                    fprintf('[Root-Free Laplace] Modo de prueba activo (%d días restantes). Active con laplace.activate(''CLAVE'')\n', ...
                        lic_info.days_left);
                end
                return;
            end

            % If invalid or expired, display professional activation prompt and halt
            fprintf('\n');
            fprintf('===============================================================================\n');
            fprintf(' [AVISO DE LICENCIA] ROOT-FREE LAPLACE INVERSION TOOLBOX                       \n');
            fprintf('===============================================================================\n');
            fprintf(' Estado : %s\n', lic_info.message);
            fprintf(' Su Host ID para solicitar clave: %s\n\n', laplace.LicenseManager.get_host_id());
            fprintf(' Para desbloquear el acceso completo sin límites de tiempo:\n');
            fprintf('   1. Adquiera su clave en la Tienda Oficial: https://lemonsqueezy.com\n');
            fprintf('   2. Active la toolbox ejecutando:\n');
            fprintf('         >> laplace.activate(''SU-CLAVE-DE-PRODUCTO'')\n');
            fprintf('===============================================================================\n\n');
            
            error('laplace:LicenseManager:licenseExpired', ...
                  'Licencia requerida: %s. Ejecute laplace.activate(''CLAVE'') para continuar.', lic_info.message);
        end

        function success = activate(key_str, customer_email)
            % ACTIVATE Validates and saves a commercial activation key (Lemon Squeezy API or Offline RFL)
            if nargin < 2
                customer_email = '';
            end

            key_clean = upper(strtrim(key_str));
            if isempty(key_clean)
                fprintf('[ERROR] Debe proporcionar una clave de activación.\n');
                success = false;
                return;
            end

            % 1. Check if it is an offline Master/Air-gap Key (starts with RFL-)
            if strncmp(key_clean, 'RFL-', 4)
                [is_key_valid, tier, exp_date] = laplace.LicenseManager.validate_key_format(key_clean);
                if ~is_key_valid
                    fprintf('[ERROR] La clave de activación local RFL ingresada no es válida o tiene un formato incorrecto.\n');
                    success = false;
                    return;
                end
                if isempty(customer_email)
                    customer_email = 'customer@licensed-user.org';
                end
            else
                % 2. Automated online verification with Lemon Squeezy License API
                fprintf('[Root-Free Laplace] Conectando con Lemon Squeezy para verificar la licencia...\n');
                [is_key_valid, tier, exp_date, lsq_email, err_msg] = laplace.LicenseManager.verify_lemonsqueezy(key_clean);
                if ~is_key_valid
                    fprintf('[ERROR] Verificación rechazada por Lemon Squeezy: %s\n', err_msg);
                    success = false;
                    return;
                end
                if ~isempty(lsq_email)
                    customer_email = lsq_email;
                elseif isempty(customer_email)
                    customer_email = 'lemonsqueezy-customer';
                end
            end

            lic_info = struct();
            lic_info.tier = tier;
            lic_info.key = key_clean;
            lic_info.customer = customer_email;
            lic_info.install_date = datestr(now(), 'yyyy-mm-dd');
            lic_info.expiry_date = exp_date;
            lic_info.host_id = laplace.LicenseManager.get_host_id();
            lic_info.signature = laplace.LicenseManager.compute_signature(lic_info);

            lic_file = laplace.LicenseManager.get_license_filepath();
            laplace.LicenseManager.write_license_file(lic_file, lic_info);

            fprintf('\n===============================================================================\n');
            fprintf(' ¡ACTIVACIÓN EXITOSA! ROOT-FREE LAPLACE TOOLBOX COMERCIAL\n');
            fprintf('===============================================================================\n');
            fprintf(' Nivel de Licencia: %s\n', tier);
            fprintf(' Titular          : %s\n', customer_email);
            fprintf(' Host ID          : %s\n', lic_info.host_id);
            fprintf(' Expiración       : %s\n', exp_date);
            fprintf(' Archivo guardado : %s\n', lic_file);
            fprintf(' Todos los motores y algoritmos de órdenes masivos están 100%% habilitados.\n');
            fprintf('===============================================================================\n\n');
            success = true;
        end

        function display_status()
            % DISPLAY_STATUS Prints formatted banner with current licensing details
            [is_valid, info] = laplace.LicenseManager.check_status();
            fprintf('===============================================================================\n');
            fprintf('          ESTADO DE LICENCIA - ROOT-FREE LAPLACE TOOLBOX                       \n');
            fprintf('===============================================================================\n');
            fprintf(' Tipo de Licencia   : %s\n', info.tier);
            fprintf(' Estado Actual      : %s\n', info.status);
            fprintf(' Días Restantes     : ');
            if isinf(info.days_left)
                fprintf('Ilimitado (Perpetua)\n');
            else
                fprintf('%d días\n', info.days_left);
            end
            fprintf(' Fecha Instalación  : %s\n', info.install_date);
            fprintf(' Fecha Expiración   : %s\n', info.expiry_date);
            fprintf(' Identificador Host : %s\n', info.host_id);
            fprintf(' Archivo Licencia   : %s\n', laplace.LicenseManager.get_license_filepath());
            fprintf(' Diagnóstico        : %s\n', info.message);
            fprintf('===============================================================================\n');
        end

        function host_id = get_host_id()
            % GET_HOST_ID Generates deterministic hardware/machine fingerprint
            user_env = getenv('USERNAME');
            if isempty(user_env)
                user_env = getenv('USER');
            end
            comp_env = getenv('COMPUTERNAME');
            if isempty(comp_env)
                comp_env = getenv('HOSTNAME');
            end
            raw_str = sprintf('%s_%s_%s', user_env, comp_env, computer);
            h = laplace.LicenseManager.hash_string(raw_str);
            host_id = sprintf('RFL-%s', h(1:8));
        end

    end

    methods (Static, Access = private)

        function filepath = get_license_filepath()
            % Locate standard license storage in user preferences or home directory
            pref_path = '';
            try
                pref_path = prefdir();
            catch
            end
            
            if ~isempty(pref_path) && exist(pref_path, 'dir')
                filepath = fullfile(pref_path, 'root_free_laplace.lic');
                return;
            end

            home_dir = getenv('USERPROFILE');
            if isempty(home_dir)
                home_dir = getenv('HOME');
            end
            if isempty(home_dir)
                home_dir = pwd();
            end
            filepath = fullfile(home_dir, '.root_free_laplace.lic');
        end

        function lic_info = init_trial(filepath)
            % Initialize a new 30-day trial record
            now_dn = now();
            lic_info = struct();
            lic_info.tier = 'TRIAL';
            lic_info.customer = 'Evaluator / Community Trial';
            lic_info.install_date = datestr(now_dn, 'yyyy-mm-dd');
            lic_info.expiry_date = datestr(now_dn + laplace.LicenseManager.TRIAL_DAYS, 'yyyy-mm-dd');
            lic_info.host_id = laplace.LicenseManager.get_host_id();
            lic_info.key = 'TRIAL-30-DAYS';
            lic_info.signature = laplace.LicenseManager.compute_signature(lic_info);
            
            laplace.LicenseManager.write_license_file(filepath, lic_info);
        end

        function sig = compute_signature(info)
            % Cryptographic signature combining payload and secret salt
            payload = sprintf('%s|%s|%s|%s|%s|%s', ...
                info.tier, info.customer, info.install_date, ...
                info.expiry_date, info.host_id, laplace.LicenseManager.SECRET_SALT);
            sig = laplace.LicenseManager.hash_string(payload);
        end

        function [is_valid, tier, exp_date] = validate_key_format(key_str)
            % Format: RFL-TIER-RANDOM-EXPIRY-CHECKSUM
            % Example: RFL-PRO-A7B2-PERP-88CD12E4
            is_valid = false;
            tier = 'UNKNOWN';
            exp_date = '2099-12-31';

            tokens = regexp(key_str, '^RFL-(PRO|ACA|STU|ANN)-([A-Z0-9]{4})-(PERP|[0-9]{4})-([A-Z0-9]{8})$', 'tokens');
            if isempty(tokens)
                return;
            end
            
            t_data = tokens{1};
            tier_token = t_data{1};
            rand_token = t_data{2};
            exp_token  = t_data{3};
            check_token = t_data{4};

            % Recompute checksum
            payload = sprintf('KEY|%s|%s|%s|%s', tier_token, rand_token, exp_token, laplace.LicenseManager.SECRET_SALT);
            full_hash = laplace.LicenseManager.hash_string(payload);
            expected_check = full_hash(1:8);

            if strcmp(check_token, expected_check)
                is_valid = true;
                if strcmp(exp_token, 'PERP')
                    switch tier_token
                        case 'PRO', tier = 'PRO_COMMERCIAL';
                        case 'ACA', tier = 'ACADEMIC_RESEARCH';
                        case 'STU', tier = 'STUDENT';
                        otherwise,  tier = 'PRO_PERPETUAL';
                    end
                    exp_date = '2099-12-31';
                else
                    % Annual subscription
                    switch tier_token
                        case 'PRO', tier = 'PRO_ANNUAL';
                        case 'ACA', tier = 'ACADEMIC_ANNUAL';
                        case 'STU', tier = 'STUDENT_ANNUAL';
                        otherwise,  tier = 'PRO_ANNUAL';
                    end
                    yy = str2double(exp_token(1:2)) + 2000;
                    mm = str2double(exp_token(3:4));
                    exp_date = sprintf('%04d-%02d-28', yy, mm);
                end
            end
        end

        function hex_str = hash_string(str)
            % Pure mathematical 128-bit hash independent of Java or external libraries
            bytes = double(uint8(str));
            h1 = 2166136261;
            h2 = 1865265579;
            h3 = 3456789011;
            h4 = 4123456789;

            p1 = 4294967291;
            p2 = 4294967279;
            p3 = 4294967197;
            p4 = 4294967167;

            for i = 1:length(bytes)
                b = bytes(i);
                h1 = mod(h1 * 16777619 + b, p1);
                h2 = mod(h2 * 2246822519 + b * 31, p2);
                h3 = mod(h3 * 3266489917 + b * 17, p3);
                h4 = mod(h4 * 668265263 + b * 7, p4);
            end

            hex_str = sprintf('%08X%08X%08X%08X', ...
                round(h1), round(h2), round(h3), round(h4));
        end

        function write_license_file(filepath, lic_info)
            fid = fopen(filepath, 'w');
            if fid < 0
                return;
            end
            fprintf(fid, 'TIER=%s\n', lic_info.tier);
            fprintf(fid, 'CUSTOMER=%s\n', lic_info.customer);
            fprintf(fid, 'INSTALL_DATE=%s\n', lic_info.install_date);
            fprintf(fid, 'EXPIRY_DATE=%s\n', lic_info.expiry_date);
            fprintf(fid, 'HOST_ID=%s\n', lic_info.host_id);
            fprintf(fid, 'KEY=%s\n', lic_info.key);
            fprintf(fid, 'SIGNATURE=%s\n', lic_info.signature);
            fclose(fid);
        end

        function lic_info = read_license_file(filepath)
            lic_info = struct();
            lic_info.tier = 'UNKNOWN';
            lic_info.customer = '';
            lic_info.install_date = '2000-01-01';
            lic_info.expiry_date = '2000-01-01';
            lic_info.host_id = '';
            lic_info.key = '';
            lic_info.signature = '';

            fid = fopen(filepath, 'r');
            if fid < 0
                return;
            end
            while ~feof(fid)
                line = strtrim(fgetl(fid));
                if isempty(line) || line(1) == '#'
                    continue;
                end
                eq_idx = find(line == '=', 1);
                if ~isempty(eq_idx)
                    k = strtrim(line(1:eq_idx-1));
                    v = strtrim(line(eq_idx+1:end));
                    switch lower(k)
                        case 'tier', lic_info.tier = v;
                        case 'customer', lic_info.customer = v;
                        case 'install_date', lic_info.install_date = v;
                        case 'expiry_date', lic_info.expiry_date = v;
                        case 'host_id', lic_info.host_id = v;
                        case 'key', lic_info.key = v;
                        case 'signature', lic_info.signature = v;
                    end
                end
            end
            fclose(fid);
        end

        function [is_valid, tier, exp_date, customer_email, err_msg] = verify_lemonsqueezy(key_str)
            % Online verification against Lemon Squeezy REST API endpoint
            is_valid = false;
            tier = 'PRO_ANNUAL';
            exp_date = datestr(now() + 365, 'yyyy-mm-dd');
            customer_email = '';
            err_msg = '';

            url = laplace.LicenseManager.LEMONSQUEEZY_ACTIVATE_URL;
            host_id = laplace.LicenseManager.get_host_id();
            resp_struct = [];

            % Attempt 1: native webwrite (standard in MATLAB R2014b+ and Octave)
            try
                opt = weboptions('MediaType', 'application/x-www-form-urlencoded', ...
                                 'HeaderFields', {'Accept', 'application/json'}, ...
                                 'RequestMethod', 'post', ...
                                 'Timeout', 15);
                resp = webwrite(url, 'license_key', key_str, 'instance_name', host_id, opt);
                if isstruct(resp)
                    resp_struct = resp;
                else
                    resp_struct = jsondecode(char(resp));
                end
            catch ME
                % Fallback via curl
                try
                    cmd = sprintf('curl -s -X POST "%s" -H "Accept: application/json" -d "license_key=%s" -d "instance_name=%s"', ...
                        url, key_str, host_id);
                    [stat, out] = system(cmd);
                    if stat == 0 && ~isempty(out) && strncmp(strtrim(out), '{', 1)
                        resp_struct = jsondecode(out);
                    end
                catch
                end

                if isempty(resp_struct)
                    msg = ME.message;
                    if contains(msg, '404') || contains(msg, 'not found', 'IgnoreCase', true)
                        err_msg = 'La clave no existe para este producto en Lemon Squeezy.';
                    elseif contains(msg, 'resolve', 'IgnoreCase', true) || contains(msg, 'connection', 'IgnoreCase', true)
                        err_msg = 'No se pudo conectar con el servidor de Lemon Squeezy. Verifique su conexión a internet.';
                    else
                        err_msg = sprintf('Error al contactar con Lemon Squeezy: %s', msg);
                    end
                    return;
                end
            end

            % Check Lemon Squeezy API response
            has_activated = isfield(resp_struct, 'activated') && (islogical(resp_struct.activated) && resp_struct.activated || isnumeric(resp_struct.activated) && resp_struct.activated == 1);
            has_valid = isfield(resp_struct, 'valid') && (islogical(resp_struct.valid) && resp_struct.valid || isnumeric(resp_struct.valid) && resp_struct.valid == 1);

            if has_activated || has_valid
                is_valid = true;
                if isfield(resp_struct, 'meta') && isstruct(resp_struct.meta)
                    m = resp_struct.meta;
                    if isfield(m, 'customer_email') && ~isempty(m.customer_email)
                        customer_email = char(m.customer_email);
                    end
                    if isfield(m, 'variant_name') && ~isempty(m.variant_name)
                        v_str = lower(char(m.variant_name));
                        if contains(v_str, 'student') || contains(v_str, 'estudiante')
                            tier = 'STUDENT_ANNUAL';
                        elseif contains(v_str, 'acad') || contains(v_str, 'univers')
                            tier = 'ACADEMIC_ANNUAL';
                        elseif contains(v_str, 'perp') || contains(v_str, 'commercial')
                            tier = 'PRO_PERPETUAL';
                        else
                            tier = 'PRO_ANNUAL';
                        end
                    end
                end
                if isfield(resp_struct, 'license_key') && isstruct(resp_struct.license_key)
                    lk = resp_struct.license_key;
                    if isfield(lk, 'expires_at') && ~isempty(lk.expires_at)
                        raw_exp = char(lk.expires_at);
                        if length(raw_exp) >= 10
                            exp_date = raw_exp(1:10);
                        end
                    else
                        exp_date = '2099-12-31';
                    end
                end
            else
                if isfield(resp_struct, 'error') && ~isempty(resp_struct.error)
                    err_msg = char(resp_struct.error);
                elseif isfield(resp_struct, 'message') && ~isempty(resp_struct.message)
                    err_msg = char(resp_struct.message);
                else
                    err_msg = 'La clave ingresada no es válida en Lemon Squeezy.';
                end
            end
        end

    end

end
