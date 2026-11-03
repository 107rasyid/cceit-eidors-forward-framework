% RUN_AB_A2_B5_COARSE Compare corrected Model A geometry with local-ring B5.
% Implements: Section IV.B, initial coarse A/B physical comparison.
% Run after setup_paths; does not modify or replace the existing A/B scripts.
clear; close all; clc;
P = cceit_params();
freq_Hz = P.f;
h_ring = P.h_ring_B_coarse;
pairs = cceit_pair_list(P.nElec);
separation = min(pairs(:,2)-pairs(:,1), ...
    P.nElec-(pairs(:,2)-pairs(:,1)));
order = (1:size(pairs,1)).';

fprintf('=== Coarse A2/B5 comparison: f=%.0f kHz, h_ring=%.2f mm ===\n', ...
    freq_Hz/1e3, h_ring*1e3);
eidors_cache clear
[fmdl_A, info_A] = cceit_mesh_A(P);
y_A = cceit_runA_mesh(fmdl_A, P, freq_Hz);
fprintf('Model A2: %d elements, max electrode-arc mismatch %.4g\n', ...
    info_A.nElems, info_A.electrode_arc_max_rel_error);

eidors_cache clear
[y_B, info_B] = cceit_runB5(P, freq_Hz, h_ring);
delta_layer = norm(y_A-y_B)/norm(y_B);
median_ratio = median(abs(y_A)./abs(y_B));
fprintf(['Model B5: total=%d, medium=%d, ring=%d elements; ' ...
    'h_medium=%.2f mm, h_ring=%.2f mm\n'], info_B.nElems, ...
    info_B.nMedium, info_B.nRing, info_B.h_medium*1e3, h_ring*1e3);
fprintf('delta_layer=%.6g | median |yA|/|yB|=%.6g\n', ...
    delta_layer, median_ratio);
fprintf('B5 max dcc=%.3g | floating/It=%.3g | dev U=%.3g V\n', ...
    info_B.dcc, info_B.dfloat, info_B.dU);

fig = figure('visible','off','color','w','position',[100 100 1100 760]);
subplot(2,1,1);
plot(1:numel(order), abs(y_A(order)), 'b-', 'linewidth', 1.3); hold on;
plot(1:numel(order), abs(y_B(order)), 'r--', 'linewidth', 1.3);
grid on; ylabel('Pair admittance (per m depth)');
title(sprintf('A2/B5 magnitude; acquisition order, delta_{layer}=%.4g', delta_layer));
legend('Model A2','Model B5','location','best');
subplot(2,1,2);
plot(1:numel(order), angle(y_A(order))*180/pi, 'b-', 'linewidth', 1.3); hold on;
plot(1:numel(order), angle(y_B(order))*180/pi, 'r--', 'linewidth', 1.3);
grid on; xlabel('Pair index (acquisition order)');
ylabel('Phase (degrees)'); legend('Model A2','Model B5','location','best');
plot_path = fullfile(P.outdir, 'fig_AB_A2_B5_coarse.png');
print(fig, plot_path, '-dpng', '-r180');
close(fig);

meta = cceit_make_metadata(P);
result_path = fullfile(P.outdir, 'AB_A2_B5_coarse_results.mat');
save(result_path, 'P','freq_Hz','h_ring','pairs','separation','order', ...
    'y_A','y_B','delta_layer','median_ratio','info_A','info_B','meta');
csv_path = fullfile(P.outdir, 'AB_A2_B5_coarse_pairs.csv');
fid = fopen(csv_path,'w');
if fid < 0, error('run_AB_A2_B5_coarse: cannot write pair CSV'); end
fprintf(fid,'pair_index,tx,rx,separation,abs_yA,phase_yA_deg,abs_yB,phase_yB_deg,relative_difference\n');
for k = 1:numel(order)
    j = order(k);
    fprintf(fid,'%d,%d,%d,%d,%.12g,%.9g,%.12g,%.9g,%.12g\n', ...
        j,pairs(j,1),pairs(j,2),separation(j),abs(y_A(j)), ...
        angle(y_A(j))*180/pi,abs(y_B(j)),angle(y_B(j))*180/pi, ...
        abs(y_A(j)-y_B(j))/max(abs(y_B(j)),realmin));
end
fclose(fid);
fprintf('Saved: %s\n%s\n%s\n', result_path, csv_path, plot_path);
