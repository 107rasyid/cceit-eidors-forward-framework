% PLOT_SWEEP_A3_MEDIUM Regenerate the medium-sensitivity figure.
% Implements: Section IV.D, Model A medium-parameter sensitivity.
clear; close all; clc;

P = cceit_params();
result_path = fullfile(P.outdir, 'sweepA3_results.mat');
if exist(result_path, 'file') ~= 2
    error('plot_sweepA3_medium: run run_sweepA3 first to generate results');
end
L = load(result_path);
if ~isfield(L, 'R') || isempty(L.R) || ~isfield(L, 'P0') || ...
        abs(L.P0.sigma-P.sigma) >= 1e-12 || ...
        abs(L.P0.epsr-P.epsr) >= 1e-12 || ...
        abs(L.P0.epsr_d-P.epsr_d) >= 1e-12 || ...
        abs(L.P0.sigma_d-P.sigma_d) >= 1e-15
    error('plot_sweepA3_medium: results are incomplete or baseline-mismatched');
end

cceit_plot_medium_sensitivity(P, L.R, P.outdir, P.plot_export_dpi);
