function P = cceit_params()
% Baseline berbasis literatur (ASUMSI MODEL, bukan jaringan biologis).
% Semua nilai harus dicek ke paper sumbernya sebelum masuk Tabel I.

% Software
P.netgen_bin = 'C:\Netgen\bin';      % ubah sesuai komputer

% Geometri
P.nElec = 16;
P.R     = 0.053;     % radius phantom [m]             (acuan: Jia20, perlu dicek)
P.w_el  = 0.018;     % lebar elektroda [m]            (turunan/adaptasi, bukan nilai paper)
P.width_mode = 'meters';
P.depth = 1;         % kedalaman ekstrusi 2D [m]
P.h_int = 0.0025;
P.h_el  = 0.001;
P.h_ring = P.h_int;  % hanya dipakai B2

% Eksitasi
P.Vtx = 1;           % [V]
P.f   = 500e3;       % [Hz]

% Medium (skenario phantom air; satu skenario saja)
P.sigma = 0.025;     % [S/m]
P.epsr  = 80;

% Lapisan isolator (asumsi model)
P.d       = 0.002;   % [m]
P.sigma_d = 0;       % [S/m]
P.epsr_d  = 3;
P.z_el    = 0.01;    % kontak elektroda model B [Ohm.m]   ASUMSI, harus diuji variasinya

P.eps0 = 8.8541878128e-12;
end
