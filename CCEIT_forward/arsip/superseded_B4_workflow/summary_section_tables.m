% SUMMARY_SECTION_TABLES Export table-ready CSV data for Section IV.
% Implements: Section IV.A-IV.D, numerical verification and sensitivity tables.
clear; clc;

P = cceit_params();
files = {'cceit_verification_results.mat','sweepA_results.mat', ...
    'sweepA2_results.mat','sweepA3_results.mat','B_resolution_study.mat'};
L = cell(size(files));
for k = 1:numel(files)
    file_path = fullfile(P.outdir, files{k});
    if exist(file_path, 'file') ~= 2
        error('summary_section_tables: missing results/%s', files{k});
    end
    L{k} = load(file_path);
end
V = L{1}; A = L{2}; A2 = L{3}; A3 = L{4}; B = L{5};
if ~isfield(V, 'check_A') || ~isfield(V, 'check_B') || ...
        ~isfield(A, 'nel') || ~isfield(A, 'delta_mesh_A') || ...
        ~isfield(A, 'time_mesh_scan_s') || ~isfield(A2, 'res') || ...
        ~isfield(A3, 'R') || ~isfield(B, 'mesh_result')
    error('summary_section_tables: one or more MAT files lack table fields');
end

%% Verification table
verification.quantity = {'Elements'; 'max dcc'; ...
    'max floating current / drive current'; 'max terminal-voltage deviation'; ...
    'max reciprocity error'};
verification.model_A = [V.check_A.nElems; V.check_A.max_dcc; ...
    V.check_A.max_dfloat; V.check_A.max_dU; V.check_A.max_reciprocity_error];
verification.model_B = [V.check_B.nElems; V.check_B.max_dcc; ...
    V.check_B.max_dfloat; V.check_B.max_dU; V.check_B.max_reciprocity_error];
verification.n_pair_responses = P.nElec*(P.nElec-1)/2;
verification.n_reciprocity_pairs = size(V.reciprocity_pairs, 1);
verification_path = fullfile(P.outdir, 'table_verification.csv');
fid = fopen(verification_path, 'w');
if fid < 0, error('summary_section_tables: cannot write %s', verification_path); end
fprintf(fid, 'Quantity,Model A,Model B\n');
for k = 1:numel(verification.quantity)
    fprintf(fid, '"%s",%.12g,%.12g\n', verification.quantity{k}, ...
        verification.model_A(k), verification.model_B(k));
end
fclose(fid);
verification_details_path = fullfile(P.outdir, 'table_verification_details.csv');
fid = fopen(verification_details_path, 'w');
if fid < 0
    error('summary_section_tables: cannot write %s', verification_details_path);
end
fprintf(fid, 'Quantity,Value\n');
fprintf(fid, 'Pair responses,%d\n', verification.n_pair_responses);
fprintf(fid, 'Reciprocity pairs tested,%d\n', verification.n_reciprocity_pairs);
fclose(fid);

%% A and B mesh-convergence table
mesh_path = fullfile(P.outdir, 'table_mesh_convergence.csv');
fid = fopen(mesh_path, 'w');
if fid < 0, error('summary_section_tables: cannot write %s', mesh_path); end
fprintf(fid, 'Model,h_int_mm,h_el_mm,h_ring_mm,elements,across_d,delta_mesh,time_scan_s\n');
% Older sweep MAT files may have one extra status entry beyond the level
% matrix. Only iterate over rows present in every column used below.
n_A_levels = min([size(A.levels,1), numel(A.ok), numel(A.delta_mesh_A), ...
    numel(A.nel), numel(A.time_mesh_scan_s)]);
for k = 1:n_A_levels
    if A.ok(k)
        delta_text = sprintf('%.12g', A.delta_mesh_A(k));
        if A.delta_mesh_A(k) == 0, delta_text = 'ref'; end
        fprintf(fid, 'A,%.6g,%.6g,,%d,,%s,%.8g\n', ...
            A.levels(k,1), A.levels(k,2), A.nel(k), delta_text, ...
        A.time_mesh_scan_s(k));
    end
end
for k = 1:numel(B.mesh_result)
    row = B.mesh_result(k);
    delta_text = sprintf('%.12g', row.delta_mesh);
    if row.delta_mesh == 0, delta_text = 'ref'; end
    fprintf(fid, 'B,,,%.6g,%d,%.0f,%s,%.8g\n', ...
        row.h_ring_m*1e3, row.nElems_total, round(row.across_d), ...
        delta_text, row.time_scan_s);
end
fclose(fid);

%% Explicit-layer comparison table
layer_path = fullfile(P.outdir, 'table_layer_resolution.csv');
fid = fopen(layer_path, 'w');
if fid < 0, error('summary_section_tables: cannot write %s', layer_path); end
fprintf(fid, ['h_ring_mm,across_d,delta_layer,median_abs_yA_over_yB,' ...
    'nElems_total,nElems_ring,nElems_medium,time_scan_s\n']);
