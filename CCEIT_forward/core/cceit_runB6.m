function [y, info] = cceit_runB6(P, freq_Hz, h_ring)
% CCEIT_RUNB6 Solve the refined explicit-layer Model B6.
% Purpose: compare contact-impedance Model A3 against refined B6 with finer medium.
% Inputs: P, model parameters; freq_Hz; optional h_ring in metres.
% Outputs: 120 pair admittances and mesh/current diagnostics.
% Manuscript ref: Section IV.B, explicit-layer comparison with refined mesh.

if nargin < 3 || isempty(h_ring), h_ring = P.h_ring_B6_coarse; end
omega = 2*pi*freq_Hz;
gamma = P.sigma + 1i*omega*P.eps0*P.epsr;
gamma_layer = P.sigma_d + 1i*omega*P.eps0*P.epsr_d;
[fmdl, ring, info] = cceit_mesh_B6(P, h_ring);
gamma_elem = gamma*ones(info.nElems,1);
gamma_elem(ring) = gamma_layer;
out = cceit_pairscan(fmdl, gamma_elem, P);
idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
y = out.Y(idx);
info.dcc = max(out.dcc);
info.dfloat = max(out.dfloat);
info.dU = max(out.dU);
end
