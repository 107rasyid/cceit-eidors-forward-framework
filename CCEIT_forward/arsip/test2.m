eidors_cache clear
P0 = cceit_params();  P0.d = 0.002;
w = 2*pi*P0.f;
gam   = P0.sigma   + 1i*w*P0.eps0*P0.epsr;
gam_d = P0.sigma_d + 1i*w*P0.eps0*P0.epsr_d;

% Model A, sekali, h_int 2.5 mm
yA = cceit_runA_mesh(cceit_mesh_A(P0), P0, P0.f);   % (fA dibuat di dalam)

his = [0.0025 0.002 0.0015 0.001];
yB = cell(numel(his),1);
for k = 1:numel(his)
  P = P0;  P.h_int = his(k);
  [fB, ring, iB] = cceit_mesh_B3(P);
  gB = gam*ones(iB.nElems,1);  gB(ring) = gam_d;
  out = cceit_pairscan(fB, gB, P);
  idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
  yB{k} = out.Y(idx);
  fprintf('B h_int %.2f mm | %d elemen | delta_layer = %.4f | max dcc = %.2g\n', ...
          his(k)*1e3, iB.nElems, norm(yA-yB{k})/norm(yB{k}), max(out.dcc));
end
for k = 1:numel(his)-1
  fprintf('delta_mesh B: %.2f mm vs %.2f mm = %.3g\n', his(k)*1e3, his(end)*1e3, ...
          norm(yB{k}-yB{end})/norm(yB{end}));
end
save('layer_conv.mat','his','yA','yB');
