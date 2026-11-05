% RUN_AB_A3_B6_COARSE Compare refined Model A3 with refined Model B6.
% Implements: Section IV.B, refined A/B physical comparison.
% Run after setup_paths; does not modify or replace the existing A/B scripts.
clear; close all; clc;
P = cceit_params();
freq_Hz = P.f;
h_ring = P.h_ring_B6_coarse;
pairs = cceit_pair_list(P.nElec);
separation = min(pairs(:,2)-pairs(:,1), ...
    P.nElec-(pairs(:,2)-pairs(:,1)));
order = (1:size(pairs,1)).';

fprintf('=== Refined A3/B6 comparison: f=%.0f kHz, h_ring=%.2f mm ===\n', ...
    freq_Hz/1e3, h_ring*1e3);
eidors_cache clear
timer_mesh_A = tic;
[fmdl_A, info_A] = cceit_mesh_A3(P);
time_mesh_A_s = toc(timer_mesh_A);
timer_scan_A = tic;
y_A = cceit_runA3_mesh(fmdl_A, P, freq_Hz);
time_scan_A_s = toc(timer_scan_A);
fprintf('Model A3: %d elements, h_medium=%.2f mm, max electrode-arc mismatch %.4g\n', ...
    info_A.nElems, info_A.h_medium*1e3, info_A.electrode_arc_max_rel_error);

eidors_cache clear
timer_mesh_B = tic;
[fmdl_B, ring_B, info_B] = cceit_mesh_B6(P, h_ring);
time_mesh_B_s = toc(timer_mesh_B);
omega = 2*pi*freq_Hz;
gamma = P.sigma + 1i*omega*P.eps0*P.epsr;
gamma_layer = P.sigma_d + 1i*omega*P.eps0*P.epsr_d;
gamma_elem_B = gamma*ones(info_B.nElems,1);
gamma_elem_B(ring_B) = gamma_layer;
timer_scan_B = tic;
out_B = cceit_pairscan(fmdl_B, gamma_elem_B, P);
time_scan_B_s = toc(timer_scan_B);
idx_B = sub2ind(size(out_B.Y), out_B.pairs(:,1), out_B.pairs(:,2));
y_B = out_B.Y(idx_B);
info_B.dcc = max(out_B.dcc);
info_B.dfloat = max(out_B.dfloat);
info_B.dU = max(out_B.dU);
delta_layer = norm(y_A-y_B)/norm(y_B);
median_ratio = median(abs(y_A)./abs(y_B));
fprintf(['Model B6: total=%d, medium=%d, ring=%d elements; ' ...
    'h_medium=%.2f mm, h_ring=%.2f mm\n'], info_B.nElems, ...
    info_B.nMedium, info_B.nRing, info_B.h_medium*1e3, h_ring*1e3);
fprintf('delta_layer=%.6g | median |yA|/|yB|=%.6g\n', ...
    delta_layer, median_ratio);
fprintf('B6 max dcc=%.3g | floating/It=%.3g | dev U=%.3g V\n', ...
    info_B.dcc, info_B.dfloat, info_B.dU);
fprintf(['Timing for 120 pairs: A3 mesh=%.2f s, A3 scan=%.2f s; ' ...
    'B6 mesh=%.2f s, B6 scan=%.2f s\n'], ...
    time_mesh_A_s, time_scan_A_s, time_mesh_B_s, time_scan_B_s);

fig = figure('visible','off','color','w','position',[100 100 1100 850]);
subplot(2,1,1);
plot(1:numel(order), abs(y_A(order)), 'b-', 'linewidth', 1.3); hold on;
plot(1:numel(order), abs(y_B(order)), 'r--', 'linewidth', 1.3);
grid on; ylabel('Pair admittance (per m depth)');
title(sprintf('A3/B6 magnitude, acquisition order; Delta_layer = %.4g', delta_layer));
subplot(2,1,2);
plot(1:numel(order), angle(y_A(order))*180/pi, 'b-', 'linewidth', 1.3); hold on;
plot(1:numel(order), angle(y_B(order))*180/pi, 'r--', 'linewidth', 1.3);
grid on; xlabel('Pair index (acquisition order)');
ylabel('Phase (degrees)');
legend('Model A3','Model B6','location','southoutside', ...
    'orientation','horizontal');
plot_path = fullfile(P.outdir, 'fig_AB_A3_B6_coarse.png');
print(fig, plot_path, '-dpng', '-r180');
close(fig);

meta = cceit_make_metadata(P);
result_path = fullfile(P.outdir, 'AB_A3_B6_coarse_results.mat');
save(result_path, 'P','freq_Hz','h_ring','pairs','separation','order', ...
    'y_A','y_B','delta_layer','median_ratio','info_A','info_B', ...
    'time_mesh_A_s','time_scan_A_s','time_mesh_B_s','time_scan_B_s','meta');
csv_path = fullfile(P.outdir, 'AB_A3_B6_coarse_pairs.csv');
fid = fopen(csv_path,'w');
if fid < 0, error('run_AB_A3_B6_coarse: cannot write pair CSV'); end
fprintf(fid,'pair_index,tx,rx,separation,abs_yA,phase_yA_deg,abs_yB,phase_yB_deg,relative_difference\n');
for k = 1:numel(order)
    j = order(k);
    fprintf(fid,'%d,%d,%d,%d,%.12g,%.9g,%.12g,%.9g,%.12g\n', ...
        j,pairs(j,1),pairs(j,2),separation(j),abs(y_A(j)), ...
        angle(y_A(j))*180/pi,abs(y_B(j)),angle(y_B(j))*180/pi, ...
        abs(y_A(j)-y_B(j))/max(abs(y_B(j)),realmin));
end
fclose(fid);
timing_csv_path = fullfile(P.outdir,'AB_A3_B6_timing.csv');
fid = fopen(timing_csv_path,'w');
if fid < 0, error('run_AB_A3_B6_coarse: cannot write timing CSV'); end
fprintf(fid,'model,elements,mesh_time_s,scan_120_pairs_time_s\n');
fprintf(fid,'A3,%d,%.9g,%.9g\n',info_A.nElems,time_mesh_A_s,time_scan_A_s);
fprintf(fid,'B6,%d,%.9g,%.9g\n',info_B.nElems,time_mesh_B_s,time_scan_B_s);
fclose(fid);
fprintf('Saved: %s\n%s\n%s\n%s\n', result_path, csv_path, timing_csv_path, plot_path);
