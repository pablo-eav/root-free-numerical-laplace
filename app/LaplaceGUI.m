function LaplaceGUI()
% LAPLACEGUI Graphical User Interface for Root-Free Numerical Laplace Inversion
%
%   LaplaceGUI() launches the interactive desktop studio for root-free
%   inversion of rational Laplace transforms with orders up to 1,000,000.
%
%   Features:
%       - Dual interactive visualization (response curve + error/diagnostics)
%       - Catalog of engineering presets (resonators, ladders, cascades, diffusion)
%       - Real-time Fujiwara spectral bound and safe causal horizon monitoring
%       - Engine dispatcher selection (Auto, Stirling, Laguerre, Taylor)
%       - Export to MATLAB Workspace, CSV, and Publication Figures
%
%   Part of the Root-Free Laplace Inversion Toolbox.

    % Create figure window
    fig = figure('Name', 'Root-Free Laplace Inversion Studio', ...
                 'NumberTitle', 'off', ...
                 'Color', [0.94, 0.95, 0.96], ...
                 'Position', [100, 80, 1150, 720], ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'figure');
    try
        theme(fig, 'light');
    catch
    end

    % Left control panel
    ctrl_panel = uipanel('Parent', fig, ...
                         'Title', ' Configuración y Parámetros ', ...
                         'FontSize', 10, 'FontWeight', 'bold', ...
                         'BackgroundColor', [0.94, 0.95, 0.96], ...
                         'ForegroundColor', [0.1, 0.1, 0.1], ...
                         'Position', [0.015, 0.02, 0.32, 0.96]);

    % Presets Dropdown
    uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Caso Predefinido (Presets):', ...
              'HorizontalAlignment', 'left', 'FontWeight', 'bold', ...
              'BackgroundColor', [0.94, 0.95, 0.96], 'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Units', 'normalized', 'Position', [0.05, 0.94, 0.9, 0.03]);
          
    preset_items = {
        '1. Oscilador Racional 2º Orden: 1 / (s^2 + 2s + 2)', ...
        '2. Doble Resonancia (Batimiento): s / ((s^2 + 1)(s^2 + 2.25))', ...
        '3. Fracción General con Ceros (Grado 4): (s + 3) / (s^4 + 6s^3 + 23s^2 + 34s + 26)', ...
        '4. Filtro Butterworth 6º Orden: 1 / (s^6 + 3.86s^5 + ... + 1)', ...
        '5. Cascada de Alto Orden (K=100): 1 / (s + 0.5)^100', ...
        '6. Resonador Polimodal Masivo (K=10,000): (s^9999 - 2*s^9998) / (s^10000 + 1)'
    };
    
    preset_popup = uicontrol('Parent', ctrl_panel, 'Style', 'popupmenu', ...
                             'String', preset_items, 'Value', 1, ...
                             'Units', 'normalized', 'Position', [0.05, 0.90, 0.9, 0.04], ...
                             'Callback', @on_preset_selected);

    % Numerator input
    uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Numerador A(s): [coeficientes en s, ej: [1 3] o escalar]', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94, 0.95, 0.96], 'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Units', 'normalized', 'Position', [0.05, 0.84, 0.9, 0.03]);
    num_edit = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '1', ...
                         'HorizontalAlignment', 'left', 'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
                         'Units', 'normalized', 'Position', [0.05, 0.80, 0.9, 0.038]);

    % Denominator input
    uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Denominador B(s): [coeficientes en s, ej: [1 2 2] o FactorPoly]', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94, 0.95, 0.96], 'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Units', 'normalized', 'Position', [0.05, 0.74, 0.9, 0.03]);
    den_edit = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '[1, 2, 2]', ...
                         'HorizontalAlignment', 'left', 'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
                         'Units', 'normalized', 'Position', [0.05, 0.70, 0.9, 0.038]);

    % Time window inputs
    uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Ventana Temporal [z_min, z_max]:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94, 0.95, 0.96], 'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Units', 'normalized', 'Position', [0.05, 0.64, 0.9, 0.03]);
    z_min_edit = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '0.0', ...
                           'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
                           'Units', 'normalized', 'Position', [0.05, 0.60, 0.42, 0.038]);
    z_max_edit = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '10.0', ...
                           'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
                           'Units', 'normalized', 'Position', [0.53, 0.60, 0.42, 0.038]);

    % Number of points
    uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Puntos de Evaluación M:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94, 0.95, 0.96], 'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Units', 'normalized', 'Position', [0.05, 0.54, 0.9, 0.03]);
    pts_edit = uicontrol('Parent', ctrl_panel, 'Style', 'edit', 'String', '500', ...
                         'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
                         'Units', 'normalized', 'Position', [0.05, 0.50, 0.9, 0.038]);

    % Engine Selection Dropdown
    uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Motor de Inversión:', ...
              'HorizontalAlignment', 'left', 'FontWeight', 'bold', ...
              'BackgroundColor', [0.94, 0.95, 0.96], 'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Units', 'normalized', 'Position', [0.05, 0.44, 0.9, 0.03]);
    engine_items = {
        'Auto (Híbrido Inteligente - Recomendado)', ...
        'Levin AR(2) (División Laurent Root-Free)', ...
        'Laurent-Stirling (Float64)', ...
        'Möbius-Laguerre (Float64)', ...
        'Prolongación Adaptativa Taylor-Laguerre'
    };
    engine_popup = uicontrol('Parent', ctrl_panel, 'Style', 'popupmenu', ...
                             'String', engine_items, 'Value', 1, ...
                             'Units', 'normalized', 'Position', [0.05, 0.40, 0.9, 0.04]);

    % Invert Button
    uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', ...
              'String', '▶ INVERTIR TRANSFORMADA', ...
              'FontWeight', 'bold', 'FontSize', 11, ...
              'BackgroundColor', [0.15, 0.45, 0.85], 'ForegroundColor', 'w', ...
              'Units', 'normalized', 'Position', [0.05, 0.32, 0.9, 0.06], ...
              'Callback', @on_invert_clicked);

    % Diagnostic Info Area
    uicontrol('Parent', ctrl_panel, 'Style', 'text', 'String', 'Diagnóstico y Rendimiento:', ...
              'HorizontalAlignment', 'left', 'FontWeight', 'bold', ...
              'BackgroundColor', [0.94, 0.95, 0.96], 'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Units', 'normalized', 'Position', [0.05, 0.26, 0.9, 0.03]);
    diag_text = uicontrol('Parent', ctrl_panel, 'Style', 'edit', ...
                          'Max', 2, 'HorizontalAlignment', 'left', ...
                          'Enable', 'inactive', 'BackgroundColor', [0.98, 0.98, 0.99], ...
                          'ForegroundColor', [0.1, 0.1, 0.1], ...
                          'FontName', 'FixedWidth', 'FontSize', 8.5, ...
                          'Units', 'normalized', 'Position', [0.05, 0.11, 0.9, 0.14]);

    % Export Buttons
    uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', ...
              'String', 'Exportar a Workspace', ...
              'Units', 'normalized', 'Position', [0.05, 0.02, 0.42, 0.04], ...
              'Callback', @on_export_workspace);
    uicontrol('Parent', ctrl_panel, 'Style', 'pushbutton', ...
              'String', 'Exportar CSV', ...
              'Units', 'normalized', 'Position', [0.53, 0.02, 0.42, 0.04], ...
              'Callback', @on_export_csv);

    % Right Display Panel with Dual Subplots
    display_panel = uipanel('Parent', fig, ...
                            'Title', ' Visualización Gráfica ', ...
                            'FontSize', 10, 'FontWeight', 'bold', ...
                            'BackgroundColor', [0.97, 0.97, 0.98], ...
                            'ForegroundColor', [0.1, 0.1, 0.1], ...
                            'Position', [0.35, 0.02, 0.635, 0.96]);

    ax_main = subplot(2, 1, 1, 'Parent', display_panel);
    grid(ax_main, 'on');
    box(ax_main, 'on');
    set(ax_main, 'Color', [1, 1, 1], 'XColor', [0.1, 0.1, 0.1], 'YColor', [0.1, 0.1, 0.1], ...
                 'GridColor', [0.8, 0.8, 0.8], 'GridAlpha', 0.6, ...
                 'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 1.2);
    title(ax_main, 'Respuesta Temporal Invertida f(z)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05, 0.05, 0.05]);
    xlabel(ax_main, 'Tiempo z (s)', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);
    ylabel(ax_main, 'f(z)', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);

    ax_err = subplot(2, 1, 2, 'Parent', display_panel);
    grid(ax_err, 'on');
    box(ax_err, 'on');
    set(ax_err, 'Color', [1, 1, 1], 'XColor', [0.1, 0.1, 0.1], 'YColor', [0.1, 0.1, 0.1], ...
                 'GridColor', [0.8, 0.8, 0.8], 'GridAlpha', 0.6, ...
                 'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 1.2);
    title(ax_err, 'Diagnóstico de Error Absoluto Logarítmico', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05, 0.05, 0.05]);
    xlabel(ax_err, 'Tiempo z (s)', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);
    ylabel(ax_err, '|Error|', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);

    % State storage
    app_data = struct('z', [], 'f_inv', [], 'f_exact', [], 'info', []);

    % Run default inversion
    on_invert_clicked();

    % -------------------------------------------------------------
    % CALLBACK FUNCTIONS
    % -------------------------------------------------------------
    function on_preset_selected(~, ~)
        val = preset_popup.Value;
        switch val
            case 1 % Subamortiguado
                num_edit.String = '1';
                den_edit.String = '[1, 2, 2]';
                z_min_edit.String = '0.0';
                z_max_edit.String = '10.0';
                engine_popup.Value = 1;
            case 2 % Doble Resonancia (Batimiento)
                num_edit.String = '[1, 0]';
                den_edit.String = '[1, 0, 3.25, 0, 2.25]';
                z_min_edit.String = '0.0';
                z_max_edit.String = '25.0';
                engine_popup.Value = 1;
            case 3 % Racional con ceros y polos (Grado 4)
                num_edit.String = '[1, 3]';
                den_edit.String = '[1, 6, 23, 34, 26]';
                z_min_edit.String = '0.0';
                z_max_edit.String = '8.0';
                engine_popup.Value = 1;
            case 4 % Butterworth 6º Orden
                num_edit.String = '1';
                den_edit.String = '[1, 3.8637, 7.4641, 9.1416, 7.4641, 3.8637, 1.0]';
                z_min_edit.String = '0.0';
                z_max_edit.String = '15.0';
                engine_popup.Value = 1;
            case 5 % Cascada Alto Orden K=100
                num_edit.String = '1';
                den_edit.String = 'laplace.FactorPoly(-0.5*ones(100,1))';
                z_min_edit.String = '0.0';
                z_max_edit.String = '80.0';
                engine_popup.Value = 1;
            case 6 % Resonador Polimodal Masivo K = 10,000 (Sin cálculo de raíces)
                num_edit.String = '[1, -2, zeros(1, 9998)]';
                den_edit.String = '[1, zeros(1, 9999), 1]';
                z_min_edit.String = '0.0';
                z_max_edit.String = '5.0';
                engine_popup.Value = 1;
        end
        on_invert_clicked();
    end

    function on_invert_clicked(~, ~)
        try
            import laplace.*

            z_min = str2double(z_min_edit.String);
            z_max = str2double(z_max_edit.String);
            N_pts = round(str2double(pts_edit.String));
            z_grid = linspace(z_min, z_max, N_pts);

            den_str = strtrim(den_edit.String);
            num_str = strtrim(num_edit.String);

            % Auto-wrap brackets if user typed numbers without brackets (e.g. '1 2 2' or '1, 2, 2')
            if ~startsWith(den_str, '[') && ~startsWith(den_str, 'laplace.') && ...
               ~startsWith(den_str, 'FactorPoly') && ~startsWith(den_str, 'PartialFractions') && ...
               ~startsWith(den_str, 'prod') && (any(den_str == ' ') || any(den_str == ','))
                den_str = ['[' den_str ']'];
            end
            if ~isempty(num_str) && ~strcmp(num_str, '[]') && ...
               ~startsWith(num_str, '[') && ~startsWith(num_str, 'laplace.') && ...
               ~startsWith(num_str, 'FactorPoly') && ~startsWith(num_str, 'PartialFractions') && ...
               ~startsWith(num_str, 'prod') && (any(num_str == ' ') || any(num_str == ','))
                num_str = ['[' num_str ']'];
            end

            % Evaluate Denominator
            if startsWith(den_str, 'FactorPoly') || startsWith(den_str, 'PartialFractions')
                den_str = ['laplace.' den_str];
            end
            den_str = strrep(den_str, '[0;', '[0,');
            den_obj = eval(den_str);

            % Evaluate Numerator (default to 1 if empty)
            if isempty(num_str) || strcmp(num_str, '[]')
                num_obj = 1;
            else
                if startsWith(num_str, 'FactorPoly') || startsWith(num_str, 'PartialFractions')
                    num_str = ['laplace.' num_str];
                end
                num_obj = eval(num_str);
            end

            % Engine selection
            eng_val = engine_popup.Value;
            switch eng_val
                case 1, eng_choice = 'Auto';
                case 2, eng_choice = 'Levin';
                case 3, eng_choice = 'Stirling';
                case 4, eng_choice = 'Laguerre';
                case 5, eng_choice = 'TaylorAdaptive';
            end

            opts = struct('engine', eng_choice, 'tol', 1e-4);

            t_start = tic;
            [f_inv, info] = laplace.invert(num_obj, den_obj, z_grid, opts);
            elapsed_ms = toc(t_start) * 1000;

            % Save app data
            app_data.z = z_grid;
            app_data.f_inv = f_inv;
            app_data.info = info;

            % Update diagnostic text
            diag_str = sprintf(['Motor: %s\n' ...
                                'Términos: %d | Precisión: %d bits\n' ...
                                'Horizonte Seguro z_fuj: %.3f s\n' ...
                                'Tiempo de Ejecución: %.3f ms'], ...
                                info.engine, info.terms, info.dps, info.z_fuj, elapsed_ms);
            diag_text.String = diag_str;

            % Plot main
            cla(ax_main);
            plot(ax_main, z_grid, f_inv, '-', 'Color', [0.0, 0.4, 0.85], 'LineWidth', 2.0, 'DisplayName', info.engine);
            grid(ax_main, 'on');
            box(ax_main, 'on');
            lgd = legend(ax_main, 'Location', 'best');
            set(lgd, 'Color', [1 1 1], 'TextColor', [0.1 0.1 0.1], 'EdgeColor', [0.75 0.75 0.75]);
            set(ax_main, 'Color', [1, 1, 1], 'XColor', [0.1, 0.1, 0.1], 'YColor', [0.1, 0.1, 0.1], ...
                         'GridColor', [0.8, 0.8, 0.8], 'GridAlpha', 0.6, ...
                         'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 1.2);
            title(ax_main, sprintf('Respuesta Invertida f(z) [%s]', info.engine), 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05, 0.05, 0.05]);
            xlabel(ax_main, 'Tiempo z (s)', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);
            ylabel(ax_main, 'f(z)', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);

            % Compute analytical reference if standard preset
            cla(ax_err);
            if preset_popup.Value == 1
                f_ref = exp(-z_grid) .* sin(z_grid);
                hold(ax_main, 'on');
                plot(ax_main, z_grid, f_ref, '--', 'Color', [0.85, 0.15, 0.15], 'LineWidth', 1.6, 'DisplayName', 'Exacto');
                err = abs(f_inv - f_ref);
                semilogy(ax_err, z_grid, max(err, 1e-17), '-', 'Color', [0.85, 0.15, 0.15], 'LineWidth', 1.6);
                title(ax_err, sprintf('Error Absoluto frente a Solución Exacta (Max: %.2e)', max(err)), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05, 0.05, 0.05]);
            elseif preset_popup.Value == 2
                f_ref = 0.8 * (cos(z_grid) - cos(1.5 * z_grid));
                hold(ax_main, 'on');
                plot(ax_main, z_grid, f_ref, '--', 'Color', [0.85, 0.15, 0.15], 'LineWidth', 1.6, 'DisplayName', 'Exacto (Batimiento)');
                err = abs(f_inv - f_ref);
                semilogy(ax_err, z_grid, max(err, 1e-17), '-', 'Color', [0.85, 0.15, 0.15], 'LineWidth', 1.6);
                title(ax_err, sprintf('Error Absoluto frente a Solución Exacta (Max: %.2e)', max(err)), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05, 0.05, 0.05]);
            elseif preset_popup.Value == 6
                f_ref = 1.0 - 2.0 * z_grid;
                hold(ax_main, 'on');
                plot(ax_main, z_grid, f_ref, '--', 'Color', [0.85, 0.15, 0.15], 'LineWidth', 1.6, 'DisplayName', 'Exacto: f(z) = 1 - 2z');
                err = abs(f_inv - f_ref);
                semilogy(ax_err, z_grid, max(err, 1e-16), '-', 'Color', [0.85, 0.15, 0.15], 'LineWidth', 1.6);
                title(ax_err, sprintf('Error frente a Solución Exacta Polimodal K=10,000 (Max: %.2e)', max(err)), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05, 0.05, 0.05]);
            else
                plot(ax_err, z_grid, abs(f_inv), '-', 'Color', [0.55, 0.1, 0.65], 'LineWidth', 1.6);
                title(ax_err, 'Magnitud Absoluta |f(z)|', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05, 0.05, 0.05]);
            end
            grid(ax_err, 'on');
            box(ax_err, 'on');
            set(ax_err, 'Color', [1, 1, 1], 'XColor', [0.1, 0.1, 0.1], 'YColor', [0.1, 0.1, 0.1], ...
                         'GridColor', [0.8, 0.8, 0.8], 'GridAlpha', 0.6, ...
                         'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 1.2);
            xlabel(ax_err, 'Tiempo z (s)', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);
            ylabel(ax_err, 'Amplitud / |Error|', 'FontWeight', 'bold', 'Color', [0.1, 0.1, 0.1]);

        catch ME
            errordlg(sprintf('Error durante la inversión: %s', ME.message), 'Error de Ejecución');
        end
    end

    function on_export_workspace(~, ~)
        if isempty(app_data.z)
            warndlg('No hay datos calculados para exportar.', 'Aviso');
            return;
        end
        assignin('base', 'laplace_z', app_data.z);
        assignin('base', 'laplace_f', app_data.f_inv);
        assignin('base', 'laplace_info', app_data.info);
        msgbox('Variables laplace_z, laplace_f y laplace_info exportadas exitosamente al Workspace.', 'Exportación Exitosa');
    end

    function on_export_csv(~, ~)
        if isempty(app_data.z)
            warndlg('No hay datos calculados para exportar.', 'Aviso');
            return;
        end
        [filename, pathname] = uiputfile('*.csv', 'Guardar Datos Invertidos', 'laplace_inversion_results.csv');
        if isequal(filename, 0) || isequal(pathname, 0)
            return;
        end
        full_path = fullfile(pathname, filename);
        T = table(app_data.z(:), app_data.f_inv(:), 'VariableNames', {'Tiempo_z', 'f_z'});
        writetable(T, full_path);
        msgbox(sprintf('Archivo CSV guardado en:\n%s', full_path), 'Exportación CSV Exitosa');
    end

end
