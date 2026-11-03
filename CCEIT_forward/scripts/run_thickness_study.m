% RUN_THICKNESS_STUDY  Compare Model A and B over selected layer thicknesses.
% Implements: Section IV.B, explicit-layer thickness and mesh-resolution study.
clear; clc;

P0 = cceit_params();
d_values_mm = [3 5 1];  % Keep this order: coarse, medium, then thin layer.
ring_divisors = [3 4];

eidors_cache clear
[fmdl_A, info_A] = cceit_mesh_A(P0);  % Reuse one A mesh across all thicknesses.
fprintf('Model A mesh reused: %d elements\n', info_A.nElems);

for id = 1:numel(d_values_mm)
    d_mm = d_values_mm(id);
    P = P0;
    P.d = d_mm * 1e-3;

    output_paths = cell(1, numel(ring_divisors));
    todo = false(1, numel(ring_divisors));
    for ir = 1:numel(ring_divisors)
        h_ring_m = P.d / ring_divisors(ir);
        output_name = sprintf('thick_d%gmm_h%.2fmm.mat', ...
            d_mm, h_ring_m*1e3);
        output_paths{ir} = fullfile(P.outdir, output_name);
        todo(ir) = exist(output_paths{ir}, 'file') ~= 2;
    end
    if ~any(todo)
        fprintf('d = %.1f mm: semua titik sudah tersimpan, dilewati.\n', d_mm);
        continue;
    end

    try
        timer_A = tic;
        y_A = cceit_runA_mesh(fmdl_A, P, P.f);
        time_A_s = toc(timer_A);
    catch err_A
        fprintf('d = %.1f mm: Model A gagal: %s\n', d_mm, err_A.message);
        continue;
    end

    for ir = 1:numel(ring_divisors)
        if ~todo(ir)
            fprintf('d = %.1f mm, h_ring = %.2f mm: hasil ada, dilewati.\n', ...
                d_mm, P.d/ring_divisors(ir)*1e3);
            continue;
        end

        h_ring_m = P.d / ring_divisors(ir);
        try
            eidors_cache clear
            timer_B = tic;
            [y_B, info_B] = cceit_runB(P, P.f, h_ring_m);
            time_B_s = toc(timer_B);

            result = struct();
            result.d_m = P.d;
            result.d_mm = d_mm;
            result.freq_Hz = P.f;
            result.h_ring_m = h_ring_m;
            result.h_ring_mm = h_ring_m*1e3;
            result.nElems_total = info_B.nElems;
            result.nElems_ring = info_B.nRing;
            result.nElems_medium = info_B.nElems - info_B.nRing;
            result.elem_per_thickness = info_B.nAcross;
            result.mean_radial_span_m = P.d / info_B.nAcross;
            result.delta_layer = norm(y_A-y_B) / norm(y_B);
            result.median_ratio_A_B = median(abs(y_A)./abs(y_B));
            result.max_dcc = info_B.dcc;
            result.max_dfloat = info_B.dfloat;
            result.max_dU = info_B.dU;
            result.time_A_s = time_A_s;
            result.time_B_s = time_B_s;
            result.time_scan_s = time_A_s + time_B_s;
            result.info_A = info_A;
            result.info_B = info_B;

            meta = cceit_make_metadata(P);
            save(output_paths{ir}, 'P', 'y_A', 'y_B', 'result', 'meta');
            fprintf(['d=%.1f mm | h_ring=%.2f mm | elems=%d (ring %d, medium %d) | ' ...
                'elem/tebal=%.2f | delta_layer=%.4f | median |yA|/|yB|=%.4f | ' ...
                'max dcc=%.3g | scan=%.1f s\n'], ...
                result.d_mm, result.h_ring_mm, result.nElems_total, ...
                result.nElems_ring, result.nElems_medium, ...
                result.elem_per_thickness, result.delta_layer, ...
                result.median_ratio_A_B, result.max_dcc, result.time_scan_s);
        catch err_B
            fprintf('d = %.1f mm, h_ring = %.3f mm gagal: %s\n', ...
                d_mm, h_ring_m*1e3, err_B.message);
        end
    end
end

fprintf('Studi selesai/terhenti; hasil parsial ada di %s\n', P0.outdir);