for k = 1:numel(B.mesh_result)
    row = B.mesh_result(k);
    fprintf(fid, '%.6g,%.0f,%.12g,%.12g,%d,%d,%d,%.8g\n', ...
        row.h_ring_m*1e3, round(row.across_d), row.delta_layer, ...
        row.median_ratio_A_B, row.nElems_total, row.nElems_ring, ...
        row.nElems_medium, row.time_scan_s);
end
fclose(fid);

%% Model A layer-parameter sweep
layer_sensitivity_path = fullfile(P.outdir, 'table_layer_sensitivity.csv');
fid = fopen(layer_sensitivity_path, 'w');
if fid < 0, error('summary_section_tables: cannot write %s', layer_sensitivity_path); end
fprintf(fid, 'parameter,value,unit,Delta_p\n');
for k = 1:numel(A2.res)
    for j = 1:numel(A2.res(k).vals)
        parameter = A2.res(k).name;
        value = A2.res(k).vals(j);
        unit = '1';
        if strcmp(parameter, 'd')
            value = value*1e3;
            unit = 'mm';
        elseif strcmp(parameter, 'sigma_d') || strcmp(parameter, 'sigma')
            unit = 'S/m';
        end
        fprintf(fid, '%s,%.12g,%s,%.12g\n', parameter, value, unit, ...
            A2.res(k).delta(j));
    end
end
fclose(fid);

%% Model A medium sweep, exporting the in-scope Delta_p metric only.
medium_path = fullfile(P.outdir, 'table_medium_sensitivity.csv');
fid = fopen(medium_path, 'w');
if fid < 0, error('summary_section_tables: cannot write %s', medium_path); end
fprintf(fid, 'd_mm,frequency_Hz,parameter,value,Delta_p\n');
for k = 1:numel(A3.R)
    row = A3.R(k);
    for j = 1:numel(row.sig)
        fprintf(fid, '%.6g,%.12g,sigma,%.12g,%.12g\n', ...
            row.d*1e3, row.f, row.sig(j), row.Sp_sig(j));
    end
    for j = 1:numel(row.eps)
        fprintf(fid, '%.6g,%.12g,epsr,%.12g,%.12g\n', ...
            row.d*1e3, row.f, row.eps(j), row.Sp_eps(j));
    end
end
fclose(fid);

%% Optional d=1,3,5 mm Model A/B points, saved individually by the study.
thickness_path = fullfile(P.outdir, 'table_thickness_study.csv');
fid = fopen(thickness_path, 'w');
if fid < 0, error('summary_section_tables: cannot write %s', thickness_path); end
fprintf(fid, ['d_mm,h_ring_mm,nElems_total,nElems_ring,nElems_medium,across_d,' ...
    'delta_layer,median_abs_yA_over_yB,max_dcc,time_scan_s\n']);
thickness_files = dir(fullfile(P.outdir, 'thick_d*mm_h*.mat'));
thickness_results = cell(numel(thickness_files),1);
for k = 1:numel(thickness_files)
    T = load(fullfile(P.outdir, thickness_files(k).name));
    if ~isfield(T, 'result'), continue; end
    row = T.result;
    thickness_results{k} = row;
    fprintf(fid, '%.6g,%.6g,%d,%d,%d,%.6g,%.12g,%.12g,%.12g,%.8g\n', ...
        row.d_mm, row.h_ring_mm, row.nElems_total, row.nElems_ring, ...
        row.nElems_medium, row.elem_per_thickness, row.delta_layer, ...
        row.median_ratio_A_B, row.max_dcc, row.time_scan_s);
end
fclose(fid);

meta = cceit_make_metadata(P);
tables = struct();
tables.model_A_mesh = struct('levels_mm', A.levels, 'elements', A.nel, ...
    'delta_mesh', A.delta_mesh_A, 'time_scan_s', A.time_mesh_scan_s);
tables.model_B_mesh = B.mesh_result;
tables.layer_sensitivity = A2.res;
medium_sensitivity = repmat(struct('d_m', [], 'frequency_Hz', [], ...
    'sigma', [], 'Delta_p_sigma', [], 'epsr', [], 'Delta_p_epsr', []), ...
    numel(A3.R), 1);
for k = 1:numel(A3.R)
    medium_sensitivity(k).d_m = A3.R(k).d;
    medium_sensitivity(k).frequency_Hz = A3.R(k).f;
    medium_sensitivity(k).sigma = A3.R(k).sig;
    medium_sensitivity(k).Delta_p_sigma = A3.R(k).Sp_sig;
    medium_sensitivity(k).epsr = A3.R(k).eps;
    medium_sensitivity(k).Delta_p_epsr = A3.R(k).Sp_eps;
end
tables.medium_sensitivity = medium_sensitivity;
tables.thickness = thickness_results;
result_path = fullfile(P.outdir, 'section_results_tables.mat');
save(result_path, 'P', 'verification', 'tables', 'meta');
fprintf(['Table CSV files saved:\n  %s\n  %s\n  %s\n  %s\n  %s\n  %s\n' ...
    'Optional thickness CSV: %s\nTable MAT: %s\n'], ...
    verification_path, verification_details_path, mesh_path, layer_path, layer_sensitivity_path, ...
    medium_path, thickness_path, result_path);
