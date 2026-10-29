% PLOT_RESULTS  Publication-oriented Model A figures and saved plot data.
% Implements: Section IV.C (forward fields) and Section IV.D (sensitivity).
clear; close all; clc;

P0 = cceit_params();
plot_dir = fileparts(mfilename('fullpath'));
if isempty(plot_dir), plot_dir = pwd; end
n = P0.nElec;
eidors_cache clear
[fA, iA] = cceit_mesh_A(P0);
omega0 = 2*pi*P0.f;
gamma0 = P0.sigma + 1i*omega0*P0.eps0*P0.epsr;
z_contact_A = 1 / (P0.sigma_d/P0.d + 1i*omega0*P0.eps0*P0.epsr_d/P0.d);
for e = 1:n
    fA.electrode(e).z_contact = z_contact_A;
end
gamma_A = gamma0 * ones(size(fA.elems, 1), 1);

%% Pair map: magnitude and phase
out = cceit_pairscan(fA, gamma_A, P0);
Ymap = out.Y;
Ymap(logical(eye(n))) = NaN;  % The diagonal is not a measured pair.

fig1 = figure('Name', 'Model A pair admittance', ...
    'Position', [80 80 1250 560], 'Color', 'w');
subplot(1, 2, 1);
imagesc(abs(Ymap) * 1e4);
axis image;
set(gca, 'YDir', 'normal', 'FontSize', 11, 'LineWidth', 0.8);
colormap(gca, jet(256));
colorbar;
xlabel('Receiver electrode'); ylabel('Transmitter electrode');
title({'|Y_{tr}| (10^{-4}, per m depth)', 'Black diagonal: not measured'});

subplot(1, 2, 2);
imagesc(angle(Ymap) * 180/pi);
axis image;
set(gca, 'YDir', 'normal', 'FontSize', 11, 'LineWidth', 0.8);
colormap(gca, jet(256));
colorbar;
xlabel('Receiver electrode'); ylabel('Transmitter electrode');
title('Phase(Y_{tr}) (degrees)');
print('-dpng', sprintf('-r%d', P0.plot_export_dpi), fullfile(plot_dir, 'fig1_Ymap.png'));

%% Pair response by electrode separation
separation = min(out.pairs(:,2) - out.pairs(:,1), ...
    n - (out.pairs(:,2) - out.pairs(:,1)));
pair_index = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
y_pair = out.Y(pair_index);
separation_values = unique(separation(:)).';
mag_median = zeros(size(separation_values));
mag_low = zeros(size(separation_values));
mag_high = zeros(size(separation_values));
phase_median = zeros(size(separation_values));
phase_low = zeros(size(separation_values));
phase_high = zeros(size(separation_values));
for k = 1:numel(separation_values)
    use_pair = separation == separation_values(k);
    mag_group = abs(y_pair(use_pair));
    phase_group = angle(y_pair(use_pair)) * 180/pi;
    mag_median(k) = median(mag_group);
    mag_low(k) = mag_median(k) - min(mag_group);
    mag_high(k) = max(mag_group) - mag_median(k);
    phase_median(k) = median(phase_group);
    phase_low(k) = phase_median(k) - min(phase_group);
    phase_high(k) = max(phase_group) - phase_median(k);
end

fig2 = figure('Name', 'Pair response by separation', ...
    'Position', [80 80 1250 560], 'Color', 'w');
subplot(1, 2, 1);
h_mag_pairs = plot(separation, abs(y_pair), 'o', 'Color', [0.25 0.48 0.72], ...
    'MarkerSize', 4); hold on;
for k = 1:numel(separation_values)
    plot([separation_values(k) separation_values(k)], ...
        [mag_median(k)-mag_low(k) mag_median(k)+mag_high(k)], ...
        'k-', 'LineWidth', 1.2);
end
h_mag_summary = plot(separation_values, mag_median, 'ks-', 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'k', 'MarkerSize', 5);
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 0.8, 'XTick', separation_values);
xlim([min(separation_values)-0.4, max(separation_values)+0.4]);
xlabel('Electrode separation'); ylabel('|Y_{tr}| (per m depth)');
title('Admittance magnitude');
legend([h_mag_pairs h_mag_summary], {'Individual pairs', 'Median and range'}, ...
    'Location', 'northeast');

