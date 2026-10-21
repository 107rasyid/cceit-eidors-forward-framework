%% RUN_CCEIT  Reproducible CC-EIT forward workflow
%  Paper: "A Reproducible EIDORS Workflow for Voltage-Driven CC-EIT"
%
%  Alur:
%    (1) Receiver scan di base mesh
%    (2) Current conservation check
%    (3) Mesh refinement study
%    (4) Comparison vs explicit dielectric-layer reference
%    (5) Plots + CSV export

clear; close all; clc;

% Path EIDORS — EDIT
run('C:\Users\user\Documents\GitHub\eidors-v3.12\startup.m');

P = cceit_params();

fprintf('\n=== CC-EIT Forward Workflow ===\n');
fprintf('nElec = %d, radius = %.3f m, tx = %d\n', P.nElec, P.radius_m, P.tx);
fprintf('C_eff = %.3e F/m, G = %.3e S/m\n', P.Ceff_F_per_m, P.Gcontact_S_per_m);

freq = P.freq_Hz(1);

%% (1) Base mesh + receiver scan
fprintf('\n[1] Receiver scan (base mesh, f = %.0f kHz)\n', freq/1e3);
fmdl = cceit_build_model(P, 0);
R_base = cceit_receiver_scan(P, fmdl, freq);

%% (2) Current conservation
fprintf('\n[2] Current conservation\n');
V_base = cceit_verify(P, R_base);
fprintf('    max |sum(I_elec)|   = %.2e A\n', V_base.max_sum_I);
fprintf('    max |I_floating|    = %.2e A\n', V_base.max_I_floating);
if V_base.max_I_floating > P.tol_current_conservation
    warning('Toleransi current conservation terlampaui.');
end

%% (3) Mesh refinement
fprintf('\n[3] Mesh refinement study\n');
mesh_levels = 0:P.mesh_refine_levels;
nElems  = zeros(size(mesh_levels));
err_rel = zeros(size(mesh_levels));
R_prev = [];

for i = 1:numel(mesh_levels)
    lv = mesh_levels(i);
    fm_lv = cceit_build_model(P, lv);
    R_lv  = cceit_receiver_scan(P, fm_lv, freq);
    nElems(i) = size(fm_lv.elems, 1);
    V_lv = cceit_verify(P, R_lv);

    if ~isempty(R_prev)
        err_rel(i) = norm(R_lv.I_rx - R_prev.I_rx) / norm(R_lv.I_rx);
    end
    R_prev = R_lv;

    fprintf('    Level %d: %5d elems | max|I_float| = %.2e A | rel-chg = %.2e\n', ...
        lv, nElems(i), V_lv.max_I_floating, err_rel(i));
end

%% (4) Reference: explicit dielectric layer
fprintf('\n[4] Reference model (explicit dielectric layer)\n');
HAVE_REF = false;
try
    [fmdl_ref, ring] = cceit_reference_layer(P);
    omega = 2*pi*freq;
    Ybg  = P.sigma_bg + 1i*omega*P.eps0*P.epsr_bg;
    Yins = P.sig_ins  + 1i*omega*P.eps0*P.er_ins;

    Y_ref = Ybg * ones(size(fmdl_ref.elems,1), 1);
    Y_ref(ring) = Yins;

    % Contact metal-elektroda kecil (bukan interface)
    for e = 1:P.nElec
        fmdl_ref.electrode(e).z_contact = 1e-4;
    end

    R_ref = cceit_receiver_scan(P, fmdl_ref, freq, Y_ref);
    rel_err_ref = norm(R_base.I_rx - R_ref.I_rx) / norm(R_ref.I_rx);

    fprintf('    Elemen: %d (%d di ring insulator)\n', numel(Y_ref), sum(ring));
    fprintf('    Relative error (CEM vs explicit): %.2e\n', rel_err_ref);
    HAVE_REF = true;
catch ME
    fprintf('    Reference dilewati: %s\n', ME.message);
end

%% (5) Plots + CSV export
fprintf('\n[5] Plots & export\n');
cceit_plot(P, fmdl, R_base, nElems, err_rel);

fid = fopen(fullfile(P.outdir,'cceit_receiver_current.csv'),'w');
fprintf(fid,'rx,Re_Irx,Im_Irx,abs_Irx,phase_deg\n');
for k = 1:numel(R_base.rx_list)
    fprintf(fid,'%d,%.12e,%.12e,%.12e,%.6f\n', ...
        R_base.rx_list(k), real(R_base.I_rx(k)), imag(R_base.I_rx(k)), ...
        abs(R_base.I_rx(k)), angle(R_base.I_rx(k))*180/pi);
end
fclose(fid);

fprintf('\nSelesai. Hasil di: %s\n', P.outdir);
