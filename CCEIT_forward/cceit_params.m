function P = cceit_params()
% Semua parameter di sini. Nilai ber-label PLACEHOLDER belum bersumber.

% Software
P.netgen_bin = 'C:\Netgen\bin';      % ubah sesuai komputer

% Geometri
P.nElec = 16;
P.R     = 0.09;      % radius jaringan [m]            PLACEHOLDER
P.w_el  = 0.026;     % lebar elektroda [m]            PLACEHOLDER
P.h_int = 0.003;     % ukuran elemen interior [m]
P.h_el  = 0.0015;    % ukuran elemen di elektroda [m]
P.width_mode = 'meters';   % 'meters' atau 'angle'

% Eksitasi
P.Vtx = 1;           % [V]
P.f   = 500e3;       % [Hz]                           PLACEHOLDER

% Jaringan (PLACEHOLDER, belum bersumber)
P.sigma = 0.20;      % [S/m]
P.epsr  = 78;

% Lapisan isolator
P.d       = 0.003;   % [m]
P.sigma_d = 1e-9;    % [S/m]
P.epsr_d  = 9;
P.z_el    = 0.01;    % kontak elektroda model B [Ohm.m^2]  PLACEHOLDER

P.eps0 = 8.8541878128e-12;
end