subplot(1, 2, 2);
h_phase_pairs = plot(separation, angle(y_pair)*180/pi, 'o', ...
    'Color', [0.25 0.48 0.72], ...
    'MarkerSize', 4); hold on;
for k = 1:numel(separation_values)
    plot([separation_values(k) separation_values(k)], ...
        [phase_median(k)-phase_low(k) phase_median(k)+phase_high(k)], ...
        'k-', 'LineWidth', 1.2);
end
h_phase_summary = plot(separation_values, phase_median, 'ks-', 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'k', 'MarkerSize', 5);
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 0.8, 'XTick', separation_values);
xlim([min(separation_values)-0.4, max(separation_values)+0.4]);
xlabel('Electrode separation'); ylabel('Phase(Y_{tr}) (degrees)');
title('Admittance phase');
legend([h_phase_pairs h_phase_summary], ...
    {'Individual pairs', 'Median and range'}, 'Location', 'northeast');
print('-dpng', sprintf('-r%d', P0.plot_export_dpi), ...
    fullfile(plot_dir, 'fig2_Y_vs_separation.png'));

%% Current-density magnitude and direction field for pair (1,9)
tx = 1;
rx = 9;
stim.stim_pattern = zeros(n, 1);
stim.volt_pattern = zeros(n, 1);
stim.stim_pattern([tx rx]) = NaN;
stim.volt_pattern(tx) = P0.Vtx;
stim.volt_pattern(rx) = 0;
stim.meas_pattern = eye(n);
fA.stimulation = stim;
img = mk_image(fA, gamma_A);
img.fwd_solve.get_all_meas = 1;
img.fwd_solve.get_elec_curr = 1;
data = fwd_solve(img);
Vnode = data.volt(1:size(fA.nodes, 1), 1);

fig3 = figure('Name', 'Current-density field, pair 1-9', ...
    'Position', [100 60 900 820], 'Color', 'w');
J_elem = calc_elem_current(img, Vnode);
J_elem_mag = sqrt(abs(J_elem(:,1)).^2 + abs(J_elem(:,2)).^2);
patch('Faces', fA.elems, 'Vertices', fA.nodes(:,1:2), ...
    'FaceVertexCData', J_elem_mag, 'FaceColor', 'flat', ...
    'EdgeColor', [0.68 0.68 0.68], 'LineWidth', 0.25);
hold on;
theta = linspace(0, 2*pi, 300);
plot(P0.R*cos(theta), P0.R*sin(theta), 'k-', 'LineWidth', 1.2);
for e = 1:n
    electrode_nodes = fA.electrode(e).nodes;
    if e == tx
        electrode_color = [0.85 0.1 0.1];
    elseif e == rx
        electrode_color = [0.1 0.2 0.85];
    else
        electrode_color = [0.15 0.15 0.15];
    end
    plot(fA.nodes(electrode_nodes,1), fA.nodes(electrode_nodes,2), ...
        '-', 'Color', electrode_color, 'LineWidth', 2.2);
end
imgQ = img;
imgQ.fwd_model.mdl_slice_mapper.npx = P0.plot_field_grid_points;
imgQ.fwd_model.mdl_slice_mapper.npy = P0.plot_field_grid_points;
q = show_current(imgQ, Vnode);
q_x = real(q.xc);
q_y = real(q.yc);
q_dir_mag = hypot(q_x, q_y);
q_mag = hypot(abs(q.xc), abs(q.yc));
if isvector(q.xp) && isvector(q.yp)
    [q_xp, q_yp] = meshgrid(q.xp, q.yp);
else
    q_xp = q.xp;
    q_yp = q.yp;
end
valid_q = isfinite(q_xp) & isfinite(q_yp) & isfinite(q_dir_mag) & ...
    isfinite(q_mag) & q_dir_mag > 0 & hypot(q_xp, q_yp) <= P0.R;
