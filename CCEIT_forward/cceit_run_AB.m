function res = cceit_run_AB(P)
w = 2*pi*P.f;
gam   = P.sigma   + 1i*w*P.eps0*P.epsr;
gam_d = P.sigma_d + 1i*w*P.eps0*P.epsr_d;

[fA, iA] = cceit_mesh_A(P);
zc = 1 / (P.sigma_d/P.d + 1i*w*P.eps0*P.epsr_d/P.d);   % tanpa kappa
for e = 1:P.nElec, fA.electrode(e).z_contact = zc; end
outA = cceit_pairscan(fA, gam*ones(size(fA.elems,1),1), P);

[fB, ring, iB] = cceit_mesh_B(P);
gB = gam*ones(iB.nElems,1);  gB(ring) = gam_d;
outB = cceit_pairscan(fB, gB, P);

idx = sub2ind(size(outA.Y), outA.pairs(:,1), outA.pairs(:,2));
res.yA = outA.Y(idx);  res.yB = outB.Y(idx);
res.delta_layer = norm(res.yA - res.yB) / norm(res.yB);
res.ratio = median(abs(res.yA)./abs(res.yB));
res.iA = iA;  res.iB = iB;
res.maxchecks = [max(outA.dcc) max(outB.dcc) max(outA.dfloat) max(outB.dfloat)];
end
