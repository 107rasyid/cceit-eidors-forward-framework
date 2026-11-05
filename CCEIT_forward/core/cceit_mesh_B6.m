function [fmdl, ring, info] = cceit_mesh_B6(P, h_ring)
% CCEIT_MESH_B6 Build an explicit dielectric shell with refined medium and ring.
% Purpose: refine both tissue mesh and dielectric ring for better accuracy.
% Inputs: P, shared model parameters; h_ring, target ring size in metres.
% Outputs: EIDORS model, ring element indices, and mesh diagnostics.
% Manuscript ref: Section II.C, explicit-layer comparison mesh with refinement.

if nargin < 2 || isempty(h_ring), h_ring = P.h_ring_B6_coarse; end
if ~isscalar(h_ring) || ~isfinite(h_ring) || h_ring <= 0
    error('cceit_mesh_B6: h_ring must be a positive finite scalar in metres');
end

setenv('PATH', [P.netgen_bin ';' getenv('PATH')]);
eidors_debug off call_netgen

% Netgen geometry is expressed in millimetres here, so its 0.001-unit
% coordinate precision is one micrometre. Give the core and shell separate
% local maximum element sizes; the outer tank background is excluded.
mm = 1e3;
Rc = P.R*mm;
Rb = (P.R + P.d)*mm;
zt = 0.05*Rc;
hc = P.h_int_B6*mm;
hr = h_ring*mm;
elmax = min(P.h_el*mm, hr);

core_code = sprintf(['solid core = cylinder(0,0,0;0,0,1;%g) ' ...
    'and orthobrick(-1000,-1000,0;1000,1000,%g) -maxh=%g;'], Rc, zt, hc);
ring_code = sprintf(['solid ring = (cylinder(0,0,0;0,0,1;%g) ' ...
    'and not cylinder(0,0,0;0,0,1;%g)) ' ...
    'and orthobrick(-1000,-1000,0;1000,1000,%g) -maxh=%g;'], ...
    Rb, Rc, zt, hr);
% Keep only the core as a separate EIDORS material region. The shell sizing
% solid is a local Netgen size constraint, not an extra volume: adding it to
% the extra-region name list removes the entire outer tank from bigcyl and
% leaves the generated CEM electrodes with no boundary edges.
extra = {'core', [core_code ' ' ring_code]};

fmdl = ng_mk_cyl_models([0, Rb, hc], [P.nElec], ...
    [P.w_el*mm, 0, elmax], extra);
fmdl.nodes = fmdl.nodes/mm;
if size(fmdl.elems,2) ~= 3
    error('cceit_mesh_B6: Netgen must return a triangular 2D mesh');
end

n = fmdl.nodes(:,1:2);
e = fmdl.elems;
nE = size(e,1);
centroid_x = mean(reshape(n(e(:),1), nE, 3), 2);
centroid_y = mean(reshape(n(e(:),2), nE, 3), 2);
ring = hypot(centroid_x, centroid_y) >= P.R;
for k = 1:P.nElec, fmdl.electrode(k).z_contact = P.z_el; end

info.nElems = nE;
info.nNodes = size(n,1);
info.nRing = sum(ring);
info.nMedium = nE-info.nRing;
info.h_ring = h_ring;
info.h_medium = P.h_int_B6;
info.rmax = max(hypot(n(:,1), n(:,2)));
info.nAcross = P.d/mean(max(hypot(n(e(ring,:),1), n(e(ring,:),2)),[],2) - ...
    min(hypot(n(e(ring,:),1), n(e(ring,:),2)),[],2));
end
