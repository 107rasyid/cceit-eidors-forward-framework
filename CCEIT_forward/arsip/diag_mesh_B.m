% DIAG_MESH_B  Count ring and medium elements without running a solve.
% Implements: Section IV.A, diagnostic check of tank-only mesh refinement.
clear; clc;

P0 = cceit_params();
P = P0;
P.d = 2e-3;
h_values_m = [1.0 0.7 0.5 0.35] * 1e-3;
mesh_diag = repmat(struct('h_ring_m', [], 'nElems_total', [], ...
    'nElems_ring', [], 'nElems_medium', [], 'elem_per_thickness', [], ...
    'nNodes', [], 'success', false, 'error', ''), numel(h_values_m), 1);
result_path = fullfile(P.outdir, 'diag_mesh_B_d2mm.mat');
if exist(result_path, 'file') == 2
    prior = load(result_path);
    if isfield(prior, 'P') && isequaln(prior.P, P) && isfield(prior, 'mesh_diag')
        old_count = min(numel(prior.mesh_diag), numel(mesh_diag));
        for j = 1:old_count
            if prior.mesh_diag(j).success && ...
                    abs(prior.mesh_diag(j).h_ring_m-h_values_m(j)) < 1e-15
                mesh_diag(j) = prior.mesh_diag(j);
            end
        end
    end
end
meta = cceit_make_metadata(P);

for k = 1:numel(h_values_m)
    h_ring_m = h_values_m(k);
    mesh_diag(k).h_ring_m = h_ring_m;
    if mesh_diag(k).success
        fprintf('h_ring=%.2f mm | total=%d | ring=%d | medium=%d | elem/tebal=%.2f (saved, skip)\n', ...
            h_ring_m*1e3, mesh_diag(k).nElems_total, mesh_diag(k).nElems_ring, ...
            mesh_diag(k).nElems_medium, mesh_diag(k).elem_per_thickness);
        continue;
    end
    try
        eidors_cache clear
        [~, ring, info] = cceit_mesh_B4(P, 'tank', h_ring_m);
        mesh_diag(k).nElems_total = info.nElems;
        mesh_diag(k).nElems_ring = sum(ring(:));
        mesh_diag(k).nElems_medium = info.nElems - sum(ring(:));
        mesh_diag(k).elem_per_thickness = info.nAcross;
        mesh_diag(k).nNodes = info.nNodes;
        mesh_diag(k).success = true;
        fprintf('h_ring=%.2f mm | total=%d | ring=%d | medium=%d | elem/tebal=%.2f\n', ...
            h_ring_m*1e3, info.nElems, mesh_diag(k).nElems_ring, ...
            mesh_diag(k).nElems_medium, info.nAcross);
    catch err
        mesh_diag(k).error = err.message;
        fprintf('h_ring=%.2f mm | mesh gagal: %s\n', h_ring_m*1e3, err.message);
    end
    save(result_path, 'P', 'h_values_m', 'mesh_diag', 'meta');
end

save(result_path, 'P', 'h_values_m', 'mesh_diag', 'meta');
fprintf('Diagnostik mesh tersimpan: %s\n', result_path);
