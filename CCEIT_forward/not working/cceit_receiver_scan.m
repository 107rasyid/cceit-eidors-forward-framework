function R = cceit_receiver_scan(P, fmdl, freq_Hz, Y_elem, z_contact_override)
% CCEIT_RECEIVER_SCAN  Voltage-driven, single-transmitter, receiver scan.
%
%   Untuk tiap rx != tx:
%       U_tx = Vtx    (prescribed voltage)
%       U_rx = 0      (virtual ground / TIA)
%       lainnya floating (current = 0)
%
%   Input opsional Y_elem = admittivity per elemen [nElem x 1].
%   Input opsional z_contact_override mempertahankan interface reference layer.
%   Default: background homogen.
%
%   Output R:
%       .rx_list   vektor indeks receiver (semua kecuali tx)
%       .I_rx      arus di rx   [nRx x 1, complex, A]
%       .V_elec    tegangan terminal tiap elektroda  [nElec x nRx]
%       .I_elec    arus tiap elektroda               [nElec x nRx]
%       .V_nodes   tegangan node FEM (untuk plot)    [nNode x nRx]
%       .zc        contact impedance yang dipakai    [nElec x 1]

if nargin < 4 || isempty(Y_elem)
    omega = 2*pi*freq_Hz;
    Y_elem = (P.sigma_bg + 1i*omega*P.eps0*P.epsr_bg) * ones(size(fmdl.elems,1),1);
end

% --- Set z_contact kompleks untuk frekuensi ini ---
omega = 2*pi*freq_Hz;
if nargin >= 5 && ~isempty(z_contact_override)
    if isscalar(z_contact_override)
        zc = z_contact_override * ones(P.nElec, 1);
    elseif numel(z_contact_override) == P.nElec
        zc = z_contact_override(:);
    else
        error('cceit_receiver_scan: z_contact_override must be scalar or nElec values');
    end
else
    zc = 1 ./ (P.Gcontact_S_per_m + 1i * omega * P.Ceff_F_per_m) * ones(P.nElec,1);
end
for e = 1:P.nElec
    fmdl.electrode(e).z_contact = zc(e);
end

% --- Image dengan elem_data ---
img = mk_image(fmdl, 1);
img.elem_data = Y_elem;
img.fwd_solve.get_all_meas  = 1;   % node voltages
img.fwd_solve.get_elec_curr = 1;   % electrode currents

% --- Loop receiver ---
rx_list = setdiff(1:P.nElec, P.tx);
nRx  = numel(rx_list);
nEl  = P.nElec;
nNd  = size(fmdl.nodes, 1);

R = struct();
R.rx_list = rx_list;
R.I_rx    = zeros(nRx, 1);
R.V_elec  = zeros(nEl, nRx);
R.I_elec  = zeros(nEl, nRx);
R.V_nodes = zeros(nNd, nRx);
R.zc      = zc;

for k = 1:nRx
    rx = rx_list(k);  % Current receiver corresponding to output column k.
    if isfield(fmdl, 'stimulation') && ~isempty(fmdl.stimulation)
        stim = fmdl.stimulation(1);
    else
        % Netgen geometry models may omit the stimulation protocol entirely.
        stim = struct('stim_pattern', zeros(nEl, 1), ...
                      'volt_pattern', zeros(nEl, 1), ...
                      'meas_pattern', eye(nEl));
    end
    stim.stim_pattern = zeros(nEl, 1);
    stim.stim_pattern([P.tx, rx]) = NaN;  % Prescribed-voltage terminals.
    stim.volt_pattern = zeros(nEl, 1);
    stim.volt_pattern(P.tx) = P.Vtx;
    stim.volt_pattern(rx) = 0;
    fmdl.stimulation = stim;
    img.fwd_model = fmdl;
    data = fwd_solve(img);

    % ===== EKSTRAKSI ROBUST (Octave + EIDORS) =====
    nNodes_l = size(fmdl.nodes, 1);
    nElec_l  = P.nElec;

    % --- I_elec: data.elec_curr bisa 16x16 atau 16x1 ---
    if isempty(data.elec_curr)
        error('cceit_receiver_scan: data.elec_curr kosong. Cek get_elec_curr di versi EIDORS.');
    end
    I_all = data.elec_curr(:, 1);    % kolom 1 = satu-satunya stimulasi
    if numel(I_all) ~= nElec_l
        % Kalau ternyata per contact node, agregasi
        I_all2 = zeros(nElec_l, 1);
        for e = 1:nElec_l
            cn = fmdl.electrode(e).nodes;
            if ~isempty(cn) && max(cn) <= numel(I_all)
                I_all2(e) = sum(I_all(cn));
            end
        end
        I_all = I_all2;
    end
    R.I_elec(:, k) = I_all;
    R.I_rx(k)      = I_all(rx);

    % --- V_elec: data.meas bisa per-elektroda (16) atau per-contact-node (208) ---
    if size(data.meas, 1) == nElec_l
        R.V_elec(:, k) = data.meas(:, 1);
    else
        % Agregasi per contact node -> per elektroda (rata-rata)
        V_all = zeros(nElec_l, 1);
        for e = 1:nElec_l
            cn = fmdl.electrode(e).nodes;
            if ~isempty(cn) && max(cn) <= size(data.meas, 1)
                V_all(e) = mean(data.meas(cn, 1));
            else
                V_all(e) = NaN;
            end
        end
        R.V_elec(:, k) = V_all;
    end

    % --- V_nodes: ambil kolom 1 (satu-satunya solve) ---
    R.V_nodes(:, k) = data.volt(1:nNodes_l, 1);
end

% Sanity check
if any(~isfinite(R.I_rx))
    warning('Receiver scan menghasilkan I_rx non-finite. Cek EIDORS/versi c2C.');
end
end
