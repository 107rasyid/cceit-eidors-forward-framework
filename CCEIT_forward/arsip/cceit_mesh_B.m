function [fmdl, ring, info] = cceit_mesh_B(P)
setenv('PATH', [P.netgen_bin ';' getenv('PATH')]);
eidors_debug off call_netgen
Rb = P.R + P.d;
wB = P.w_el;
if isfield(P,'width_mode') && strcmp(P.width_mode,'angle')
  wB = P.w_el * Rb / P.R;
end
fmdl = ng_mk_cyl_models([0, Rb, P.h_int], [P.nElec], [wB, 0, P.h_el]);
fmdl.nodes = fmdl.nodes * (Rb / max(hypot(fmdl.nodes(:,1), fmdl.nodes(:,2))));
if size(fmdl.elems,2) ~= 3, error('Harus mesh 2D (segitiga).'); end
nE = size(fmdl.elems,1);
xc = mean(reshape(fmdl.nodes(fmdl.elems(:),1), nE, 3), 2);
yc = mean(reshape(fmdl.nodes(fmdl.elems(:),2), nE, 3), 2);
ring = hypot(xc, yc) >= P.R;
for e = 1:P.nElec, fmdl.electrode(e).z_contact = P.z_el; end
rn = hypot(fmdl.nodes(:,1), fmdl.nodes(:,2));
Vr = fmdl.elems(ring,:);
span = max(rn(Vr),[],2) - min(rn(Vr),[],2);
info.nNodes = size(fmdl.nodes,1);
info.nElems = nE;
info.nRing  = sum(ring);
info.wB     = wB;
info.nInteriorRingNodes = sum(rn > P.R + 1e-6 & rn < Rb - 1e-6);
info.meanSpan = mean(span);
info.nAcross  = P.d / info.meanSpan;
end
