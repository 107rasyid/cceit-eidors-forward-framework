% GENERATE_REPORT Create comprehensive report from run_all results
% Reads all CSV and MAT files from results/ and creates one report file
clear; close all; clc;

P = cceit_params();
outdir = P.outdir;
report_path = fullfile(outdir, 'run_all_report.txt');

fid = fopen(report_path, 'w');
if fid < 0
    error('generate_report: cannot create report file');
end

fprintf(fid, 'CC-EIT Forward Model Results Report\n');
fprintf(fid, '====================================\n\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

%% Read and write run_all log
log_path = fullfile(outdir, 'run_all_log.txt');
if exist(log_path, 'file')
    fprintf(fid, '=== RUN_ALL LOG ===\n');
    log_content = fileread(log_path);
    fprintf(fid, '%s\n\n', log_content);
end

%% Verification results
verify_path = fullfile(outdir, 'cceit_verification_results.mat');
if exist(verify_path, 'file')
    fprintf(fid, '=== VERIFICATION RESULTS ===\n');
    V = load(verify_path);
    fprintf(fid, 'Model A3:\n');
    fprintf(fid, '  Elements: %d\n', V.check_A.nElems);
    fprintf(fid, '  Max dcc: %.3g\n', V.check_A.max_dcc);
    fprintf(fid, '  Max floating/It: %.3g\n', V.check_A.max_dfloat);
    fprintf(fid, '  Max dev U: %.3g V\n', V.check_A.max_dU);
    fprintf(fid, '  Max reciprocity error: %.3g (%d pairs)\n\n', ...
        V.check_A.max_reciprocity_error, numel(V.check_A.reciprocity_errors));
    fprintf(fid, 'Model B6:\n');
    fprintf(fid, '  Elements: %d (ring: %d)\n', V.check_B.nElems, V.check_B.nRing);
    fprintf(fid, '  h_ring: %.2f mm\n', V.check_B.h_ring*1e3);
    fprintf(fid, '  Max dcc: %.3g\n', V.check_B.max_dcc);
    fprintf(fid, '  Max floating/It: %.3g\n', V.check_B.max_dfloat);
    fprintf(fid, '  Max dev U: %.3g V\n', V.check_B.max_dU);
    fprintf(fid, '  Max reciprocity error: %.3g (%d pairs)\n\n', ...
        V.check_B.max_reciprocity_error, numel(V.check_B.reciprocity_errors));
end

%% A3/B6 coarse comparison
coarse_path = fullfile(outdir, 'AB_A3_B6_coarse_results.mat');
if exist(coarse_path, 'file')
    fprintf(fid, '=== A3/B6 COARSE COMPARISON ===\n');
    C = load(coarse_path);
    fprintf(fid, 'Frequency: %.0f kHz\n', C.freq_Hz/1e3);
    fprintf(fid, 'h_ring: %.2f mm\n', C.h_ring*1e3);
    fprintf(fid, 'Model A3:\n');
    fprintf(fid, '  Elements: %d\n', C.info_A.nElems);
    fprintf(fid, '  h_medium: %.2f mm\n', C.info_A.h_medium*1e3);
    fprintf(fid, '  Electrode arc max error: %.4g\n', C.info_A.electrode_arc_max_rel_error);
    fprintf(fid, 'Model B6:\n');
    fprintf(fid, '  Total elements: %d (medium: %d, ring: %d)\n', ...
        C.info_B.nElems, C.info_B.nMedium, C.info_B.nRing);
    fprintf(fid, '  h_medium: %.2f mm, h_ring: %.2f mm\n', ...
        C.info_B.h_medium*1e3, C.info_B.h_ring*1e3);
    fprintf(fid, '  Elements across layer: %.1f\n', C.info_B.nAcross);
    fprintf(fid, 'Delta_layer: %.6g\n', C.delta_layer);
    fprintf(fid, 'Median |yA|/|yB|: %.6g\n', C.median_ratio);
    fprintf(fid, 'B6 max dcc: %.3g\n', C.info_B.dcc);
    fprintf(fid, 'B6 max floating/It: %.3g\n', C.info_B.dfloat);
    fprintf(fid, 'B6 max dev U: %.3g V\n\n', C.info_B.dU);
end

%% B6 resolution study
resolution_path = fullfile(outdir, 'B6_resolution_study.mat');
if exist(resolution_path, 'file')
    fprintf(fid, '=== B6 RESOLUTION STUDY ===\n');
    R = load(resolution_path);
    fprintf(fid, 'Frequency: %.0f kHz\n', R.freq_Hz/1e3);
    fprintf(fid, 'h_medium: %.2f mm\n', R.h_int_B6*1e3);
    fprintf(fid, '\nRing resolution:\n');
    fprintf(fid, 'h_ring (mm) | Total elems | Medium elems | Ring elems | Delta_layer | Median |yA|/|yB|\n');
    fprintf(fid, '-----------|-------------|--------------|-----------|-------------|------------------\n');
    for k = 1:length(R.levels)
        q = R.levels(k);
        fprintf(fid, '%9.3g | %11d | %12d | %9d | %11.6g | %16.6g\n', ...
            q.h_ring_m*1e3, q.nElems, q.nMedium, q.nRing, q.delta_layer, q.median_ratio_A_B);
    end
    fprintf(fid, '\n');
end

%% Sweep A (frequency)
sweepA_path = fullfile(outdir, 'sweepA_results.mat');
if exist(sweepA_path, 'file')
    fprintf(fid, '=== SWEEP A: FREQUENCY ===\n');
    SA = load(sweepA_path);
    fprintf(fid, 'Mesh resolution levels tested: %d\n', size(SA.levels, 1));
    fprintf(fid, 'Frequencies: %s\n', mat2str(SA.freqs));
    fprintf(fid, 'Frequency sweep Delta_p:\n');
    base_idx = find(abs(SA.freqs - SA.P0.f) == min(abs(SA.freqs - SA.P0.f)), 1);
    y_base = SA.Yf(:, base_idx);
    for k = 1:length(SA.freqs)
        delta_p = norm(SA.Yf(:,k) - y_base) / norm(y_base);
        fprintf(fid, '  f = %.0f Hz: Delta_p = %.4g\n', SA.freqs(k), delta_p);
    end
    fprintf(fid, '\n');
end

%% Sweep A2 (layer)
sweepA2_path = fullfile(outdir, 'sweepA2_results.mat');
if exist(sweepA2_path, 'file')
    fprintf(fid, '=== SWEEP A2: LAYER ===\n');
    SA2 = load(sweepA2_path);
    fprintf(fid, 'Mesh elements: %d\n', SA2.iA.nElems);
    fprintf(fid, 'Degeneracy check (2d, 2*epsr_d): Delta_p = %.3g\n\n', SA2.res_degen);
    for k = 1:length(SA2.res)
        r = SA2.res(k);
        fprintf(fid, '%s sweep:\n', r.name);
        fprintf(fid, '  Values: %s\n', mat2str(r.vals));
        fprintf(fid, '  Delta_p: %s\n', mat2str(r.delta));
        fprintf(fid, '  Median |y|: %s\n', mat2str(r.median_abs));
        fprintf(fid, '  Median phase (deg): %s\n\n', mat2str(r.median_phase));
    end
end

%% Sweep A3 (tissue)
sweepA3_path = fullfile(outdir, 'sweepA3_results.mat');
if exist(sweepA3_path, 'file')
    fprintf(fid, '=== SWEEP A3: TISSUE ===\n');
    SA3 = load(sweepA3_path);
    fprintf(fid, 'Mesh elements: %d\n', SA3.iA.nElems);
    fprintf(fid, 'Layer thickness tested: %s mm\n', mat2str(SA3.dlist*1e3));
    fprintf(fid, 'Frequencies tested: %s kHz\n', mat2str(SA3.flist/1e3));
    fprintf(fid, '\nTissue sensitivity results:\n');
    for k = 1:length(SA3.R)
        r = SA3.R(k);
        fprintf(fid, 'd = %.1f mm, f = %.0f kHz\n', r.d*1e3, r.f/1e3);
        fprintf(fid, '  Sigma sensitivity range: [%.3g, %.3g]\n', ...
            min(r.Delta_p_sig), max(r.Delta_p_sig));
        fprintf(fid, '  Epsr sensitivity range: [%.3g, %.3g]\n\n', ...
            min(r.Delta_p_eps), max(r.Delta_p_eps));
    end
end

%% Summary sweeps
summary_path = fullfile(outdir, 'summary_sweeps.mat');
if exist(summary_path, 'file')
    fprintf(fid, '=== SUMMARY SWEEPS ===\n');
    SS = load(summary_path);
    fprintf(fid, '%-12s | %-74s | %-12s | %-12s\n', ...
        'Study', 'Parameter range', 'Delta_p min', 'Delta_p max');
    fprintf(fid, '%s\n', repmat('-',1,120));
    for k = 1:length(SS.study)
        fprintf(fid, '%-12s | %-74s | %-12.4g | %-12.4g\n', ...
            SS.study{k}, SS.parameter_range{k}, SS.delta_range(k,1), SS.delta_range(k,2));
    end
    fprintf(fid, '\n');
end

%% List all CSV files
fprintf(fid, '=== CSV FILES ===\n');
csv_files = dir(fullfile(outdir, '*.csv'));
for k = 1:length(csv_files)
    fprintf(fid, '%s\n', csv_files(k).name);
end
fprintf(fid, '\n');

%% List all MAT files
fprintf(fid, '=== MAT FILES ===\n');
mat_files = dir(fullfile(outdir, '*.mat'));
for k = 1:length(mat_files)
    fprintf(fid, '%s\n', mat_files(k).name);
end
fprintf(fid, '\n');

%% List all PNG files
fprintf(fid, '=== PNG FILES ===\n');
png_files = dir(fullfile(outdir, '*.png'));
for k = 1:length(png_files)
    fprintf(fid, '%s\n', png_files(k).name);
end

fclose(fid);
fprintf('Report generated: %s\n', report_path);
