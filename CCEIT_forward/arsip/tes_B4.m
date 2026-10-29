% tes_B4.m : konvergensi model B terhadap resolusi cincin (d = 2 mm)
eidors_cache clear
P0 = cceit_params();  P0.d = 0.002;
w = 2*pi*P0.f;
gam   = P0.sigma   + 1i*w*P0.eps0*P0.epsr;
gam_d = P0.sigma_d + 1i*w*P0.eps0*P0.epsr_d;

[fA, ~] = cceit_mesh_A(P0);
yA = cceit_runA_mesh(fA, P0, P0.f);

modes = {'tank','el'};
hrs   = [1.0 0.7 0.5 0.35]*1e-3;
R = struct();
for m = 1:numel(modes)
  yB = cell(numel(hrs),1);  ok = false(numel(hrs),1);
  for k = 1:numel(hrs)
    try
      tic;
      [fB, ring, iB] = cceit_mesh_B4(P0, modes{m}, hrs(k));
      gB = gam*ones(iB.nElems,1);  gB(ring) = gam_d;
      out = cceit_pairscan(fB, gB, P0);
      idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
      yB{k} = out.Y(idx);  ok(k) = true;
      fprintf('[%s] h_ring %.2f mm | %6d elem | rmax %.4f | elem/tebal ~ %.2f | node dalam %d | rasio luas %.3f | delta_layer %.4f | dcc %.2g | %.0f s\n', ...
        modes{m}, hrs(k)*1e3, iB.nElems, iB.rmax, iB.nAcross, iB.nInner, iB.areaRatio, ...
        norm(yA-yB{k})/norm(yB{k}), max(out.dcc), toc);
    catch err
      fprintf('[%s] h_ring %.2f mm GAGAL: %s\n', modes{m}, hrs(k)*1e3, err.message);
    end
  end
  last = find(ok,1,'last');
  for k = find(ok)'
    if k == last, continue; end
    fprintf('[%s] delta_mesh B: %.2f mm vs %.2f mm = %.3g\n', modes{m}, ...
            hrs(k)*1e3, hrs(last)*1e3, norm(yB{k}-yB{last})/norm(yB{last}));
  end
  R.(modes{m}).yB = yB;  R.(modes{m}).ok = ok;
  save('tes_B4_results.mat','R','yA','hrs','P0');
end
