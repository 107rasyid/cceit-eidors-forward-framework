function [fmdl_ref, ring] = cceit_reference_layer(P)
% CCEIT_REFERENCE_LAYER  Mesh dengan layer dielektrik eksplisit.
%
% Dipakai sebagai referensi independen untuk memvalidasi pendekatan
% CEM dengan z_contact efektif.

% NGNetgen path — EDIT sesuai mesin Anda
setenv('PATH', ['C:\Netgen\bin;' getenv('PATH')]);
eidors_debug off call_netgen

R_tank = P.radius_m;
t_ins  = P.insulator_thickness_m;
R_mesh = R_tank + t_ins;

fm = ng_mk_cyl_models([0, R_mesh, 0.003], ...
                      [P.nElec], ...
                      [0.026, 0, 0.0015]);
fm.nodes = fm.nodes * (R_mesh / max(hypot(fm.nodes(:,1), fm.nodes(:,2))));

nodes = fm.nodes(:,1:2);
elems = fm.elems;
nE = size(elems,1);
xc = mean(reshape(nodes(elems(:),1), nE, 3), 2);
yc = mean(reshape(nodes(elems(:),2), nE, 3), 2);
ring = hypot(xc, yc) >= R_tank;

fmdl_ref = fm;
fmdl_ref.normalize_measurements = 0;
end
