% RUN_B5_RESOLUTION_STUDY Check ring convergence with the B5 coarse medium.
% Implements: Section IV.B, explicit-layer mesh sensitivity.
% Run after setup_paths. Reuses the completed 1.0 mm A2/B5 scan when valid.
clear; close all; clc;
P = cceit_params();
freq_Hz = P.f;
h_values = [1.0 0.7 0.5]*1e-3;
pairs = cceit_pair_list(P.nElec);

coarse_path = fullfile(P.outdir, 'AB_A2_B5_coarse_results.mat');
if exist(coarse_path,'file') ~= 2
    error('run_B5_resolution_study: run run_AB_A2_B5_coarse first to create the 1 mm reference');
end
C = load(coarse_path);
if ~isfield(C,'P') || ~cceit_same_baseline(C.P,P) || ...
        ~isfield(C,'freq_Hz') || C.freq_Hz ~= freq_Hz || ...
        ~isfield(C,'h_ring') || abs(C.h_ring-h_values(1)) > 1e-12 || ...
        ~isfield(C,'y_A') || ~isfield(C,'y_B')
    error('run_B5_resolution_study: saved 1 mm A2/B5 reference does not match current baseline');
end
y_A = C.y_A(:);
nLevels = numel(h_values);
levels = repmat(struct('h_ring_m',NaN,'nElems',NaN,'nMedium',NaN, ...
    'nRing',NaN,'delta_layer',NaN,'median_ratio_A_B',NaN, ...
    'max_dcc',NaN,'max_dfloat',NaN,'max_dU',NaN,'time_scan_s',NaN, ...
    'y_B',[]), ...
    nLevels,1);

for k = 1:nLevels
    h_ring = h_values(k);
    levels(k).h_ring_m = h_ring;
    if k == 1
        y_B = C.y_B(:);
        info = C.info_B;
        time_scan_s = NaN; % reused result; original duration was not saved
        fprintf('Reuse B5 h_ring=%.2f mm from %s\n',h_ring*1e3,coarse_path);
    else
        fprintf('\n=== B5 resolution: h_ring=%.2f mm; medium h=%.2f mm ===\n', ...
            h_ring*1e3,P.h_int*1e3);
        eidors_cache clear
        timer_scan = tic;
        [y_B,info] = cceit_runB5(P,freq_Hz,h_ring);
        time_scan_s = toc(timer_scan);
    end
    levels(k).nElems = info.nElems;
    levels(k).nMedium = info.nMedium;
    levels(k).nRing = info.nRing;
    levels(k).delta_layer = norm(y_A-y_B)/norm(y_B);
    levels(k).median_ratio_A_B = median(abs(y_A)./abs(y_B));
    levels(k).max_dcc = info.dcc;
    levels(k).max_dfloat = info.dfloat;
    levels(k).max_dU = info.dU;
    levels(k).time_scan_s = time_scan_s;
    levels(k).y_B = y_B;
    fprintf(['h_ring=%.2f mm | total=%d medium=%d ring=%d | delta_layer=%.6g | ' ...
        'median |yA|/|yB|=%.6g | time=%.1f s\n'],h_ring*1e3, ...
        info.nElems,info.nMedium,info.nRing,levels(k).delta_layer, ...
        levels(k).median_ratio_A_B,time_scan_s);
end

meta = cceit_make_metadata(P);
result_path = fullfile(P.outdir,'B5_resolution_study.mat');
save(result_path,'P','freq_Hz','h_values','pairs','y_A','levels','meta');
csv_path = fullfile(P.outdir,'B5_resolution_study.csv');
fid = fopen(csv_path,'w');
if fid < 0, error('run_B5_resolution_study: cannot write %s',csv_path); end
fprintf(fid,['h_ring_mm,h_medium_mm,total_elements,medium_elements,ring_elements,' ...
    'delta_layer,median_abs_yA_over_yB,max_dcc,max_dfloat,max_dU,time_scan_s\n']);
for k = 1:nLevels
    q = levels(k);
    fprintf(fid,'%.6g,%.6g,%d,%d,%d,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', ...
        q.h_ring_m*1e3,P.h_int*1e3,q.nElems,q.nMedium,q.nRing, ...
        q.delta_layer,q.median_ratio_A_B,q.max_dcc,q.max_dfloat,q.max_dU,q.time_scan_s);
end
fclose(fid);

fig = figure('visible','off','color','w','position',[100 100 850 560]);
plot([levels.h_ring_m]*1e3,[levels.delta_layer],'o-','linewidth',1.8);
set(gca,'xdir','reverse'); grid on;
xlabel('Ring mesh target h_{ring} (mm)'); ylabel('\delta_{layer}');
title('A2/B5 convergence with fixed coarse medium mesh');
plot_path = fullfile(P.outdir,'fig_B5_resolution_study.png');
print(fig,plot_path,'-dpng','-r180');
close(fig);
fprintf('\nSaved: %s\n%s\n%s\n',result_path,csv_path,plot_path);
