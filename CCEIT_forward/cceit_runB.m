function [y, info] = cceit_runB(P, freq_Hz, h_ring)
% CCEIT_RUNB  Run the explicit-layer Model B on a B4 tank-refined mesh.
%
% Implements: Section IV.B, explicit dielectric-layer reference comparison.
%
% Inputs:
%   P       parameter struct from cceit_params
%   freq_Hz excitation frequency [Hz]
%   h_ring  target ring mesh size [m], defaults to P.h_ring_B
%
% Outputs:
%   y       120 pair admittances in cceit_pairscan pair order [S/m]
%   info    mesh metadata and normalized current/voltage checks

if nargin < 3 || isempty(h_ring)
    h_ring = P.h_ring_B;
end
if ~isscalar(h_ring) || ~isfinite(h_ring) || h_ring <= 0
    error('cceit_runB: h_ring must be a positive finite scalar in meters');
end

omega = 2*pi*freq_Hz;
gamma = P.sigma + 1i*omega*P.eps0*P.epsr;
gamma_layer = P.sigma_d + 1i*omega*P.eps0*P.epsr_d;

% A separate ring target preserves P.h_int as the core mesh setting.
[fmdl_B, ring, info] = cceit_mesh_B4(P, 'tank', h_ring);
gamma_elem = gamma * ones(info.nElems, 1);
gamma_elem(ring) = gamma_layer;

out = cceit_pairscan(fmdl_B, gamma_elem, P);
pair_idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
y = out.Y(pair_idx);
info.h_ring = h_ring;
info.dcc = max(out.dcc);
info.dfloat = max(out.dfloat);
info.dU = max(out.dU);
end
