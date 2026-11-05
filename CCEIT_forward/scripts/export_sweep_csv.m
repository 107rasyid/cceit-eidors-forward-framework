% EXPORT_SWEEP_CSV Export existing Goal 3 MAT sweep results as tidy CSV files.
% Implements: Section IV.D data handoff; performs no mesh build or forward solve.
clear; clc;
P = cceit_params();

%% Frequency and Model A mesh-convergence data
freq_path = fullfile(P.outdir, 'sweepA_results.mat');
if exist(freq_path, 'file') ~= 2
    error('export_sweep_csv: missing sweepA_results.mat; run run_sweepA first');
end
F = load(freq_path);
if ~isfield(F, 'Yf') || ~isfield(F, 'freqs') || ~isfield(F, 'P0')
    error('export_sweep_csv: sweepA_results.mat has an unexpected structure');
end
freq_csv = fullfile(P.outdir, 'sweepA_frequency_data.csv');
fid = fopen(freq_csv, 'w');
if fid < 0, error('export_sweep_csv: cannot write frequency CSV'); end
fprintf(fid, 'frequency_Hz,median_abs_pair_admittance_per_m_depth,median_phase_deg,Delta_p\n');
base_idx = find(abs(F.freqs-P.f) == min(abs(F.freqs-P.f)), 1);
y_base = F.Yf(:,base_idx);
for k = 1:numel(F.freqs)
    y_freq = F.Yf(:,k);
    delta_p = norm(y_freq-y_base)/norm(y_base);
    fprintf(fid, '%.12g,%.12g,%.12g,%.12g\n', F.freqs(k), ...
        median(abs(y_freq)), median(angle(y_freq))*180/pi, delta_p);
end
fclose(fid);

mesh_csv = fullfile(P.outdir, 'sweepA_mesh_convergence.csv');
fid = fopen(mesh_csv, 'w');
if fid < 0, error('export_sweep_csv: cannot write mesh CSV'); end
fprintf(fid, 'level,h_int_mm,h_el_mm,elements,Delta_mesh_A,mesh_build_s,scan_s,success\n');
for k = 1:size(F.levels,1)
    fprintf(fid, '%d,%.9g,%.9g,%d,%.12g,%.12g,%.12g,%d\n', k, ...
        F.levels(k,1), F.levels(k,2), F.nel(k), F.delta_mesh_A(k), ...
        F.time_mesh_build_s(k), F.time_mesh_scan_s(k), F.ok(k));
end
fclose(fid);

%% Layer and single-condition medium sweeps
a2_path = fullfile(P.outdir, 'sweepA2_results.mat');
if exist(a2_path, 'file') ~= 2
    error('export_sweep_csv: missing sweepA2_results.mat; run run_sweepA2 first');
end
A2 = load(a2_path);
a2_csv = fullfile(P.outdir, 'sweepA2_long.csv');
fid = fopen(a2_csv, 'w');
if fid < 0, error('export_sweep_csv: cannot write A2 CSV'); end
fprintf(fid, ['parameter,value_SI,unit,factor,Delta_p,median_abs_pair_admittance,' ...
    'median_phase_deg,phase_change_deg,flag,baseline_frequency_Hz\n']);
for i = 1:numel(A2.res)
    for j = 1:numel(A2.res(i).vals)
        fprintf(fid, '%s,%.12g,%s,%.12g,%.12g,%.12g,%.12g,%.12g,%d,%.12g\n', ...
            A2.res(i).name, A2.res(i).vals(j), A2.res(i).unit, ...
            A2.res(i).factors(j), A2.res(i).delta(j), ...
            A2.res(i).median_abs(j), A2.res(i).median_phase(j), ...
            A2.res(i).phase_diff(j), A2.res(i).flag(j), A2.P0.f);
    end
end
fclose(fid);

%% Medium sweeps, one row per parameter perturbation
a3_path = fullfile(P.outdir, 'sweepA3_results.mat');
if exist(a3_path, 'file') ~= 2
    error('export_sweep_csv: missing sweepA3_results.mat; run run_sweepA3 first');
end
A3 = load(a3_path);
a3_csv = fullfile(P.outdir, 'sweepA3_long.csv');
fid = fopen(a3_csv, 'w');
if fid < 0, error('export_sweep_csv: cannot write A3 CSV'); end
fprintf(fid, ['d_mm,frequency_Hz,parameter,baseline,value,factor,Delta_p,' ...
    'median_abs_pair_admittance,phase_change_deg,flag\n']);
for i = 1:numel(A3.R)
    for j = 1:numel(A3.R(i).factors)
        fprintf(fid, '%.9g,%.12g,sigma_S_m,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d\n', ...
            A3.R(i).d*1e3, A3.R(i).f, A3.P0.sigma, A3.R(i).sig_vals(j), ...
            A3.R(i).factors(j), A3.R(i).Delta_p_sig(j), ...
            A3.R(i).median_abs_sig(j), A3.R(i).phase_diff_sig(j), A3.R(i).flag);
        fprintf(fid, '%.9g,%.12g,epsr,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d\n', ...
            A3.R(i).d*1e3, A3.R(i).f, A3.P0.epsr, A3.R(i).eps_vals(j), ...
            A3.R(i).factors(j), A3.R(i).Delta_p_eps(j), ...
            A3.R(i).median_abs_eps(j), A3.R(i).phase_diff_eps(j), A3.R(i).flag);
    end
end
fclose(fid);

fprintf('CSV exports from existing MAT files (no simulations run):\n');
fprintf('  %s\n  %s\n  %s\n  %s\n', freq_csv, mesh_csv, a2_csv, a3_csv);
