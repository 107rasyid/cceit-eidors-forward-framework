function mesh_result = run_B_resolution_study(recompute_missing)
% RUN_B_RESOLUTION_STUDY Assemble/compute the d=2 mm Model B mesh sweep.
% Purpose: provide paired admittances, element counts, mesh changes, and scan
% times for the Section IV mesh and contact-impedance comparison tables.
% Inputs: recompute_missing (optional logical); true solves any missing mesh.
% Outputs: mesh_result with one record for each h_ring target.
% Manuscript ref: Section IV.B, explicit-layer mesh convergence.

if nargin < 1 || isempty(recompute_missing)
    recompute_missing = false;
end
if ~isscalar(recompute_missing)
    error('run_B_resolution_study: recompute_missing must be scalar');
end

P = cceit_params();
P.d = 2e-3;
freq_Hz = 500e3;
h_values_m = [1.0 0.7 0.5 0.35]*1e-3;
AB_path = fullfile(P.outdir, 'cceit_AB_final_results.mat');
if exist(AB_path, 'file') ~= 2
    error('run_B_resolution_study: run scripts/run_AB_final.m first');
end
AB = load(AB_path);
if ~isfield(AB, 'results') || ~isfield(AB.results, 'y_A') || ...
        abs(AB.freq_Hz-freq_Hz) > 1e-6
    error('run_B_resolution_study: A/B result does not match the 500 kHz baseline');
end
y_A = AB.results.y_A(:);
current_AB_match = isfield(AB, 'P') && cceit_same_baseline(AB.P, P);

legacy_path = fullfile(P.outdir, 'tes_B4_results.mat');
legacy = struct();
if exist(legacy_path, 'file') == 2
    legacy = load(legacy_path);
end
legacy_diff = {'missing P0'};
if isfield(legacy, 'P0')
    [~, legacy_diff] = cceit_same_baseline(legacy.P0, P);
end
legacy_match = isfield(legacy, 'P0') && isfield(legacy, 'R') && ...
    isfield(legacy.R, 'tank') && isfield(legacy.R.tank, 'ok') && ...
    isfield(legacy.R.tank, 'yB') && isfield(legacy, 'hrs') && ...
    cceit_same_baseline(legacy.P0, P);

diag_path = fullfile(P.outdir, 'diag_mesh_B_d2mm.mat');
diag_data = struct();
if exist(diag_path, 'file') == 2
    diag_data = load(diag_path);
end

mesh_result = repmat(struct('h_ring_m', [], 'nElems_total', [], ...
    'nElems_ring', [], 'nElems_medium', [], 'across_d', [], ...
    'delta_mesh', [], 'delta_layer', [], 'median_ratio_A_B', [], ...
    'time_scan_s', [], 'time_source', '', 'max_dcc', NaN, ...
    'y_B', [], 'info_B', struct()), numel(h_values_m), 1);
R = struct();
R.tank.yB = cell(size(h_values_m));
R.tank.ok = false(size(h_values_m));

for k = 1:numel(h_values_m)
    h_ring_m = h_values_m(k);
    mesh_result(k).h_ring_m = h_ring_m;
    point_path = fullfile(P.outdir, sprintf('B_resolution_h%.2fmm.mat', h_ring_m*1e3));
    loaded_point = false;
    if exist(point_path, 'file') == 2
        point = load(point_path);
        if isfield(point, 'P') && isfield(point, 'result') && ...
                isfield(point, 'y_A') && isfield(point, 'y_B') && ...
                cceit_same_baseline(point.P, P) && ...
                abs(point.result.h_ring_m-h_ring_m) < 1e-12
            mesh_result(k) = point.result;
            R.tank.yB{k} = point.y_B(:);
            R.tank.ok(k) = true;
            loaded_point = true;
        end
    end
    if loaded_point
        continue;
    end

    % Reuse current-baseline scans already produced by run_AB_final. This
    % avoids repeating the 1.0 and 0.5 mm solves when only finer/missing
    % resolution points need to be recomputed.
    reused_current_AB = false;
    if current_AB_match && isfield(AB.results, 'h_ring') && ...
            isfield(AB.results, 'y_B') && isfield(AB.results, 'info_B')
        ab_k = find(abs(AB.results.h_ring(:)-h_ring_m) < 1e-12, 1);
        if ~isempty(ab_k) && numel(AB.results.y_B) >= ab_k && ...
                numel(AB.results.info_B) >= ab_k && ...
                numel(AB.results.y_B{ab_k}) == numel(y_A)
            y_B = AB.results.y_B{ab_k}(:);
            info_B = AB.results.info_B{ab_k};
            source = 'current-baseline run_AB_final result';
            time_scan_s = NaN; % run_AB_final did not time individual scans.
            reused_current_AB = true;
        end
    end

    reused_legacy = legacy_match && numel(legacy.hrs) == numel(legacy.R.tank.ok);
    if reused_legacy
        old_k = find(abs(legacy.hrs(:)-h_ring_m) < 1e-12, 1);
        reused_legacy = ~isempty(old_k) && legacy.R.tank.ok(old_k) && ...
            numel(legacy.R.tank.yB{old_k}) == numel(y_A);
    end

    if reused_current_AB
        % Already populated from the current run_AB_final MAT file.
    elseif reused_legacy
        y_B = legacy.R.tank.yB{old_k}(:);
        source = 'preserved prior B4 scan';
        known_times = [44 122 319 941]; % Measured values supplied for this mesh sweep.
        time_scan_s = known_times(k);
        info_B = struct();
        if isfield(diag_data, 'mesh_diag') && numel(diag_data.mesh_diag) >= k && ...
                diag_data.mesh_diag(k).success
            md = diag_data.mesh_diag(k);
            info_B.nElems = md.nElems_total;
            info_B.nRing = md.nElems_ring;
            info_B.nAcross = md.elem_per_thickness;
        else
            info_B = [];
        end
    elseif recompute_missing
        timer_scan = tic;
        [y_B, info_B] = cceit_runB(P, freq_Hz, h_ring_m);
        time_scan_s = toc(timer_scan);
        source = 'timed during this run';
    else
        if isempty(legacy_diff)
            mismatch_text = 'legacy scan fields or mesh resolutions do not match';
        else
            mismatch_text = strjoin(legacy_diff, ', ');
        end
        error(['run_B_resolution_study: missing or baseline-mismatched data at ' ...
            'h_ring=%.2f mm (mismatched baseline fields: %s). ' ...
            'Inspect tes_B4_results.mat or recompute with ' ...
            'run_B_resolution_study(true).'], h_ring_m*1e3, mismatch_text);
    end

    if isempty(info_B)
        if recompute_missing
            timer_mesh = tic;
            [~, ~, info_B] = cceit_mesh_B4(P, 'tank', h_ring_m);
            info_B.mesh_only_time_s = toc(timer_mesh);
        else
            error('run_B_resolution_study: missing mesh counts for h_ring=%.2f mm', h_ring_m*1e3);
        end
    end

    mesh_result(k).nElems_total = info_B.nElems;
    mesh_result(k).nElems_ring = info_B.nRing;
    mesh_result(k).nElems_medium = info_B.nElems-info_B.nRing;
    mesh_result(k).across_d = info_B.nAcross;
    mesh_result(k).delta_layer = norm(y_A-y_B)/norm(y_B);
    mesh_result(k).median_ratio_A_B = median(abs(y_A)./abs(y_B));
    mesh_result(k).time_scan_s = time_scan_s;
    mesh_result(k).time_source = source;
    mesh_result(k).y_B = y_B;
    mesh_result(k).info_B = info_B;
    if isfield(info_B, 'dcc'), mesh_result(k).max_dcc = info_B.dcc; end
    R.tank.yB{k} = y_B;
    R.tank.ok(k) = true;

    result = mesh_result(k);
    meta = cceit_make_metadata(P);
    save(point_path, 'P', 'freq_Hz', 'y_A', 'y_B', 'result', 'meta');