if any(valid_q(:))
    arrow_spacing_m = 2*P0.R / (P0.plot_field_grid_points - 1);
    arrow_length_m = P0.plot_arrow_grid_frac * arrow_spacing_m;
    quiver(q_xp(valid_q), q_yp(valid_q), ...
        arrow_length_m*q_x(valid_q)./q_dir_mag(valid_q), ...
        arrow_length_m*q_y(valid_q)./q_dir_mag(valid_q), ...
        0, 'k', 'LineWidth', 1.1);
end
axis equal tight;
set(gca, 'FontSize', 11, 'LineWidth', 0.8);
cb = colorbar;
set(get(cb, 'ylabel'), 'String', '|J| (A/m^2)');
title(sprintf(['Current-density magnitude and Re(J) direction, ' ...
    'tx=%d at %.2f V, rx=%d at 0 V'], tx, P0.Vtx, rx), 'FontSize', 13);
fig3_path = fullfile(plot_dir, 'fig3_field_1_9.png');
try
    print('-dpng', sprintf('-r%d', P0.plot_export_dpi), fig3_path);
catch export_error
    fallback_fig3_path = fullfile(P0.outdir, 'fig3_field_1_9.png');
    try
        print('-dpng', sprintf('-r%d', P0.plot_export_dpi), fallback_fig3_path);
        warning('plot_results: Fig. 3 could not overwrite %s; saved it to %s', ...
            fig3_path, fallback_fig3_path);
    catch fallback_error
        error('plot_results: unable to export Fig. 3 to %s (%s) or %s (%s)', ...
            fig3_path, export_error.message, fallback_fig3_path, fallback_error.message);
    end
end

%% Model A frequency response
y0 = cceit_runA_mesh(fA, P0, P0.f);
freqs = [10e3 30e3 100e3 300e3 500e3 1e6 3e6];
Yf = zeros(numel(freqs), 1);
for j = 1:numel(freqs)
    y_freq = cceit_runA_mesh(fA, P0, freqs(j));
    Yf(j) = median(abs(y_freq));
end
fig4a = figure('Name', 'Model A frequency response', ...
    'Position', [100 100 900 650], 'Color', 'w');
loglog(freqs, Yf, 'o-', 'LineWidth', 1.8, 'MarkerSize', 7, ...
    'MarkerFaceColor', [0.18 0.46 0.70]);
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 0.8);
xlim([min(freqs)*0.8, max(freqs)*1.2]);
xlabel('Frequency (Hz)'); ylabel('Median |Y_{tr}| (per m depth)');
title('Frequency sweep, Model A');
print('-dpng', sprintf('-r%d', P0.plot_export_dpi), fullfile(plot_dir, 'fig4a_freq.png'));

