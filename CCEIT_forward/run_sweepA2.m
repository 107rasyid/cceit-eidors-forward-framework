% run_sweepA2.m  (baseline literatur)
% Sweep lapisan dan jaringan, model A, mesh dibuat sekali.
% Ukuran: Delta_p = ||y(p)-y(p0)|| / ||y(p0)||  (relative measurement change)
clear; close all; clc;
% run('C:\Users\user\Documents\GitHub\eidors-v3.12\eidors\startup.m');

P0 = cceit_params();
eidors_cache clear
[fA, iA] = cceit_mesh_A(P0);
fprintf('Mesh A: %d elemen | baseline: f=%.0f kHz, d=%.1f mm, epsr_d=%g, sigma_d=%g, sigma=%g, epsr=%g\n', ...
        iA.nElems, P0.f/1e3, P0.d*1e3, P0.epsr_d, P0.sigma_d, P0.sigma, P0.epsr);

y0 = cceit_runA_mesh(fA, P0, P0.f);

% {nama field, daftar nilai, faktor tampilan, label}
sw = { 'd',       [1 2 3 4.5 6 9]*1e-3,         1e3, 'd (mm)';
       'epsr_d',  [1 3 6 9],                    1,   'epsr_d';
       'sigma_d', [0 1e-9 1e-7 1e-5 1e-4],      1,   'sigma_d (S/m)';
       'sigma',   [0.0125 0.025 0.05 0.1],      1,   'sigma tissue (S/m)';
       'epsr',    [40 80 150],                  1,   'epsr tissue' };

res = struct('name',{},'vals',{},'delta',{},'medabs',{},'medphase',{});
for s = 1:size(sw,1)
  nm = sw{s,1};  vals = sw{s,2};
  dl = zeros(size(vals));  ma = dl;  mp = dl;
  fprintf('\n--- %s ---\n', sw{s,4});
  for j = 1:numel(vals)
    P = P0;  P.(nm) = vals(j);
    y = cceit_runA_mesh(fA, P, P0.f);
    dl(j) = norm(y - y0)/norm(y0);
    ma(j) = median(abs(y));
    mp(j) = median(angle(y))*180/pi;
    fprintf('%-10s = %-10.4g | Delta_p = %-10.4g | median|y| = %.4e | fase = %6.2f deg\n', ...
            nm, vals(j)*sw{s,3}, dl(j), ma(j), mp(j));
  end
  res(s).name = nm;  res(s).vals = vals;  res(s).delta = dl;
  res(s).medabs = ma;  res(s).medphase = mp;
  meta.version = version;  meta.date = datestr(now);
  save('sweepA2_results.mat','res','P0','iA','meta');      % simpan tiap blok
end

% Cek degenerasi model lumped: (2d, 2*epsr_d) harus identik dengan baseline
P = P0;  P.d = 2*P0.d;  P.epsr_d = 2*P0.epsr_d;
yd = cceit_runA_mesh(fA, P, P0.f);
res_degen = norm(yd - y0)/norm(y0);
fprintf('\nCek degenerasi (2d, 2*epsr_d): Delta_p = %.3g (harusnya ~0)\n', res_degen);

save('sweepA2_results.mat','res','res_degen','P0','iA','meta');
fprintf('Selesai. Hasil di sweepA2_results.mat\n');
