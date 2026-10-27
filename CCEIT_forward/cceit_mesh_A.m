function [fmdl, info] = cceit_mesh_A(P)
% Model A: radius R, 16 elektroda CEM, lapisan diwakili z_contact.
setenv('PATH', [P.netgen_bin ';' getenv('PATH')]);
eidors_debug off call_netgen

% CHECK: argumen ng_mk_cyl_models dicopy dari cceit_sim3 (h=tinggi 2D)
fmdl = ng_mk_cyl_models([0, P.R, P.h_int], [P.nElec], [P.w_el, 0, P.h_el]);
fmdl.nodes = fmdl.nodes * (P.R / max(hypot(fmdl.nodes(:,1), fmdl.nodes(:,2))));
if size(fmdl.elems,2) ~= 3, error('Harus mesh 2D (segitiga).'); end

info.nNodes = size(fmdl.nodes,1);
info.nElems = size(fmdl.elems,1);
info.rmax   = max(hypot(fmdl.nodes(:,1), fmdl.nodes(:,2)));
end