%% Model A layer response from the saved A2 sweep
a2_path = 'sweepA2_results.mat';
if exist(a2_path, 'file')
    A2 = load(a2_path);
    if isfield(A2, 'res') && isfield(A2, 'P0') && ...
            abs(A2.P0.sigma - P0.sigma) < 1e-12 && ...
            abs(A2.P0.epsr - P0.epsr) < 1e-12 && ...
            abs(A2.P0.d - P0.d) < 1e-12 && ...
            abs(A2.P0.epsr_d - P0.epsr_d) < 1e-12 && ...
            abs(A2.P0.sigma_d - P0.sigma_d) < 1e-15 && ...
            abs(A2.P0.f - P0.f) < 1e-6 && ...
            abs(A2.P0.h_int - P0.h_int) < 1e-12 && ...
            abs(A2.P0.R - P0.R) < 1e-12 && ...
            abs(A2.P0.w_el - P0.w_el) < 1e-12
        d_idx = find(strcmp({A2.res.name}, 'd'), 1);
        er_idx = find(strcmp({A2.res.name}, 'epsr_d'), 1);
        sd_idx = find(strcmp({A2.res.name}, 'sigma_d'), 1);
        if ~isempty(d_idx) && ~isempty(er_idx) && ~isempty(sd_idx)
            d_values_mm = A2.res(d_idx).vals * 1e3;
            d_delta = A2.res(d_idx).delta;
            er_values = A2.res(er_idx).vals;
            er_delta = A2.res(er_idx).delta;
            sd_values = A2.res(sd_idx).vals;
            sd_delta = A2.res(sd_idx).delta;

            fig4b = figure('Name', 'Model A layer response', ...
                'Position', [50 100 1450 560], 'Color', 'w');
            ax_d = subplot(1, 3, 1);
            hold(ax_d, 'on'); grid(ax_d, 'on'); box(ax_d, 'on');
            d_base = find(abs(d_values_mm - P0.d*1e3) < 1e-9, 1);
            d_other = setdiff(1:numel(d_values_mm), d_base);
            h_sweep = plot(ax_d, d_values_mm(d_other), d_delta(d_other), ...
                'o', 'Color', [0.12 0.43 0.70], 'MarkerSize', 7, 'LineWidth', 1.3);
            h_base = plot(ax_d, d_values_mm(d_base), d_delta(d_base), ...
                'd', 'Color', [0.1 0.1 0.1], 'MarkerFaceColor', [0.1 0.1 0.1], ...
                'MarkerSize', 8, 'LineWidth', 1.2);
            set(ax_d, 'FontSize', 10, 'LineWidth', 0.8, 'XTick', d_values_mm);
            xlabel(ax_d, 'Layer thickness d (mm)'); ylabel(ax_d, '\Delta_p');
            title(ax_d, 'Thickness');
            legend(ax_d, [h_sweep h_base], {'Sweep value', 'Baseline'}, ...
                'Location', 'northeast');

            ax_er = subplot(1, 3, 2);
            hold(ax_er, 'on'); grid(ax_er, 'on'); box(ax_er, 'on');
            er_base = find(abs(er_values - P0.epsr_d) < 1e-12, 1);
            er_other = setdiff(1:numel(er_values), er_base);
            plot(ax_er, er_values(er_other), er_delta(er_other), 'o', ...
                'Color', [0.12 0.43 0.70], 'MarkerSize', 7, 'LineWidth', 1.3);
            plot(ax_er, er_values(er_base), er_delta(er_base), 'd', ...
                'Color', [0.1 0.1 0.1], 'MarkerFaceColor', [0.1 0.1 0.1], ...
                'MarkerSize', 8, 'LineWidth', 1.2);
            set(ax_er, 'FontSize', 10, 'LineWidth', 0.8, 'XTick', er_values);
            xlabel(ax_er, 'Layer relative permittivity \epsilon_{r,d}');
            ylabel(ax_er, '\Delta_p'); title(ax_er, 'Relative permittivity');

            ax_sd = subplot(1, 3, 3);
            hold(ax_sd, 'on'); grid(ax_sd, 'on'); box(ax_sd, 'on');
            sd_base = find(abs(sd_values - P0.sigma_d) < 1e-15, 1);
            sd_other = setdiff(1:numel(sd_values), sd_base);
            sd_x = 1:numel(sd_values);
            plot(ax_sd, sd_x(sd_other), sd_delta(sd_other), 'o', ...
                'Color', [0.12 0.43 0.70], 'MarkerSize', 7, 'LineWidth', 1.3);
            plot(ax_sd, sd_x(sd_base), sd_delta(sd_base), 'd', ...
                'Color', [0.1 0.1 0.1], 'MarkerFaceColor', [0.1 0.1 0.1], ...
                'MarkerSize', 8, 'LineWidth', 1.2);
            sd_labels = cell(size(sd_values));
            for j = 1:numel(sd_values)
                sd_labels{j} = sprintf('%.0e', sd_values(j));
            end
            set(ax_sd, 'FontSize', 10, 'LineWidth', 0.8, ...
                'XTick', sd_x, 'XTickLabel', sd_labels);
            xlabel(ax_sd, 'Layer conductivity \sigma_d (S/m)');
            ylabel(ax_sd, '\Delta_p'); title(ax_sd, 'Conductivity');
            print('-dpng', sprintf('-r%d', P0.plot_export_dpi), ...
                fullfile(plot_dir, 'fig4b_layer.png'));
        else
            warning('plot_results: A2 layer sweep fields are missing; skipping fig4b');
        end
    else
        warning('plot_results: A2 baseline differs from cceit_params; skipping fig4b');
    end
