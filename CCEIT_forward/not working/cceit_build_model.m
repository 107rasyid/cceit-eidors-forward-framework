function fmdl = cceit_build_model(P, ref_level)
% CCEIT_BUILD_MODEL  Model 2D circular 16-elektroda (CEM) di EIDORS.
%
%   ref_level = 0..4 selects c2C through g2C respectively.
%
% Catatan: boundary condition (voltage-driven) TIDAK diset di sini.
% Itu tugas cceit_receiver_scan.

if nargin < 2, ref_level = 0; end

% Model EIDORS standar: c2C = circular 2D, CEM electrodes.
% (Manuscript menyebut 'c2C'. Kalau versi EIDORS Anda tidak punya,
%  ganti ke 'c2C2' — API-nya sama.)
% EIDORS does not provide refine_mesh in this release. Its common-model
% c/d/e variants provide nested mesh-density levels for the convergence study.
model_codes = 'cdefg';
if ref_level < 0 || ref_level >= numel(model_codes) || ref_level ~= floor(ref_level)
    error('cceit_build_model: ref_level must be an integer from 0 to %d', numel(model_codes)-1);
end
model_name = [model_codes(ref_level + 1), '2C'];
imdl = mk_common_model(model_name, P.nElec);
fmdl = imdl.fwd_model;

% Skala unit circle ke radius fisik
fmdl.nodes = P.radius_m * fmdl.nodes;

% Jangan normalisasi (kita butuh nilai absolut)
fmdl.normalize_measurements = 0;

% Placeholder z_contact — nilai sebenarnya diset per frekuensi
% di cceit_receiver_scan.
for e = 1:P.nElec
    fmdl.electrode(e).z_contact = 1 / (1i*2*pi*P.freq_Hz(1)*P.Ceff_F_per_m);
end
end
