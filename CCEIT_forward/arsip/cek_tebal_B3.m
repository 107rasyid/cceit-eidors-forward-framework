% cek_tebal_B3.m  -- elemen sepanjang tebal cincin model B3
eidors_cache clear
P0 = cceit_params();  P0.d = 0.002;
his = [0.0025 0.002 0.0015 0.001];
fprintf('d = %.1f mm, R = %.1f mm\n', P0.d*1e3, P0.R*1e3);

for k = 1:numel(his)
  P = P0;  P.h_int = his(k);
  [f, ring, i] = cceit_mesh_B3(P);
  n = f.nodes(:,1:2);  e = f.elems;
  rn = hypot(n(:,1), n(:,2));

  % (a) rentang radial elemen cincin
  Re = rn(e(ring,:));
  span = max(Re,[],2) - min(Re,[],2);
  nAcross_a = P.d / mean(span);

  % (b) node yang benar-benar di dalam cincin (bukan di batas R atau R+d)
  tol = 1e-6;
  inner = rn > P.R + tol & rn < P.R + P.d - tol;
  nIn = sum(inner);

  % (c) jumlah lapisan node: kelompokkan r node cincin (termasuk batas), resolusi 0.05 mm
  rr = rn(rn >= P.R - tol & rn <= P.R + P.d + tol);
  layers = numel(unique(round(rr*1e5)));   % 0.01 mm bin

  fprintf(['h_int %.2f mm | elemen cincin %5d | rentang radial rata2 %.3f mm | ' ...
           'elemen/tebal ~ %.2f | node di dalam cincin %d | bin r unik %d\n'], ...
          his(k)*1e3, i.nRing, mean(span)*1e3, nAcross_a, nIn, layers);
end
