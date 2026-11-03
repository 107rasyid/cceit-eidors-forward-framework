% PLOT_PAIRS_AB  Plot the A/B pair response from run_AB_final output.
% Implements: Section IV.B, pairwise Model A/B admittance comparison.
clear; close all; clc;

P = cceit_params();
input_path = fullfile(P.outdir, 'cceit_AB_final_results.mat');
if exist(input_path, 'file') ~= 2
    error('plot_pairs_AB: missing %s; run run_AB_final.m first', input_path);
end
L = load(input_path);
if ~isfield(L, 'results') || ~isfield(L.results, 'h_ring') || ...
        ~isfield(L.results, 'y_A') || ~isfield(L.results, 'y_B')
    error('plot_pairs_AB: %s does not contain A/B pair vectors', input_path);
end
[mesh_error, mesh_idx] = min(abs(L.results.h_ring - P.h_ring_B));
if mesh_error > max(1e-12, 0.01*P.h_ring_B)
    error('plot_pairs_AB: no Model B result at h_ring_B = %.3g m', P.h_ring_B);
end

n = P.nElec;
pairs = cceit_pair_list(n);
separation = min(pairs(:,2)-pairs(:,1), n-(pairs(:,2)-pairs(:,1)));
y_A = L.results.y_A(:);
y_B = L.results.y_B{mesh_idx}(:);
if numel(y_A) ~= size(pairs,1) || numel(y_B) ~= size(pairs,1)
    error('plot_pairs_AB: expected %d pair admittances for both models', size(pairs,1));
end
pair_index = (1:numel(y_A)).';
relative_pair_difference = abs(y_A-y_B) ./ max(abs(y_B), realmin);
phase_A_deg = angle(y_A)*180/pi;
phase_B_deg = angle(y_B)*180/pi;

meta = cceit_make_metadata(P);
png_mag = fullfile(P.outdir, 'cceit_pairs_AB_magnitude.png');
fig_mag = figure('Name', 'A/B pair admittance magnitude', ...
    'Position', [80 80 1400 760], 'Color', 'w');
ax_mag = axes('Parent', fig_mag);
plot(ax_mag, pair_index, abs(y_A), '-', 'Color', [0.12 0.43 0.70], ...
    'LineWidth', 1.7);
hold(ax_mag, 'on');
plot(ax_mag, pair_index, abs(y_B), '--', 'Color', [0.82 0.30 0.12], ...
    'LineWidth', 1.7);
grid(ax_mag, 'on'); box(ax_mag, 'on');
set(ax_mag, 'FontSize', 13, 'LineWidth', 1.0);
xlim(ax_mag, [1 numel(pair_index)]);
xlabel(ax_mag, 'Pair index (acquisition order)');
ylabel(ax_mag, 'Pair admittance (per m depth)');
title(ax_mag, sprintf('Admittance magnitude: 120 pairs, B h_{ring}=%.2f mm', ...
    L.results.h_ring(mesh_idx)*1e3));
legend(ax_mag, {'Model A', 'Model B'}, 'Location', 'best');
print(fig_mag, '-dpng', sprintf('-r%d', P.plot_export_dpi), png_mag);

png_phase = fullfile(P.outdir, 'cceit_pairs_AB_phase.png');
fig_phase = figure('Name', 'A/B pair admittance phase', ...
    'Position', [100 100 1400 760], 'Color', 'w');
ax_phase = axes('Parent', fig_phase);
plot(ax_phase, pair_index, phase_A_deg, '-', 'Color', [0.12 0.43 0.70], ...
    'LineWidth', 1.7);
hold(ax_phase, 'on');
plot(ax_phase, pair_index, phase_B_deg, '--', 'Color', [0.82 0.30 0.12], ...
    'LineWidth', 1.7);
grid(ax_phase, 'on'); box(ax_phase, 'on');
set(ax_phase, 'FontSize', 13, 'LineWidth', 1.0);
xlim(ax_phase, [1 numel(pair_index)]);
xlabel(ax_phase, 'Pair index (acquisition order)');
ylabel(ax_phase, 'Pair admittance phase (degrees)');
title(ax_phase, sprintf('Admittance phase: 120 pairs, B h_{ring}=%.2f mm', ...
    L.results.h_ring(mesh_idx)*1e3));
legend(ax_phase, {'Model A', 'Model B'}, 'Location', 'best');
print(fig_phase, '-dpng', sprintf('-r%d', P.plot_export_dpi), png_phase);

png_diff = fullfile(P.outdir, 'cceit_pairs_AB_relative_difference.png');
fig_diff = figure('Name', 'A/B pair relative difference', ...
    'Position', [120 120 1400 760], 'Color', 'w');
ax_diff = axes('Parent', fig_diff);
plot(ax_diff, pair_index, relative_pair_difference, '-', ...
    'Color', [0.22 0.48 0.28], 'LineWidth', 1.5);
hold(ax_diff, 'on');
plot(ax_diff, pair_index, relative_pair_difference, 'o', ...
    'Color', [0.22 0.48 0.28], 'MarkerSize', 4);
grid(ax_diff, 'on'); box(ax_diff, 'on');
set(ax_diff, 'FontSize', 13, 'LineWidth', 1.0);
xlim(ax_diff, [1 numel(pair_index)]);
xlabel(ax_diff, 'Pair index (acquisition order)');
ylabel(ax_diff, '|y_A-y_B| / |y_B|');
title(ax_diff, 'Relative A/B difference for each pair');
print(fig_diff, '-dpng', sprintf('-r%d', P.plot_export_dpi), png_diff);

result_path = fullfile(P.outdir, 'cceit_pairs_AB.mat');
save(result_path, 'P', 'pairs', 'separation', 'pair_index', 'y_A', 'y_B', ...
    'relative_pair_difference', 'phase_A_deg', 'phase_B_deg', 'meta');
csv_path = fullfile(P.outdir, 'pair_admittance_AB.csv');
fid = fopen(csv_path, 'w');
if fid < 0
    error('plot_pairs_AB: cannot write %s', csv_path);
end
fprintf(fid, ['pair_index,tx,rx,separation,yA_real,yA_imag,yA_magnitude,' ...
    'yA_phase_deg,yB_real,yB_imag,yB_magnitude,yB_phase_deg,relative_difference\n']);
for k = 1:numel(pair_index)
    fprintf(fid, '%d,%d,%d,%d,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', ...
        pair_index(k), pairs(k,1), pairs(k,2), separation(k), ...
        real(y_A(k)), imag(y_A(k)), abs(y_A(k)), phase_A_deg(k), ...
        real(y_B(k)), imag(y_B(k)), abs(y_B(k)), phase_B_deg(k), ...
        relative_pair_difference(k));
end
fclose(fid);
fprintf('Pair plots:\n  %s\n  %s\n  %s\nData: %s\n', ...
    png_mag, png_phase, png_diff, result_path);
fprintf('Pair CSV: %s\n', csv_path);
