% run_sweepA.m
% (a) delta_mesh model A3, (b) sweep frekuensi model A3.
% Satu file ini saja; tidak mengubah file lain.
clear; close all; clc;
P0 = cceit_params();

%% (a) delta_mesh model A3 pada frekuensi baseline
% Level sizes are passed as explicit A3 mesh overrides; physical model
% parameters and the default verification mesh remain unchanged.
% level: [h_int mm, h_el mm]; level terakhir = acuan (terhalus)
levels = [4.0 2.0; 3.0 1.5; 2.5 1.0];
nL = size(levels,1);
yL = cell(nL,1);  nel = zeros(nL,1);  ok = false(nL,1);
time_mesh_build_s = nan(nL,1);
time_mesh_scan_s = nan(nL,1);
delta_mesh_A = nan(nL,1);

for k = 1:nL
  P = P0;
  P.mesh_h_int_A3 = levels(k,1)*1e-3;
  P.mesh_h_el_A3  = levels(k,2)*1e-3;
  try
    eidors_cache clear
    timer_build = tic;
    [fmdl, info] = cceit_mesh_A3(P);
    time_mesh_build_s(k) = toc(timer_build);
    timer_scan = tic;
    y = cceit_runA3_mesh(fmdl, P, P0.f);
    time_mesh_scan_s(k) = toc(timer_scan);
    yL{k} = y;  nel(k) = info.nElems;  ok(k) = true;
    fprintf('level %d (h_int=%.1f mm, h_el=%.1f mm): %d elemen\n', ...
      k, info.h_medium*1e3, info.h_electrode*1e3, nel(k));
  catch err
    fprintf('level %d GAGAL: %s\n', k, err.message);
  end
end

if sum(ok) < 2
  error('run_sweepA: at least two distinct mesh levels must build successfully');
end
if numel(unique(nel(ok))) < 2
  error('run_sweepA: mesh overrides produced identical element counts; inspect Netgen mesh-size handling');
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

%% (b) Sweep frekuensi (mesh A3 dibuat sekali, mesh tidak bergantung pada f)
% 13 titik log-spaced dari 10 kHz sampai 10 MHz, sertakan 500 kHz
freqs_base = logspace(log10(10e3), log10(10e6), 13);
if min(abs(freqs_base - 500e3)) > 1e3
    % Keep the frequency vector a row; appending vertically mixes 1xN and 1x1.
    freqs_base = [freqs_base 500e3];
    freqs_base = sort(freqs_base);
end
freqs = freqs_base;
nf = numel(freqs);
Yf = zeros(120, nf);
median_abs_It = zeros(1, nf);
median_phase_deg = zeros(1, nf);
time_frequency_scan_s = nan(nf,1);

% Build the production A3 mesh once for the frequency sweep. No mesh overrides
% are set here, so this remains identical to the usual configured A3 model.
eidors_cache clear
[fmdl_A3, info_A3] = cceit_mesh_A3(P0);
fprintf('Mesh A3 built once: %d elements\n', info_A3.nElems);

for j = 1:nf
  timer_scan = tic;
  y = cceit_runA3_mesh(fmdl_A3, P0, freqs(j));
  time_frequency_scan_s(j) = toc(timer_scan);
  Yf(:,j) = y;
  median_abs_It(j) = median(abs(y));
  median_phase_deg(j) = median(angle(y))*180/pi;
  fprintf('f = %8.0f Hz | median|I_t| = %.4e | median phase = %7.2f deg\n', ...
    freqs(j), median_abs_It(j), median_phase_deg(j));
end

meta = cceit_make_metadata(P0);
result_path = fullfile(P0.outdir, 'sweepA_results.mat');
save(result_path,'levels','yL','nel','ok','delta_mesh_A','time_mesh_build_s', ...
  'time_mesh_scan_s','freqs','Yf','median_abs_It','median_phase_deg', ...
  'time_frequency_scan_s','P0','meta');

fprintf('Frequency sweep data saved: %s\n', result_path);
