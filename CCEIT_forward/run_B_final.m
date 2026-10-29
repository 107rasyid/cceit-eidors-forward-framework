% RUN_B_FINAL  Run Model B at the coarse diagnostic ring resolution.
%
% Implements: Section IV.A, Model B mesh and forward-solve checks.
% Requires EIDORS startup, cceit_params, and cceit_runB.

clear; clc;
P = cceit_params();
freq_cache = P.f;
h_ring_cache = P.h_ring_B_coarse;

eidors_cache clear
[y_B_coarse, info_B_coarse] = cceit_runB(P, freq_cache, h_ring_cache);

fprintf('Model B coarse: %.0f kHz, h_ring = %.2f mm, %d elements\n', ...
    freq_cache/1e3, h_ring_cache*1e3, info_B_coarse.nElems);
fprintf('  max dcc = %.3g | max floating/It = %.3g | max dev U = %.3g V\n', ...
    info_B_coarse.dcc, info_B_coarse.dfloat, info_B_coarse.dU);

P_cache = P;
result_path = fullfile(P.outdir, 'cceit_B_coarse_results.mat');
save(result_path, 'P_cache', 'freq_cache', 'h_ring_cache', ...
    'y_B_coarse', 'info_B_coarse');
fprintf('Hasil tersimpan: %s\n', result_path);
