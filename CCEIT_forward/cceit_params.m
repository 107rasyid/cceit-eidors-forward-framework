function P = cceit_params()
% CCEIT_PARAMS  Semua parameter di satu tempat.
% Ubah hanya di sini — jangan hardcode di file lain.

% --- Geometri ---
P.nElec                  = 16;
P.radius_m               = 0.09;       % radius tangki [m]
P.insulator_thickness_m  = 0.003;      % 3 mm layer

% --- Eksitasi ---
P.Vtx = 1.0;                           % tegangan transmitter [V]
P.tx  = 1;                             % indeks elektroda transmitter

% --- Frekuensi ---
P.freq_Hz = [100e3, 500e3, 1e6];       % Hz

% --- Material background ---
P.sigma_bg = 0.20;                     % S/m
P.epsr_bg  = 78;                       % relative permittivity
P.eps0     = 8.8541878128e-12;         % F/m

% --- Interface kapasitif (persamaan 2 manuscript) ---
% z_l(w) = 1 / (G_l + j*w*C_l)
P.sig_ins = 1e-9;                      % S/m
P.er_ins  = 9;
% Estimasi first-principles: C_eff = eps0 * er_ins / t_ins
% (untuk 2D CEM ini setara impedansi lapisan tipis)
P.Ceff_F_per_m     = P.eps0 * P.er_ins / P.insulator_thickness_m;
P.Gcontact_S_per_m = 0;                % 0 = kapasitor ideal

% --- Verifikasi ---
P.tol_current_conservation = 1e-10;    % A
P.mesh_refine_levels       = 2;        % 0 = coarse, 2 = ~16x elemen

% --- Output ---
P.outdir = fullfile(pwd, 'hasil_cceit');
if ~exist(P.outdir, 'dir'), mkdir(P.outdir); end
end
