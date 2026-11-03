% run_sweepA.m
% (a) delta_mesh model A, (b) sweep frekuensi model A.
% Satu file ini saja; tidak mengubah file lain.
clear; close all; clc;
P0 = cceit_params();

%% Fungsi bantu: jalankan model A pada satu P dan satu frekuensi
runA = @(P, f) local_runA(P, f);

%% (a) delta_mesh model A pada frekuensi baseline
% level: [skala h_int, skala h_el]; level terakhir = acuan (terhalus)
levels = [4.0 2.0; 3.0 1.5; 2.5 1.0];
nL = size(levels,1);
yL = cell(nL,1);  nel = zeros(nL,1);  ok = false(nL,1);
time_mesh_scan_s = nan(nL,1);
delta_mesh_A = nan(nL,1);

for k = 1:nL
  P = P0;
  P.h_int = levels(k,1)*1e-3;
  P.h_el  = levels(k,2)*1e-3;
  try
    eidors_cache clear
    timer_scan = tic;
    [y, ne] = runA(P, P0.f);
    time_mesh_scan_s(k) = toc(timer_scan);
    yL{k} = y;  nel(k) = ne;  ok(k) = true;
    fprintf('level %d (h_int x%.1f, h_el x%.1f): %d elemen\n', k, levels(k,1), levels(k,2), ne);
  catch err
    fprintf('level %d GAGAL: %s\n', k, err.message);
  end
end

iref = find(ok, 1, 'last');
for k = find(ok)'
  if k == iref
    delta_mesh_A(k) = 0;
    continue;
  end
  dm = norm(yL{k} - yL{iref}) / norm(yL{iref});
  delta_mesh_A(k) = dm;
  fprintf('delta_mesh level %d vs acuan level %d = %.3g\n', k, iref, dm);
end

%% (b) Sweep frekuensi (mesh baseline, nilai jaringan masih placeholder)
freqs = [10e3 30e3 100e3 300e3 500e3 1e6 3e6];
nf = numel(freqs);
Yf = zeros(120, nf);
time_frequency_scan_s = nan(nf,1);
eidors_cache clear
for j = 1:nf
  timer_scan = tic;
  [Yf(:,j), ~] = runA(P0, freqs(j));
  time_frequency_scan_s(j) = toc(timer_scan);
  fprintf('f = %8.0f Hz | median|Y| = %.4e | median fase = %7.2f deg\n', ...
    freqs(j), median(abs(Yf(:,j))), median(angle(Yf(:,j)))*180/pi);
end

% Sensitivitas Delta_p terhadap baseline (f = P0.f), sesuai Section II-F
[~, ib] = min(abs(freqs - P0.f));
y0 = Yf(:,ib);
Sp = zeros(1,nf);
for j = 1:nf
  Sp(j) = norm(Yf(:,j) - y0) / norm(y0);
end
fprintf('\nDelta_p terhadap f baseline = %.0f Hz:\n', freqs(ib));
for j = 1:nf, fprintf('  f = %8.0f Hz : Delta_p = %.4g\n', freqs(j), Sp(j)); end

meta = cceit_make_metadata(P0);
result_path = fullfile(P0.outdir, 'sweepA_results.mat');
save(result_path,'levels','yL','nel','ok','delta_mesh_A','time_mesh_scan_s', ...
  'freqs','Yf','Sp','time_frequency_scan_s','P0','meta');

figure; semilogx(freqs, Sp, 'o-'); grid on;
xlabel('Frekuensi (Hz)'); ylabel('Delta_p'); title('Sensitivitas terhadap frekuensi (model A)');
print('-dpng', sprintf('-r%d', P0.plot_export_dpi), ...
    fullfile(P0.outdir, 'sweepA_frequency_delta.png'));


