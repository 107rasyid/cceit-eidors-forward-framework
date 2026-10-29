function [fmdl, ring, info] = cceit_mesh_B3(P)
% Model B konformal. Mesh dibangun dalam mm (menghindari pembulatan radius), lalu dikonversi ke m.
setenv('PATH', [P.netgen_bin ';' getenv('PATH')]);
eidors_debug off call_netgen
mm = 1e3;
Rc = P.R*mm;  Rb = (P.R + P.d)*mm;
zt = 0.05*Rc;                                     % tinggi irisan (mm)
code = sprintf(['solid core = cylinder(0,0,0;0,0,1;%g) ' ...
                'and orthobrick(-1000,-1000,0;1000,1000,%g) -maxh=%g;'], ...
                Rc, zt, P.h_int*mm);
extra = {'core', code};                           % CHECK: sintaks dari contoh bantuan
fmdl = ng_mk_cyl_models([0, Rb, P.h_int*mm], [P.nElec], ...
                        [P.w_el*mm, 0, P.h_el*mm], extra);
fmdl.nodes = fmdl.nodes / mm;                     % kembali ke meter
if size(fmdl.elems,2) ~= 3, error('Harus mesh 2D (segitiga).'); end

n = fmdl.nodes(:,1:2);  e = fmdl.elems;  nE = size(e,1);
xc = mean(reshape(n(e(:),1), nE, 3), 2);
yc = mean(reshape(n(e(:),2), nE, 3), 2);
ring = hypot(xc, yc) >= P.R;
for k = 1:P.nElec, fmdl.electrode(k).z_contact = P.z_el; end

rn = hypot(n(:,1), n(:,2));
A2 = abs((n(e(:,2),1)-n(e(:,1),1)).*(n(e(:,3),2)-n(e(:,1),2)) - ...
         (n(e(:,3),1)-n(e(:,1),1)).*(n(e(:,2),2)-n(e(:,1),2)))/2;
info.nElems = nE;  info.nNodes = size(n,1);  info.nRing = sum(ring);
info.rmax = max(rn);
info.nNodesAtR = sum(abs(rn - P.R) < 1e-6);
info.areaRatio = sum(A2(ring)) / (pi*((P.R+P.d)^2 - P.R^2));
end
