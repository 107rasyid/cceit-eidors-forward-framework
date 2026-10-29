% tes_B5.m : (1) delta_layer vs d dengan B terkonvergen, (2) per jarak elektroda, (3) sensitivitas z_el
eidors_cache clear
P0 = cceit_params();
mm = 1e-3;

%% (1) delta_layer vs d. Tiap d dijalankan di dua h_ring (d/3 dan d/4) untuk melihat konvergensi
dlist = [2 3 5]*mm;
[fA, ~] = cceit_mesh_A(P0);
res = struct('d',{},'h',{},'delta',{},'nacross',{},'nel',{},'t',{},'yA',{},'yB',{});
k = 0;
for a = 1:numel(dlist)
  P = P0;  P.d = dlist(a);
  w = 2*pi*P.f;
  gam   = P.sigma   + 1i*w*P.eps0*P.epsr;
  gam_d = P.sigma_d + 1i*w*P.eps0*P.epsr_d;
  yA = cceit_runA_mesh(fA, P, P.f);
  for h = [P.d/3, P.d/4]
    try
      tic;
      [fB, ring, iB] = cceit_mesh_B4(P, 'tank', h);
      gB = gam*ones(iB.nElems,1);  gB(ring) = gam_d;
      out = cceit_pairscan(fB, gB, P);
      idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
      yB = out.Y(idx);
      k = k+1;
      res(k).d = P.d; res(k).h = h; res(k).delta = norm(yA-yB)/norm(yB);
      res(k).nacross = iB.nAcross; res(k).nel = iB.nElems; res(k).t = toc;
      res(k).yA = yA; res(k).yB = yB;
      fprintf('d=%.0f mm | h_ring %.2f mm | %6d elem | elem/tebal ~ %.1f | delta_layer %.4f | rasio %.3f | %.0f s\n', ...
        P.d*1e3, h*1e3, iB.nElems, iB.nAcross, res(k).delta, median(abs(yA)./abs(yB)), toc);
      save('tes_B5_results.mat','res','P0');
    catch err
      fprintf('d=%.0f mm | h_ring %.2f mm GAGAL: %s\n', P.d*1e3, h*1e3, err.message);
    end
  end
end

%% (2) Per jarak elektroda (hasil terhalus d = 2 mm)
j = find([res.d] == 2*mm, 1, 'last');
if ~isempty(j)
  pairs = [];
  for t = 1:15, for q = t+1:16, pairs(end+1,:) = [t q]; end, end
  c = pairs(:,2)-pairs(:,1);  sep = min(c, 16-c);
  fprintf('\nPer jarak (d = 2 mm, h_ring %.2f mm):\n', res(j).h*1e3);
  for s = 1:8
    m = (sep == s);
    fprintf('jarak %d | median|yA|/|yB| = %.4f | galat relatif = %.4f | selisih fase = %.3f deg\n', s, ...
      median(abs(res(j).yA(m))./abs(res(j).yB(m))), ...
      norm(res(j).yA(m)-res(j).yB(m))/norm(res(j).yB(m)), ...
      median(angle(res(j).yA(m)./res(j).yB(m)))*180/pi);
  end
end

%% (3) Sensitivitas z_el (d = 2 mm, h_ring 1.0 mm, mesh murah)
P = P0;  P.d = 2*mm;  w = 2*pi*P.f;
gam   = P.sigma   + 1i*w*P.eps0*P.epsr;
gam_d = P.sigma_d + 1i*w*P.eps0*P.epsr_d;
yA = cceit_runA_mesh(fA, P, P.f);
fprintf('\nSensitivitas z_el (h_ring 1.0 mm):\n');
for ze = [0.001 0.01 0.1]
  Q = P;  Q.z_el = ze;
  [fB, ring, iB] = cceit_mesh_B4(Q, 'tank', 1.0*mm);
  gB = gam*ones(iB.nElems,1);  gB(ring) = gam_d;
  out = cceit_pairscan(fB, gB, Q);
  idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
  fprintf('z_el = %.3g Ohm.m | delta_layer = %.4f\n', ze, norm(yA-out.Y(idx))/norm(out.Y(idx)));
end
