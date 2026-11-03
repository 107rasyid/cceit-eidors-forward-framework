% RUN_A_ELECTRODE_RESOLUTION_STUDY Inspect electrode nodes and sweep h_el.
% Implements: Section IV.B, Model A geometry sensitivity and A/B comparison.
% Uses h_int=2.5 mm and h_el=[1.0 0.6 0.4] mm; catches each level separately.
clear; close all; clc;

setup_paths();
P = cceit_params();
P.h_int = 2.5e-3;
h_el_values = [1.0 0.6 0.4]*1e-3;
freq_Hz = P.f;
n = P.nElec;
pairs = cceit_pair_list(n);
pair_sep = min(pairs(:,2)-pairs(:,1), n-(pairs(:,2)-pairs(:,1)));

%% Load current-baseline explicit-layer reference at h_ring=0.5 mm.
ab_path = fullfile(P.outdir, 'cceit_AB_final_results.mat');
if exist(ab_path, 'file') ~= 2
    error('run_A_electrode_resolution_study: missing %s; run run_AB_final first', ab_path);
end
AB = load(ab_path);
if ~isfield(AB, 'P') || ~cceit_same_baseline(AB.P, P) || ...
        ~isfield(AB, 'results') || ~isfield(AB.results, 'h_ring') || ...
        ~isfield(AB.results, 'y_B') || abs(AB.freq_Hz-freq_Hz) > 1e-6
    error('run_A_electrode_resolution_study: saved A/B reference does not match current baseline');
end
idx_B = find(abs(AB.results.h_ring(:)-0.5e-3) < 1e-12, 1);
if isempty(idx_B) || numel(AB.results.y_B) < idx_B || ...
        numel(AB.results.y_B{idx_B}) ~= size(pairs,1)
    error('run_A_electrode_resolution_study: missing current-baseline B reference at h_ring=0.5 mm');
end
y_B = AB.results.y_B{idx_B}(:);

levels = repmat(struct('h_el_m', NaN, 'nElems', NaN, 'delta_layer', NaN, ...
    'cv_by_separation', NaN(1,7), 'status', 'pending', 'error', ''), ...
    numel(h_el_values), 1);
electrode_geometry = [];
mean_absY_by_electrode = [];
rho_node_count_mean_absY = NaN;
rho_arc_width_mean_absY = NaN;
rho_boundary_arc_mean_absY = NaN;

