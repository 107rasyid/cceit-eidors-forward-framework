% RUN_AB_FINAL  Compare Model A with B4 at coarse and working ring resolutions.
%
% Implements: Section IV.B, explicit-layer comparison and its mesh sensitivity.
% Requires EIDORS startup, cceit_params, cceit_mesh_A, cceit_runA_mesh,
% and cceit_runB. The A mesh and core mesh remain controlled by P.h_int.

clear; close all; clc;
P = cceit_params();
freq_Hz = P.f;

fprintf('=== Model A/B comparison at %.0f kHz ===\n', freq_Hz/1e3);

% Model A uses the lumped interface on its own mesh.
eidors_cache clear
[fmdl_A, info_A] = cceit_mesh_A(P);
y_A = cceit_runA_mesh(fmdl_A, P, freq_Hz);
fprintf('Model A: %d elements, h_int = %.2f mm\n', info_A.nElems, P.h_int*1e3);

% Run the inexpensive B mesh and the designated working mesh independently.
h_ring_values = [P.h_ring_B_coarse, P.h_ring_B];
results = struct();
results.freq_Hz = freq_Hz;
results.y_A = y_A;
results.info_A = info_A;
results.h_ring = h_ring_values;
results.y_B = cell(size(h_ring_values));
results.info_B = cell(size(h_ring_values));
results.delta_layer = zeros(size(h_ring_values));
results.median_ratio_A_B = zeros(size(h_ring_values));

for k = 1:numel(h_ring_values)
    h_ring = h_ring_values(k);
    cache_path = fullfile(P.outdir, 'cceit_B_coarse_results.mat');
    reused_coarse = false;
    if k == 1 && exist(cache_path, 'file')
        cached = load(cache_path);
        if isfield(cached, 'P_cache') && isfield(cached, 'freq_cache') && ...
                isfield(cached, 'h_ring_cache') && isfield(cached, 'y_B_coarse') && ...
                isfield(cached, 'info_B_coarse') && isequaln(cached.P_cache, P) && ...
                cached.freq_cache == freq_Hz && cached.h_ring_cache == h_ring
            y_B = cached.y_B_coarse;
            info_B = cached.info_B_coarse;
            reused_coarse = true;
        end
    end
    if ~reused_coarse
        eidors_cache clear
        [y_B, info_B] = cceit_runB(P, freq_Hz, h_ring);
    else
        fprintf('Model B coarse: memakai hasil tersimpan %s\n', cache_path);
    end
    results.y_B{k} = y_B;
    results.info_B{k} = info_B;
    results.delta_layer(k) = norm(y_A - y_B) / norm(y_B);
    results.median_ratio_A_B(k) = median(abs(y_A) ./ abs(y_B));

    fprintf(['Model B: h_ring = %.2f mm | %d elements | delta_layer = %.4f | ' ...
             'median |y_A|/|y_B| = %.4f\n'], ...
        h_ring*1e3, info_B.nElems, results.delta_layer(k), ...
        results.median_ratio_A_B(k));
    fprintf('  max dcc = %.3g | max floating/It = %.3g | max dev U = %.3g V\n', ...
        info_B.dcc, info_B.dfloat, info_B.dU);
end

meta.version = version;
meta.date = datestr(now);
result_path = fullfile(P.outdir, 'cceit_AB_final_results.mat');
save(result_path, 'P', 'freq_Hz', 'results', 'meta');
fprintf('Hasil tersimpan: %s\n', result_path);
