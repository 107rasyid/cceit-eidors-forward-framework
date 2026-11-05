% run_sweepA2.m  (baseline literatur)
% Sweep lapisan dan jaringan, model A3, mesh dibuat sekali.
% Ukuran: Delta_p = ||y(p)-y(p0)|| / ||y(p0)||  (relative measurement change)
% Median magnitude dan fase disimpan sebagai deskripsi tambahan.
clear; close all; clc;
P0 = cceit_params();
eidors_cache clear
[fA, iA] = cceit_mesh_A3(P0);
fprintf('Mesh A3: %d elemen | baseline: f=%.0f kHz, d=%.1f mm, epsr_d=%g, sigma_d=%g, sigma=%g, epsr=%g\n', ...
        iA.nElems, P0.f/1e3, P0.d*1e3, P0.epsr_d, P0.sigma_d, P0.sigma, P0.epsr);

y0 = cceit_runA3_mesh(fA, P0, P0.f);
median_phase_y0 = median(angle(y0))*180/pi;
result_path = fullfile(P0.outdir, 'sweepA2_results.mat');

% Faktor skala: [0.25 0.5 1 2 4] dikali baseline
f_k = [0.25 0.5 1 2 4];

% {nama field, nilai baseline, skala tampilan, unit, faktor skala}
sw = { 'd',       P0.d,       1e3, 'mm',   f_k;
       'epsr_d',  P0.epsr_d, 1,   '',     f_k;
       'sigma',   P0.sigma,   1,   'S/m',  f_k;
       'epsr',    P0.epsr,    1,   '',     f_k };

% sigma_d (baseline 0): nilai absolut
sigma_d_vals = [0 1e-8 1e-7 1e-6 1e-5 1e-4 3e-4];

res = struct('name',{},'baseline',{},'unit',{},'factors',{},'vals',{},'delta',{}, ...
    'median_abs',{},'median_phase',{},'phase_diff',{},'flag',{});
idx = 1;

% Sweep parameter berskala
for s = 1:size(sw,1)
  nm = sw{s,1};  baseline = sw{s,2};  unit_scale = sw{s,3};
  unit_label = sw{s,4};  factors = sw{s,5};
  dl = zeros(size(factors));  ma = dl;  mp = dl;  pd = dl;  fg = false(size(factors));
  fprintf('\n--- %s (baseline=%.4g %s) ---\n', nm, baseline*unit_scale, unit_label);
  for j = 1:numel(factors)
    P = P0;  P.(nm) = baseline * factors(j);
    y = cceit_runA3_mesh(fA, P, P0.f);
    dl(j) = norm(y - y0)/norm(y0);
    ma(j) = median(abs(y));
    mp(j) = median(angle(y))*180/pi;
    pd(j) = mp(j) - median_phase_y0;
    % Flag d di luar [1,5] mm
    if strcmp(nm, 'd')
      if P.d < 1e-3 || P.d > 5e-3
        fg(j) = true;
      end
    end
    fprintf('%-10s = %-10.4g %s (factor %.2f) | Delta_p = %-10.4g | median|y| = %.4e | phase = %6.2f deg (diff %6.2f)\n', ...
            nm, P.(nm)*unit_scale, unit_label, factors(j), dl(j), ma(j), mp(j), pd(j));
  end
  res(idx).name = nm;  res(idx).baseline = baseline;  res(idx).unit = unit_label;
  res(idx).factors = factors;  res(idx).vals = baseline * factors;
  res(idx).delta = dl;
  res(idx).median_abs = ma;  res(idx).median_phase = mp;  res(idx).phase_diff = pd;
  res(idx).flag = fg;
  idx = idx + 1;
  meta = cceit_make_metadata(P0);
  save(result_path,'res','P0','iA','meta');
end

% Sweep sigma_d (nilai absolut)
nm = 'sigma_d';  unit = '';  factors = nan(size(sigma_d_vals));
dl = zeros(size(sigma_d_vals));  ma = dl;  mp = dl;  pd = dl;  fg = false(size(sigma_d_vals));
fprintf('\n--- %s (baseline=%.4g %s) ---\n', nm, P0.sigma_d, unit);
for j = 1:numel(sigma_d_vals)
  P = P0;  P.sigma_d = sigma_d_vals(j);
  y = cceit_runA3_mesh(fA, P, P0.f);
  dl(j) = norm(y - y0)/norm(y0);
  ma(j) = median(abs(y));
  mp(j) = median(angle(y))*180/pi;
  pd(j) = mp(j) - median_phase_y0;
  fprintf('%-10s = %-10.4g %s | Delta_p = %-10.4g | median|y| = %.4e | phase = %6.2f deg (diff %6.2f)\n', ...
          nm, P.sigma_d, unit, dl(j), ma(j), mp(j), pd(j));
end
res(idx).name = nm;  res(idx).baseline = P0.sigma_d;  res(idx).unit = unit;
res(idx).factors = factors;  res(idx).vals = sigma_d_vals;
res(idx).delta = dl;
res(idx).median_abs = ma;  res(idx).median_phase = mp;  res(idx).phase_diff = pd;
res(idx).flag = fg;
idx = idx + 1;

% Cek degenerasi model lumped: (2d, 2*epsr_d) harus identik dengan baseline
P = P0;  P.d = 2*P0.d;  P.epsr_d = 2*P0.epsr_d;
yd = cceit_runA3_mesh(fA, P, P0.f);
res_degen = norm(yd - y0)/norm(y0);
fprintf('\nCek degenerasi (2d, 2*epsr_d): Delta_p = %.3g (harusnya ~0)\n', res_degen);

meta = cceit_make_metadata(P0);
save(result_path,'res','res_degen','P0','iA','meta');
fprintf('Selesai. Hasil di %s\n', result_path);