for level_idx = 1:numel(h_el_values)
    h_el_m = h_el_values(level_idx);
    levels(level_idx).h_el_m = h_el_m;
    fprintf('\n=== Model A: h_int=%.2f mm, h_el=%.2f mm ===\n', ...
        P.h_int*1e3, h_el_m*1e3);
    try
        P_level = P;
        P_level.h_el = h_el_m;
        eidors_cache clear
        [fmdl, mesh_info] = cceit_mesh_A(P_level);
        y_A = cceit_runA_mesh(fmdl, P_level, freq_Hz);
        levels(level_idx).nElems = mesh_info.nElems;
        levels(level_idx).delta_layer = norm(y_A(:)-y_B)/norm(y_B);
        fprintf('Max electrode arc mismatch vs target=%.4g\n', ...
            mesh_info.electrode_arc_max_rel_error);

        for sep = 2:8
            vals = abs(y_A(pair_sep == sep));
            if ~isempty(vals)
                levels(level_idx).cv_by_separation(sep-1) = std(vals)/mean(vals);
            end
        end
        levels(level_idx).status = 'completed';
        fprintf('Elements=%d | delta_layer vs B(0.50 mm)=%.6g\n', ...
            mesh_info.nElems, levels(level_idx).delta_layer);
        for sep = 2:8
            fprintf('  separation %d: std(|Y|)/mean(|Y|)=%.6g\n', ...
                sep, levels(level_idx).cv_by_separation(sep-1));
        end

        if level_idx == 1
            electrode_geometry = repmat(struct('electrode', 0, ...
                'node_count', 0, 'angle_span_deg', NaN, ...
                'node_span_width_mm', NaN, 'boundary_arc_length_mm', NaN, ...
                'mean_absY', NaN, ...
                'mean_abs_terminal_current_A', NaN), n, 1);
            Ymap = zeros(n);
            for pair_idx = 1:size(pairs,1)
                tx = pairs(pair_idx,1);
                rx = pairs(pair_idx,2);
                Ymap(tx,rx) = y_A(pair_idx);
                Ymap(rx,tx) = y_A(pair_idx);
            end
            boundary_arc = cceit_electrode_boundary_lengths(fmdl);
            mean_absY_by_electrode = zeros(n,1);
            for e = 1:n
                node_ids = unique(fmdl.electrode(e).nodes(:));
                xy = fmdl.nodes(node_ids,1:2);
                theta = atan2(xy(:,2), xy(:,1));
                center_theta = angle(mean(exp(1i*theta)));
                theta_local = angle(exp(1i*(theta-center_theta)));
                angle_span = max(theta_local)-min(theta_local);
                mean_absY_by_electrode(e) = mean(abs(Ymap(e,[1:e-1 e+1:n])));
                electrode_geometry(e).electrode = e;
                electrode_geometry(e).node_count = numel(node_ids);
                electrode_geometry(e).angle_span_deg = angle_span*180/pi;
                electrode_geometry(e).node_span_width_mm = angle_span*P.R*1e3;
                electrode_geometry(e).boundary_arc_length_mm = boundary_arc(e)*1e3;
                electrode_geometry(e).mean_absY = mean_absY_by_electrode(e);
                electrode_geometry(e).mean_abs_terminal_current_A = ...
                    mean_absY_by_electrode(e)*abs(P.Vtx);
            end
            Cn = corrcoef([electrode_geometry.node_count].', mean_absY_by_electrode);
            Ca = corrcoef([electrode_geometry.node_span_width_mm].', mean_absY_by_electrode);
            Ce = corrcoef([electrode_geometry.boundary_arc_length_mm].', mean_absY_by_electrode);
            rho_node_count_mean_absY = Cn(1,2);
            rho_arc_width_mean_absY = Ca(1,2);
            rho_boundary_arc_mean_absY = Ce(1,2);
            fprintf('\nBaseline electrode geometry and response:\n');
            fprintf(['elec,node_count,angle_span_deg,node_span_width_mm,' ...
                'boundary_arc_length_mm,mean_absY,mean_abs_It_A\n']);
            for e = 1:n
                g = electrode_geometry(e);
                fprintf('%d,%d,%.8g,%.8g,%.8g,%.12g,%.12g\n', ...
                    g.electrode, g.node_count, g.angle_span_deg, ...
                    g.node_span_width_mm, g.boundary_arc_length_mm, ...
                    g.mean_absY, g.mean_abs_terminal_current_A);
            end
            fprintf('Pearson r(node count, mean |Y|)=%.8g\n', rho_node_count_mean_absY);
            fprintf('Pearson r(node-span width, mean |Y|)=%.8g\n', rho_arc_width_mean_absY);
            fprintf('Pearson r(boundary arc length, mean |Y|)=%.8g\n', ...
                rho_boundary_arc_mean_absY);
        end
    catch level_error
        levels(level_idx).status = 'failed';
        levels(level_idx).error = level_error.message;
        fprintf(2, 'LEVEL FAILED h_el=%.2f mm | %s: %s\n', ...
            h_el_m*1e3, level_error.identifier, level_error.message);
    end
end

meta = cceit_make_metadata(P);
result_path = fullfile(P.outdir, 'A_electrode_resolution_study.mat');
save(result_path, 'P', 'freq_Hz', 'h_el_values', 'levels', ...
    'electrode_geometry', 'rho_node_count_mean_absY', ...
    'rho_arc_width_mean_absY', 'rho_boundary_arc_mean_absY', 'y_B', 'meta');

electrode_csv = fullfile(P.outdir, 'A_baseline_electrode_geometry.csv');
fid = fopen(electrode_csv, 'w');
if fid < 0, error('run_A_electrode_resolution_study: cannot write %s', electrode_csv); end
fprintf(fid, ['electrode,node_count,angle_span_deg,node_span_width_mm,' ...
    'boundary_arc_length_mm,mean_absY,mean_abs_terminal_current_A\n']);
for e = 1:numel(electrode_geometry)
    g = electrode_geometry(e);
    fprintf(fid, '%d,%d,%.12g,%.12g,%.12g,%.12g,%.12g\n', g.electrode, ...
        g.node_count, g.angle_span_deg, g.node_span_width_mm, ...
        g.boundary_arc_length_mm, g.mean_absY, ...
        g.mean_abs_terminal_current_A);
end
fclose(fid);

sweep_csv = fullfile(P.outdir, 'A_electrode_resolution_sweep.csv');
fid = fopen(sweep_csv, 'w');
if fid < 0, error('run_A_electrode_resolution_study: cannot write %s', sweep_csv); end
fprintf(fid, 'h_int_mm,h_el_mm,elements,status,delta_layer_vs_B_h0.5mm');
for sep = 2:8, fprintf(fid, ',cv_absY_sep%d', sep); end
fprintf(fid, ',error\n');
for level_idx = 1:numel(levels)
    row = levels(level_idx);
    fprintf(fid, '%.6g,%.6g,%.0f,%s,%.12g', P.h_int*1e3, ...
        row.h_el_m*1e3, row.nElems, row.status, row.delta_layer);
    for sep_idx = 1:7, fprintf(fid, ',%.12g', row.cv_by_separation(sep_idx)); end
    error_text = strrep(strrep(row.error, '"', '""'), ',', ';');
    fprintf(fid, ',"%s"\n', error_text);
end
fclose(fid);
fprintf('\nSaved MAT: %s\nElectrode CSV: %s\nSweep CSV: %s\n', ...
    result_path, electrode_csv, sweep_csv);
