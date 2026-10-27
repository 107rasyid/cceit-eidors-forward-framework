function [fmdl, ring, info] = cceit_mesh_B2(P)
setenv('PATH', [P.netgen_bin ';' getenv('PATH')]);
eidors_debug off call_netgen
Rb = P.R + P.d;
zt = 0.05 * P.R;                                  % tinggi irisan, skala domain
code = sprintf(['solid core = cylinder(0,0,0;0,0,1;%g) ' ...
                'and orthobrick(-1,-1,0;1,1,%g) -maxh=%g;'], P.R, zt, P.h_int);
extra = {'core', code};
fmdl = ng_mk_cyl_models([0, Rb, P.h_int], [P.nElec], [P.w_el, 0, P.h_el], extra);
nE = size(fmdl.elems,1);
xc = mean(reshape(fmdl.nodes(fmdl.elems(:),1), nE, 3), 2);
yc = mean(reshape(fmdl.nodes(fmdl.elems(:),2), nE, 3), 2);
ring = hypot(xc, yc) >= P.R;
for e = 1:P.nElec, fmdl.electrode(e).z_contact = P.z_el; end
n = fmdl.nodes(:,1:2); e = fmdl.elems;
A2 = abs((n(e(:,2),1)-n(e(:,1),1)).*(n(e(:,3),2)-n(e(:,1),2)) - ...
         (n(e(:,3),1)-n(e(:,1),1)).*(n(e(:,2),2)-n(e(:,1),2)))/2;
info.nElems = nE;  info.nRing = sum(ring);
info.areaRatio = sum(A2(ring)) / (pi*(Rb^2 - P.R^2));
end
