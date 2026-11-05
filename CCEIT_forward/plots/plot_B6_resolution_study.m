% PLOT_B6_RESOLUTION_STUDY Plot saved B6 ring-convergence results only.
% Implements: Section IV.B, explicit-layer mesh-resolution comparison.
clear; close all; clc;

P = cceit_params();
result_path = fullfile(P.outdir, 'B6_resolution_study.mat');
if exist(result_path, 'file') ~= 2
    error('plot_B6_resolution_study: run the B6 resolution study first');
end
L = load(result_path);
if ~isfield(L, 'P') || ~cceit_same_baseline(L.P, P) || ...
        ~isfield(L, 'levels') || isempty(L.levels)
    error('plot_B6_resolution_study: saved results are incomplete or baseline-mismatched');
end

h_ring_mm = [L.levels.h_ring_m] * 1e3;
delta_layer_pct = [L.levels.delta_layer] * 100;
fig = figure('Name', 'B6 mesh resolution', 'Color', 'w', ...
    'Position', [100 100 950 650]);
plot(h_ring_mm, delta_layer_pct, 'o-', 'LineWidth', 1.8, ...
    'MarkerSize', 7, 'Color', [0.12 0.43 0.70]);
set(gca, 'XDir', 'reverse', 'XTick', h_ring_mm, ...
    'FontSize', 13, 'LineWidth', 1.0);
grid on; box on;
xlabel('B6 ring target size (mm)', 'FontSize', 14);
ylabel('Relative A3/B6 difference (%)', 'FontSize', 14);
title('A3/B6 response difference across B6 mesh resolutions', 'FontSize', 15);

png_path = fullfile(P.outdir, 'fig_B6_resolution_study.png');
print(fig, png_path, '-dpng', sprintf('-r%d', P.plot_export_dpi));
close(fig);
fprintf('Updated plot from saved MAT: %s\n', png_path);
