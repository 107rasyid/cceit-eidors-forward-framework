% PLOT_RESULTS Generate only the retained Goal 3 figures from saved sweeps.
% Implements: Section IV.D, frequency, layer, and medium sensitivity results.
clear; close all; clc;

P0 = cceit_params();
plot_dir = P0.outdir;

%% Frequency response (one axis, using the completed run_sweepA results)
freq_path = fullfile(plot_dir, 'sweepA_results.mat');
if exist(freq_path, 'file') ~= 2
    error('plot_results: sweepA_results.mat is missing; run run_sweepA first');
end
F = load(freq_path);
if ~isfield(F, 'freqs') || ~isfield(F, 'Yf') || ...
        ~isfield(F, 'P0') || abs(F.P0.sigma-P0.sigma) >= 1e-12 || ...
        abs(F.P0.epsr-P0.epsr) >= 1e-12 || abs(F.P0.f-P0.f) >= 1e-6
    error('plot_results: frequency sweep is incomplete or baseline-mismatched');
end
freq_Hz = F.freqs(:).';
median_abs_Y = median(abs(F.Yf), 1);
fig = figure('Name', 'Model A frequency response', ...
    'Units', 'pixels', 'Position', [100 100 1000 700], ...
    'Color', 'w', 'PaperPositionMode', 'auto');
loglog(freq_Hz, median_abs_Y, 'o-', 'LineWidth', 1.8, 'MarkerSize', 7, ...
    'MarkerFaceColor', [0.18 0.46 0.70]);
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 0.8);
xlim([min(freq_Hz)*0.8, max(freq_Hz)*1.2]);
xlabel('Frequency (Hz)');
ylabel('Median pair admittance (per m depth)');
title('Model A frequency response');
freq_png = fullfile(plot_dir, 'fig4a_freq.png');
print(fig, '-dpng', sprintf('-r%d', P0.plot_export_dpi), freq_png);
close(fig);

%% Layer sensitivity (three parameter panels, direct Delta_p scale)
layer_path = fullfile(plot_dir, 'sweepA2_results.mat');
if exist(layer_path, 'file') ~= 2
    error('plot_results: sweepA2_results.mat is missing; run run_sweepA2 first');
end
A2 = load(layer_path);
if ~isfield(A2, 'res') || ~isfield(A2, 'P0') || ...
        abs(A2.P0.sigma-P0.sigma) >= 1e-12 || ...
        abs(A2.P0.epsr-P0.epsr) >= 1e-12 || ...
        abs(A2.P0.d-P0.d) >= 1e-12 || ...
        abs(A2.P0.epsr_d-P0.epsr_d) >= 1e-12 || ...
        abs(A2.P0.sigma_d-P0.sigma_d) >= 1e-15 || ...
        abs(A2.P0.f-P0.f) >= 1e-6
    error('plot_results: layer sweep is incomplete or baseline-mismatched');
end
layer_png = cceit_plot_layer_sensitivity(P0, A2.res, plot_dir, P0.plot_export_dpi);

%% Medium sensitivity (one spacious 4-by-2 figure)
medium_path = fullfile(plot_dir, 'sweepA3_results.mat');
if exist(medium_path, 'file') ~= 2
    error('plot_results: sweepA3_results.mat is missing; run run_sweepA3 first');
end
A3 = load(medium_path);
if ~isfield(A3, 'R') || ~isfield(A3, 'P0') || ...
        abs(A3.P0.sigma-P0.sigma) >= 1e-12 || ...
        abs(A3.P0.epsr-P0.epsr) >= 1e-12 || ...
        abs(A3.P0.epsr_d-P0.epsr_d) >= 1e-12 || ...
        abs(A3.P0.sigma_d-P0.sigma_d) >= 1e-15
    error('plot_results: medium sweep is incomplete or baseline-mismatched');
end
medium_pngs = cceit_plot_medium_sensitivity(P0, A3.R, plot_dir, P0.plot_export_dpi);

fprintf('Goal 3 plots saved:\n  %s\n', freq_png);
fprintf('  %s\n', layer_png);
for k = 1:numel(medium_pngs)
    fprintf('  %s\n', medium_pngs{k});
end