else
    warning('plot_results: sweepA2_results.mat not found; skipping fig4b');
end

%% Model A tissue sensitivity; panels separate frequency and compare thickness
sweep_path = 'sweepA3_results.mat';
if exist(sweep_path, 'file')
    L = load(sweep_path);
    if ~isfield(L, 'P0') || abs(L.P0.sigma - P0.sigma) >= 1e-12 || ...
            abs(L.P0.epsr - P0.epsr) >= 1e-12 || ...
            abs(L.P0.epsr_d - P0.epsr_d) >= 1e-12 || ...
            abs(L.P0.sigma_d - P0.sigma_d) >= 1e-15 || ...
            abs(L.P0.h_int - P0.h_int) >= 1e-12 || ...
            abs(L.P0.R - P0.R) >= 1e-12 || ...
            abs(L.P0.w_el - P0.w_el) >= 1e-12
        warning('plot_results: sweepA3 baseline differs from cceit_params; skipping fig4c');
        L = struct();
    end
end
if exist(sweep_path, 'file') && isfield(L, 'R')
    d_list = unique([L.R.d]);
    freq_list = unique([L.R.f]);
    line_colors = lines(numel(d_list));
    fig4c = figure('Name', 'Model A tissue sensitivity', ...
        'Position', [50 40 1450 1050], 'Color', 'w');
    ax_sp_legend = [];
    h_d_lines = cell(1, numel(d_list));
    legend_text = cell(1, numel(d_list));
    for fi = 1:numel(freq_list)
        ax_sp = subplot(numel(freq_list), 2, 2*fi-1);
        if fi == 1
            ax_sp_legend = ax_sp;
        end
        hold(ax_sp, 'on'); grid(ax_sp, 'on'); box(ax_sp, 'on');
        ax_shape = subplot(numel(freq_list), 2, 2*fi);
        hold(ax_shape, 'on'); grid(ax_shape, 'on'); box(ax_shape, 'on');
        for di = 1:numel(d_list)
            scenario = find([L.R.d] == d_list(di) & [L.R.f] == freq_list(fi), 1);
            if isempty(scenario)
                continue;
            end
            h_line = loglog(ax_sp, L.R(scenario).sig, ...
                max(L.R(scenario).Sp_sig, realmin), 'o-', ...
                'Color', line_colors(di,:), 'LineWidth', 1.4, 'MarkerSize', 5);
            loglog(ax_shape, L.R(scenario).sig, ...
                max(L.R(scenario).Ssh_sig, realmin), 'o-', ...
                'Color', line_colors(di,:), 'LineWidth', 1.4, 'MarkerSize', 5);
            legend_text{di} = sprintf('d = %.1f mm', d_list(di)*1e3);
            if fi == 1
                h_d_lines{di} = h_line;
            end
        end
        set(ax_sp, 'FontSize', 10, 'LineWidth', 0.8);
        set(ax_shape, 'FontSize', 10, 'LineWidth', 0.8);
        xlabel(ax_sp, 'Tissue conductivity \sigma (S/m)');
        ylabel(ax_sp, '\Delta_p');
        title(ax_sp, sprintf('\Delta_p, f = %.0f kHz', freq_list(fi)/1e3));
        xlabel(ax_shape, 'Tissue conductivity \sigma (S/m)');
        ylabel(ax_shape, '\Delta_{shape}');
        title(ax_shape, sprintf('\Delta_{shape}, f = %.0f kHz', freq_list(fi)/1e3));
    end
    has_line = ~cellfun(@isempty, h_d_lines);
    legend(ax_sp_legend, [h_d_lines{has_line}], legend_text(has_line), ...
        'Location', 'northoutside', ...
        'Orientation', 'horizontal');
    print('-dpng', sprintf('-r%d', P0.plot_export_dpi), ...
        fullfile(plot_dir, 'fig4c_tissue.png'));
