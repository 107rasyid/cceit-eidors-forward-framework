% PLOT_SWEEP_A2 Regenerate standalone layer-sensitivity figures from MAT data.
% Implements: Section IV.D, Model A layer-parameter sensitivity.
clear; close all; clc;

P = cceit_params();
result_path = fullfile(P.outdir, 'sweepA2_results.mat');
if exist(result_path, 'file') ~= 2
    error('plot_sweepA2: run run_sweepA2 first to generate results');
end
L = load(result_path);
if ~isfield(L, 'res') || ~isfield(L, 'P0') || ...
        abs(L.P0.sigma-P.sigma) >= 1e-12 || ...
        abs(L.P0.epsr-P.epsr) >= 1e-12 || ...
        abs(L.P0.d-P.d) >= 1e-12 || ...
        abs(L.P0.epsr_d-P.epsr_d) >= 1e-12 || ...
        abs(L.P0.sigma_d-P.sigma_d) >= 1e-15 || ...
        abs(L.P0.f-P.f) >= 1e-6
    error('plot_sweepA2: results are incomplete or baseline-mismatched');
end

output_path = cceit_plot_layer_sensitivity(P, L.res, P.outdir, P.plot_export_dpi);
fprintf('Saved: %s\n', output_path);