end

valid = find(R.tank.ok);
if isempty(valid)
    error('run_B_resolution_study: no valid resolution results are available');
end
ref_index = valid(end);
y_ref = R.tank.yB{ref_index};
for k = valid(:).'
    mesh_result(k).delta_mesh = norm(R.tank.yB{k}-y_ref)/norm(y_ref);
end

R.tank.info = {mesh_result.info_B}.';
R.tank.time_scan_s = [mesh_result.time_scan_s].';
R.tank.nElems = [mesh_result.nElems_total].';
R.tank.delta_layer = [mesh_result.delta_layer].';
R.tank.delta_mesh = [mesh_result.delta_mesh].';
hrs = h_values_m;
P0 = P;
yA = y_A;  % Preserve the field name used by the existing mesh-plot reader.
meta = cceit_make_metadata(P);
summary_path = fullfile(P.outdir, 'B_resolution_study.mat');
save(summary_path, 'P0', 'P', 'freq_Hz', 'hrs', 'y_A', 'yA', 'R', ...
    'mesh_result', 'ref_index', 'meta');

csv_path = fullfile(P.outdir, 'B_resolution_study.csv');
fid = fopen(csv_path, 'w');
if fid < 0
    error('run_B_resolution_study: cannot write %s', csv_path);
end
fprintf(fid, ['h_ring_mm,nElems_total,nElems_ring,nElems_medium,across_d,' ...
    'delta_mesh,delta_layer,median_abs_yA_over_yB,time_scan_s,time_source\n']);
for k = valid(:).'
    fprintf(fid, '%.6g,%d,%d,%d,%.6g,%.12g,%.12g,%.12g,%.6g,"%s"\n', ...
        mesh_result(k).h_ring_m*1e3, mesh_result(k).nElems_total, ...
        mesh_result(k).nElems_ring, mesh_result(k).nElems_medium, ...
        mesh_result(k).across_d, mesh_result(k).delta_mesh, ...
        mesh_result(k).delta_layer, mesh_result(k).median_ratio_A_B, ...
        mesh_result(k).time_scan_s, mesh_result(k).time_source);
end
fclose(fid);

fprintf('Model B mesh convergence (reference h_ring=%.2f mm)\n', hrs(ref_index)*1e3);
for k = valid(:).'
    fprintf(['h=%.2f mm | elems=%d (ring %d, medium %d) | across d=%.2f | ' ...
        'delta_mesh=%.3g | delta_layer=%.4f | median ratio=%.4f | time=%.1f s\n'], ...
        mesh_result(k).h_ring_m*1e3, mesh_result(k).nElems_total, ...
        mesh_result(k).nElems_ring, mesh_result(k).nElems_medium, ...
        mesh_result(k).across_d, mesh_result(k).delta_mesh, ...
        mesh_result(k).delta_layer, mesh_result(k).median_ratio_A_B, ...
        mesh_result(k).time_scan_s);
end
fprintf('B-resolution MAT: %s\nB-resolution CSV: %s\n', summary_path, csv_path);
end
