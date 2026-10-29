% tes_zel.m : sensitivitas delta_layer terhadap z_el (d = 2 mm, h_ring = 1.0 mm)
eidors_cache clear
P0 = cceit_params();  P0.d = 0.002;
w = 2*pi*P0.f;
gam   = P0.sigma   + 1i*w*P0.eps0*P0.epsr;
gam_d = P0.sigma_d + 1i*w*P0.eps0*P0.epsr_d;

[fA, ~] = cceit_mesh_A(P0);
yA = cceit_runA_mesh(fA, P0, P0.f);

zels = [0.001 0.01 0.1];
dz = zeros(size(zels));  yBz = cell(size(zels));
for k = 1:numel(zels)
  Q = P0;  Q.z_el = zels(k);
  [fB, ring, iB] = cceit_mesh_B4(Q, 'tank', 1.0e-3);
  gB = gam*ones(iB.nElems,1);  gB(ring) = gam_d;
  out = cceit_pairscan(fB, gB, Q);
  idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
  yBz{k} = out.Y(idx);
  dz(k) = norm(yA - yBz{k}) / norm(yBz{k});
  fprintf('z_el = %.3g Ohm.m | delta_layer = %.4f | %d elemen\n', zels(k), dz(k), iB.nElems);
  save('tes_zel_results.mat','zels','dz','yA','yBz','P0');
end
