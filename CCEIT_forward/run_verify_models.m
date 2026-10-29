% RUN_VERIFY_MODELS  Verify A/B pair scans and reciprocity on 30 pairs.
%
% Implements: Section IV.A, current conservation and forward-solver verification.
% Requires EIDORS startup and the active Model A/B forward functions.

clear; clc;
P = cceit_params();
omega = 2*pi*P.f;
gamma = P.sigma + 1i*omega*P.eps0*P.epsr;
gamma_layer = P.sigma_d + 1i*omega*P.eps0*P.epsr_d;
eidors_cache clear

%% Model A: lumped interface
[fmdl_A, info_A] = cceit_mesh_A(P);
z_contact_A = 1 / (P.sigma_d/P.d + 1i*omega*P.eps0*P.epsr_d/P.d);
for e = 1:P.nElec
    fmdl_A.electrode(e).z_contact = z_contact_A;
end
gamma_A = gamma * ones(size(fmdl_A.elems, 1), 1);
out_A = cceit_pairscan(fmdl_A, gamma_A, P);

pair_index = unique(round(linspace(1, size(out_A.pairs, 1), ...
    P.n_reciprocity_pairs)));
reciprocity_pairs = out_A.pairs(pair_index, :);
reciprocity_A = zeros(numel(pair_index), 1);
for k = 1:numel(pair_index)
    t = reciprocity_pairs(k, 1);
    r = reciprocity_pairs(k, 2);
    I_reverse = cceit_solve_pair(fmdl_A, gamma_A, P, r, t);
    y_forward = out_A.Y(t, r);
    y_reverse = I_reverse(r) / P.Vtx;
    reciprocity_A(k) = abs(y_forward - y_reverse) / max(abs(y_forward), realmin);
end
check_A = struct('nElems', info_A.nElems, ...
    'max_dcc', max(out_A.dcc), ...
    'max_dfloat', max(out_A.dfloat), ...
    'max_dU', max(out_A.dU), ...
    'max_reciprocity_error', max(reciprocity_A), ...
    'reciprocity_errors', reciprocity_A);
fprintf(['Model A: %d elements | max dcc = %.3g | max floating/It = %.3g | ' ...
         'max dev U = %.3g V | max reciprocity error = %.3g (%d pairs)\n'], ...
    check_A.nElems, check_A.max_dcc, check_A.max_dfloat, check_A.max_dU, ...
    check_A.max_reciprocity_error, numel(pair_index));

%% Model B: explicit dielectric ring at the working resolution
[fmdl_B, ring_B, info_B] = cceit_mesh_B4(P, 'tank', P.h_ring_B);
gamma_B = gamma * ones(info_B.nElems, 1);
gamma_B(ring_B) = gamma_layer;
out_B = cceit_pairscan(fmdl_B, gamma_B, P);
reciprocity_B = zeros(numel(pair_index), 1);
for k = 1:numel(pair_index)
    t = reciprocity_pairs(k, 1);
    r = reciprocity_pairs(k, 2);
    I_reverse = cceit_solve_pair(fmdl_B, gamma_B, P, r, t);
    y_forward = out_B.Y(t, r);
    y_reverse = I_reverse(r) / P.Vtx;
    reciprocity_B(k) = abs(y_forward - y_reverse) / max(abs(y_forward), realmin);
end
check_B = struct('nElems', info_B.nElems, ...
    'nRing', info_B.nRing, ...
    'h_ring', P.h_ring_B, ...
    'max_dcc', max(out_B.dcc), ...
    'max_dfloat', max(out_B.dfloat), ...
    'max_dU', max(out_B.dU), ...
    'max_reciprocity_error', max(reciprocity_B), ...
    'reciprocity_errors', reciprocity_B);
fprintf(['Model B: %d elements (%d ring) | h_ring = %.2f mm | max dcc = %.3g | ' ...
         'max floating/It = %.3g | max dev U = %.3g V | ' ...
         'max reciprocity error = %.3g (%d pairs)\n'], ...
    check_B.nElems, check_B.nRing, check_B.h_ring*1e3, check_B.max_dcc, ...
    check_B.max_dfloat, check_B.max_dU, check_B.max_reciprocity_error, ...
    numel(pair_index));

meta.version = version;
meta.date = datestr(now);
result_path = fullfile(P.outdir, 'cceit_verification_results.mat');
save(result_path, 'P', 'check_A', 'check_B', 'reciprocity_pairs', 'meta');
fprintf('Hasil verifikasi tersimpan: %s\n', result_path);
