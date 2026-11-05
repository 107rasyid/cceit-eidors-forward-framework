% run_sweepA3.m
% Sensitivitas jaringan (sigma, epsr) pada beberapa d dan f, model A3.
% Ukuran: Delta_p = ||y(p)-y(p0)|| / ||y(p0)||.
% Median magnitude dan phase change are stored as descriptive outputs.
clear; close all; clc;

P0 = cceit_params();
eidors_cache clear
[fA, iA] = cceit_mesh_A3(P0);
fprintf('Mesh A3: %d elemen\n', iA.nElems);

dlist = [0.5 1 2 4]*1e-3;               % tebal lapisan [m]
flist = [100e3 500e3 1e6 3e6];            % frekuensi [Hz]
factors = [0.25 0.5 2 4];                % faktor skala sigma dan epsr

result_path = fullfile(P0.outdir, 'sweepA3_results.mat');

% Load existing results if exists
if exist(result_path, 'file')
    L = load(result_path);
    expected_fields = {'d','f','factors','sig_vals','eps_vals', ...
        'Delta_p_sig','Delta_p_eps','median_abs_sig','median_abs_eps', ...
        'phase_diff_sig','phase_diff_eps','flag','y0'};
    if isfield(L, 'R') && (isempty(L.R) || ...
            isequal(fieldnames(L.R), expected_fields(:)))
        existing_R = L.R;
    else
        % Ignore results from older schemas; mixing struct layouts makes Octave cat fail.
        existing_R = [];
    end
else
    existing_R = [];
end

R = struct('d',{},'f',{},'factors',{},'sig_vals',{},'eps_vals',{}, ...
    'Delta_p_sig',{},'Delta_p_eps',{},'median_abs_sig',{},'median_abs_eps',{}, ...
    'phase_diff_sig',{},'phase_diff_eps',{},'flag',{},'y0',{});
k = 0;

for a = 1:numel(dlist)
  for b = 1:numel(flist)
    P = P0;  P.d = dlist(a);  f = flist(b);
    
    % Check if this (d,f) combination already exists
    skip = false;
    if ~isempty(existing_R)
        for r_idx = 1:length(existing_R)
            if abs(existing_R(r_idx).d - P.d) < 1e-12 && abs(existing_R(r_idx).f - f) < 1e-6
                fprintf('Skipping d=%.1f mm, f=%.0f kHz (already in results)\n', P.d*1e3, f/1e3);
                R = [R; existing_R(r_idx)];
                k = k + 1;
                skip = true;
                break;
            end
        end
    end
    if skip, continue; end
    
    y0 = cceit_runA3_mesh(fA, P, f);
    median_phase_y0 = median(angle(y0))*180/pi;

    delta_p_sig = zeros(size(factors));
    ma_s = zeros(size(factors));
    pd_s = zeros(size(factors));
    for j = 1:numel(factors)
      Q = P;  Q.sigma = P0.sigma * factors(j);
      y = cceit_runA3_mesh(fA, Q, f);
      delta_p_sig(j) = norm(y-y0)/norm(y0);
      ma_s(j) = median(abs(y));
      pd_s(j) = median(angle(y))*180/pi - median_phase_y0;
    end
    
    delta_p_eps = zeros(size(factors));
    ma_e = zeros(size(factors));
    pd_e = zeros(size(factors));
    for j = 1:numel(factors)
      Q = P;  Q.epsr = P0.epsr * factors(j);
      y = cceit_runA3_mesh(fA, Q, f);
      delta_p_eps(j) = norm(y-y0)/norm(y0);
      ma_e(j) = median(abs(y));
      pd_e(j) = median(angle(y))*180/pi - median_phase_y0;
    end

    k = k + 1;
    R(k).d = P.d; R(k).f = f; R(k).factors = factors;
    R(k).sig_vals = P0.sigma * factors;
    R(k).eps_vals = P0.epsr * factors;
    R(k).Delta_p_sig = delta_p_sig;
    R(k).Delta_p_eps = delta_p_eps;
    R(k).median_abs_sig = ma_s;
    R(k).median_abs_eps = ma_e;
    R(k).phase_diff_sig = pd_s;
    R(k).phase_diff_eps = pd_e;
    R(k).y0 = y0;
    % Flag d di luar [1,5] mm
    if P.d < 1e-3 || P.d > 5e-3
        R(k).flag = true;
    else
        R(k).flag = false;
    end

    fprintf('\nd = %.1f mm, f = %.0f kHz  (baseline sigma=%g, epsr=%g)\n', ...
            P.d*1e3, f/1e3, P0.sigma, P0.epsr);
    fprintf('  factors: %s\n', mat2str(factors));
    fprintf('  sigma Delta_p     : %s\n', mat2str(delta_p_sig, '%10.3e'));
    fprintf('  sigma median |y|  : %s\n', mat2str(ma_s, '%10.3e'));
    fprintf('  sigma phase diff  : %s\n', mat2str(pd_s, '%10.3e'));
    fprintf('  epsr Delta_p      : %s\n', mat2str(delta_p_eps, '%10.3e'));
    fprintf('  epsr median |y|  : %s\n', mat2str(ma_e, '%10.3e'));
    fprintf('  epsr phase diff   : %s\n', mat2str(pd_e, '%10.3e'));

    meta = cceit_make_metadata(P0);
    save(result_path,'R','P0','iA','dlist','flist','factors','meta');
  end
end
fprintf('\nSelesai. Hasil di sweepA3_results.mat\n');

% Write CSV
csv_path = fullfile(P0.outdir, 'sweepA3_table.csv');
fid = fopen(csv_path, 'w');
if fid < 0, error('run_sweepA3: cannot write CSV'); end
fprintf(fid, ['d_mm,f_kHz,factor,sigma_S_m,epsr,Delta_p_sig,median_abs_sig,' ...
    'phase_diff_sig_deg,Delta_p_eps,median_abs_eps,phase_diff_eps_deg,flag\n']);
for k = 1:length(R)
    for j = 1:length(R(k).factors)
        fprintf(fid, '%.3g,%.3g,%.3g,%.4g,%.4g,%.6g,%.6g,%.6g,%.6g,%.6g,%.6g,%d\n', ...
            R(k).d*1e3, R(k).f/1e3, R(k).factors(j), R(k).sig_vals(j), R(k).eps_vals(j), ...
            R(k).Delta_p_sig(j), R(k).median_abs_sig(j), R(k).phase_diff_sig(j), ...
            R(k).Delta_p_eps(j), R(k).median_abs_eps(j), R(k).phase_diff_eps(j), R(k).flag);
    end
end
fclose(fid);
fprintf('CSV saved: %s\n', csv_path);