elseif ~exist(sweep_path, 'file')
    warning('plot_results: sweepA3_results.mat not found; skipping tissue sensitivity figure');
end

%% Model B mesh convergence and A/B response by electrode separation
b4_path = 'tes_B4_results.mat';
if exist(b4_path, 'file')
    B4 = load(b4_path);
    required_b4 = isfield(B4, 'R') && isfield(B4.R, 'tank') && ...
        isfield(B4, 'hrs') && isfield(B4, 'yA') && isfield(B4, 'P0') && ...
        isfield(B4.R.tank, 'ok') && isfield(B4.R.tank, 'yB');
    baseline_match = required_b4 && ...
        abs(B4.P0.sigma-P0.sigma) < 1e-12 && ...
        abs(B4.P0.epsr-P0.epsr) < 1e-12 && ...
        abs(B4.P0.d-P0.d) < 1e-12 && ...
        abs(B4.P0.epsr_d-P0.epsr_d) < 1e-12 && ...
        abs(B4.P0.sigma_d-P0.sigma_d) < 1e-15 && ...
        abs(B4.P0.f-P0.f) < 1e-6 && ...
        abs(B4.P0.h_int-P0.h_int) < 1e-12 && ...
        abs(B4.P0.R-P0.R) < 1e-12 && ...
        abs(B4.P0.w_el-P0.w_el) < 1e-12 && ...
        abs(B4.P0.depth-P0.depth) < 1e-12 && ...
        abs(B4.P0.z_el-P0.z_el) < 1e-12 && ...
        abs(B4.P0.Vtx-P0.Vtx) < 1e-12;
    if baseline_match
        valid_b4 = find(B4.R.tank.ok(:).');
        if ~isempty(valid_b4)
            h_mm = B4.hrs(valid_b4) * 1e3;
            delta_layer_B = zeros(size(valid_b4));
            for j = 1:numel(valid_b4)
                yB_now = B4.R.tank.yB{valid_b4(j)};
                delta_layer_B(j) = norm(B4.yA-yB_now) / norm(yB_now);
            end
            ref_idx = valid_b4(end);
            yB_ref = B4.R.tank.yB{ref_idx};
            delta_mesh_B = zeros(size(valid_b4));
            for j = 1:numel(valid_b4)
                yB_now = B4.R.tank.yB{valid_b4(j)};
                delta_mesh_B(j) = norm(yB_now-yB_ref) / norm(yB_ref);
            end

            fig4d = figure('Name', 'Model B mesh convergence', ...
                'Position', [100 100 1100 760], 'Color', 'w');
            ax_layer = subplot(2, 1, 1);
            plot(ax_layer, h_mm, delta_layer_B, 'o-', 'LineWidth', 1.8, ...
                'MarkerSize', 7, 'Color', [0.12 0.43 0.70]);
            grid(ax_layer, 'on'); box(ax_layer, 'on');
            set(ax_layer, 'FontSize', 11, 'LineWidth', 0.8, ...
                'XTick', h_mm, 'XDir', 'reverse');
            ylabel(ax_layer, '\Delta_{layer}');
            title(ax_layer, 'Model A vs explicit Model B');
            text(ax_layer, 0.02, 0.90, 'smaller h_{ring} = finer mesh', ...
                'Units', 'normalized', 'FontSize', 9);

            ax_mesh = subplot(2, 1, 2);
            plot(ax_mesh, h_mm, delta_mesh_B, 's-', 'LineWidth', 1.8, ...
                'MarkerSize', 7, 'Color', [0.82 0.30 0.12]);
            grid(ax_mesh, 'on'); box(ax_mesh, 'on');
            set(ax_mesh, 'FontSize', 11, 'LineWidth', 0.8, ...
                'XTick', h_mm, 'XDir', 'reverse');
            xlabel(ax_mesh, 'Ring element target h_{ring} (mm)');
            ylabel(ax_mesh, '\Delta_{mesh,B}');
            title(ax_mesh, sprintf('Model B change relative to %.2f mm reference', ...
                B4.hrs(ref_idx)*1e3));
            print('-dpng', sprintf('-r%d', P0.plot_export_dpi), ...
                fullfile(plot_dir, 'fig4d_layer_mesh.png'));

            target_k = find(abs(B4.hrs-P0.h_ring_B) == ...
                min(abs(B4.hrs-P0.h_ring_B)), 1);
            if B4.R.tank.ok(target_k) && ...
                    abs(B4.hrs(target_k)-P0.h_ring_B) <= max(1e-12, 0.01*P0.h_ring_B)
                n = P0.nElec;
                pair_list = zeros(n*(n-1)/2, 2);
                q = 0;
                for tx_pair = 1:n-1
                    for rx_pair = tx_pair+1:n
                        q = q + 1;
                        pair_list(q,:) = [tx_pair rx_pair];
                    end
                end
                pair_sep = min(pair_list(:,2)-pair_list(:,1), ...
                    n-(pair_list(:,2)-pair_list(:,1)));
                yA_B4 = B4.yA(:);
                yB_B4 = B4.R.tank.yB{target_k}(:);
                sep_values = unique(pair_sep).';
                medA = zeros(size(sep_values));
                medB = zeros(size(sep_values));
                medRatio = zeros(size(sep_values));
                for j = 1:numel(sep_values)
                    use = pair_sep == sep_values(j);
                    medA(j) = median(abs(yA_B4(use)));
                    medB(j) = median(abs(yB_B4(use)));
                    medRatio(j) = median(abs(yA_B4(use))./abs(yB_B4(use)));
                end
                fig4e = figure('Name', 'Model A/B response by separation', ...
                    'Position', [100 100 1200 540], 'Color', 'w');
                subplot(1, 2, 1);
                plot(sep_values, medA*1e4, 'o-', 'LineWidth', 1.7, ...
                    'MarkerSize', 6, 'Color', [0.12 0.43 0.70]); hold on;
                plot(sep_values, medB*1e4, 's-', 'LineWidth', 1.7, ...
                    'MarkerSize', 6, 'Color', [0.82 0.30 0.12]);
                grid on; box on;
                set(gca, 'FontSize', 10, 'LineWidth', 0.8, 'XTick', sep_values);
                xlabel('Electrode separation'); ylabel('Median |Y_{tr}| (10^{-4} per m depth)');
                title(sprintf('Pair response, Model B h_{ring}=%.2f mm', ...
                    B4.hrs(target_k)*1e3));
                legend({'Model A', 'Model B'}, 'Location', 'northeast');
                subplot(1, 2, 2);
                plot(sep_values, medRatio, 'd-', 'LineWidth', 1.7, ...
                    'MarkerSize', 6, 'Color', [0.32 0.52 0.26]); hold on;
                plot([min(sep_values) max(sep_values)], [1 1], 'k--', 'LineWidth', 1);
                grid on; box on;
                set(gca, 'FontSize', 10, 'LineWidth', 0.8, 'XTick', sep_values);
                xlabel('Electrode separation'); ylabel('Median |Y_A| / |Y_B|');
                title('Magnitude ratio');
                print('-dpng', sprintf('-r%d', P0.plot_export_dpi), ...
                    fullfile(plot_dir, 'fig4e_AB_by_separation.png'));
            else
                warning('plot_results: no successful B4 result at h_ring_B; skipping fig4e');
            end
        else
            warning('plot_results: no valid tank mesh sweep in tes_B4_results.mat');
        end
    else
        warning('plot_results: B4 sweep baseline does not match current parameters; skipping fig4d/e');
    end
else
    warning('plot_results: tes_B4_results.mat not found; skipping fig4d/e');
end

meta.version = version;
meta.date = datestr(now);
save(fullfile(plot_dir, 'plot_data.mat'), 'P0', 'iA', 'Ymap', 'separation', 'y_pair', ...
    'separation_values', 'mag_median', 'phase_median', 'freqs', 'Yf', 'meta');
fprintf('Selesai. Gambar PNG (%d dpi) dan plot_data.mat tersimpan di %s\n', ...
    P0.plot_export_dpi, plot_dir);
