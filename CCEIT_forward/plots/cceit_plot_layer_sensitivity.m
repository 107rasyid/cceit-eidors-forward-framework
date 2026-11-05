function output_path = cceit_plot_layer_sensitivity(P0, res, outdir, dpi)
% CCEIT_PLOT_LAYER_SENSITIVITY Plot Delta_p against each layer parameter.
% Purpose: compare layer sweeps while marking the configured baseline.
% Inputs: P0 baseline parameters, res A2 sweep struct, output folder, PNG dpi.
% Outputs: path to the three-panel layer-sensitivity PNG.
% Manuscript ref: Section IV.D, Model A layer-parameter sensitivity.

idx_d = find(strcmp({res.name}, 'd'), 1);
idx_epsd = find(strcmp({res.name}, 'epsr_d'), 1);
idx_sigd = find(strcmp({res.name}, 'sigma_d'), 1);
if isempty(idx_d) || isempty(idx_epsd) || isempty(idx_sigd)
    error('cceit_plot_layer_sensitivity: required layer sweeps are missing');
end

d_values = res(idx_d).vals(:)*1e3;
d_delta = res(idx_d).delta(:);
epsd_values = res(idx_epsd).vals(:);
epsd_delta = res(idx_epsd).delta(:);
sigma_d_values = res(idx_sigd).vals(:);
sigma_d_delta = res(idx_sigd).delta(:);
sigma_labels = cell(size(sigma_d_values));
for k = 1:numel(sigma_d_values)
    if sigma_d_values(k) == 0
        sigma_labels{k} = '0';
    else
        sigma_labels{k} = sprintf('%.0e', sigma_d_values(k));
    end
end

fig = figure('Name', 'Model A layer sensitivity', ...
    'Units', 'pixels', 'Position', [80 80 1550 700], ...
    'Color', 'w', 'PaperPositionMode', 'auto');
base_color = [0.12 0.12 0.12];
sweep_color = [0.12 0.43 0.70];

ax_d = subplot(1, 3, 1);
semilogx(ax_d, d_values, d_delta, '-o', 'Color', sweep_color, ...
    'MarkerFaceColor', 'w', 'MarkerSize', 7, 'LineWidth', 1.6);
hold(ax_d, 'on'); grid(ax_d, 'on'); box(ax_d, 'on');
base_idx = find(abs(d_values-P0.d*1e3) < 1e-9, 1);
if ~isempty(base_idx)
    plot(ax_d, d_values(base_idx), d_delta(base_idx), 'd', ...
        'Color', base_color, 'MarkerFaceColor', base_color, 'MarkerSize', 8);
end
xlabel(ax_d, 'Layer thickness d (mm)'); ylabel(ax_d, 'Delta_p');
title(ax_d, sprintf('Thickness (baseline %.1f mm)', P0.d*1e3));
set(ax_d, 'XTick', d_values, 'FontSize', 10, 'LineWidth', 0.9);

ax_epsd = subplot(1, 3, 2);
semilogx(ax_epsd, epsd_values, epsd_delta, '-o', 'Color', sweep_color, ...
    'MarkerFaceColor', 'w', 'MarkerSize', 7, 'LineWidth', 1.6);
hold(ax_epsd, 'on'); grid(ax_epsd, 'on'); box(ax_epsd, 'on');
base_idx = find(abs(epsd_values-P0.epsr_d) < 1e-12, 1);
if ~isempty(base_idx)
    plot(ax_epsd, epsd_values(base_idx), epsd_delta(base_idx), 'd', ...
        'Color', base_color, 'MarkerFaceColor', base_color, 'MarkerSize', 8);
end
xlabel(ax_epsd, 'Layer relative permittivity epsr_d');
ylabel(ax_epsd, 'Delta_p');
title(ax_epsd, sprintf('Permittivity (baseline %g)', P0.epsr_d));
set(ax_epsd, 'XTick', epsd_values, 'FontSize', 10, 'LineWidth', 0.9);

ax_sigma = subplot(1, 3, 3);
x_sigma = 1:numel(sigma_d_values);
plot(ax_sigma, x_sigma, sigma_d_delta, '-o', 'Color', sweep_color, ...
    'MarkerFaceColor', 'w', 'MarkerSize', 7, 'LineWidth', 1.6);
hold(ax_sigma, 'on'); grid(ax_sigma, 'on'); box(ax_sigma, 'on');
base_idx = find(abs(sigma_d_values-P0.sigma_d) < 1e-15, 1);
if ~isempty(base_idx)
    plot(ax_sigma, x_sigma(base_idx), sigma_d_delta(base_idx), 'd', ...
        'Color', base_color, 'MarkerFaceColor', base_color, 'MarkerSize', 8);
end
set(ax_sigma, 'XTick', x_sigma, 'XTickLabel', sigma_labels, ...
    'FontSize', 9, 'LineWidth', 0.9);
xlabel(ax_sigma, 'Layer conductivity sigma_d (S/m; test levels)');
ylabel(ax_sigma, 'Delta_p');
title(ax_sigma, 'Conductivity (zero is baseline)');

set([ax_d ax_epsd ax_sigma], 'YLim', [0 max([d_delta; epsd_delta; sigma_d_delta])*1.08]);
output_path = fullfile(outdir, 'fig4b_layer.png');
print(fig, '-dpng', sprintf('-r%d', dpi), output_path);
close(fig);
fprintf('Saved: %s\n', output_path);
end
