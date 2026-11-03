function [y, info] = cceit_runB5(P, freq_Hz, h_ring)
% CCEIT_RUNB5 Solve the locally refined explicit-layer Model B.
% Purpose: compare contact-impedance Model A against an explicit ring while
% holding the tissue mesh target at P.h_int.
% Inputs: P, model parameters; freq_Hz; optional h_ring in metres.
% Outputs: 120 pair admittances and mesh/current diagnostics.
% Manuscript ref: Section IV.B, explicit-layer comparison.

if nargin < 3 || isempty(h_ring), h_ring = P.h_ring_B_coarse; end
omega = 2*pi*freq_Hz;
gamma = P.sigma + 1i*omega*P.eps0*P.epsr;
gamma_layer = P.sigma_d + 1i*omega*P.eps0*P.epsr_d;
[fmdl, ring, info] = cceit_mesh_B5(P, h_ring);
gamma_elem = gamma*ones(info.nElems,1);
gamma_elem(ring) = gamma_layer;
out = cceit_pairscan(fmdl, gamma_elem, P);
idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
y = out.Y(idx);
info.dcc = max(out.dcc);
info.dfloat = max(out.dfloat);
info.dU = max(out.dU);
end
