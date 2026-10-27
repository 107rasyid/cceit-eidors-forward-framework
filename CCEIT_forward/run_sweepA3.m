% run_sweepA3.m
% Sensitivitas jaringan (sigma, epsr) pada beberapa d dan f, model A.
% Ukuran: S_p (seperti Section II-F) dan S_shape (hanya pola antar pasangan).
clear; close all; clc;
% run('C:\Users\user\Documents\GitHub\eidors-v3.12\eidors\startup.m');

P0 = cceit_params();
eidors_cache clear
[fA, iA] = cceit_mesh_A(P0);          % mesh dibuat sekali
fprintf('Mesh A: %d elemen\n', iA.nElems);

dlist = [0.5 1 3]*1e-3;               % tebal lapisan [m]
flist = [100e3 500e3 3e6];            % frekuensi [Hz]
sig_list = [0.05 0.1 0.2 0.5 1.0];    % S/m   (placeholder)
eps_list = [10 40 78 150 400];        % relatif (placeholder)

Sp  = @(y,y0) norm(y - y0) / norm(y0);
% S_shape: normalisasi dengan rata-rata kompleks, sehingga skala umum hilang
Ssh = @(y,y0) norm(y/mean(y) - y0/mean(y0)) / norm(y0/mean(y0));

R = struct('d',{},'f',{},'sig',{},'eps',{},'Sp_sig',{},'Ssh_sig',{},'Sp_eps',{},'Ssh_eps',{},'y0',{});
k = 0;
for a = 1:numel(dlist)
  for b = 1:numel(flist)
    P = P0;  P.d = dlist(a);  f = flist(b);
    y0 = cceit_runA_mesh(fA, P, f);               % baseline jaringan

    sp_s = zeros(size(sig_list)); sh_s = sp_s;
    for j = 1:numel(sig_list)
      Q = P;  Q.sigma = sig_list(j);
      y = cceit_runA_mesh(fA, Q, f);
      sp_s(j) = Sp(y,y0);  sh_s(j) = Ssh(y,y0);
    end
    sp_e = zeros(size(eps_list)); sh_e = sp_e;
    for j = 1:numel(eps_list)
      Q = P;  Q.epsr = eps_list(j);
      y = cceit_runA_mesh(fA, Q, f);
      sp_e(j) = Sp(y,y0);  sh_e(j) = Ssh(y,y0);
    end

    k = k + 1;
    R(k).d = P.d; R(k).f = f; R(k).sig = sig_list; R(k).eps = eps_list;
    R(k).Sp_sig = sp_s; R(k).Ssh_sig = sh_s;
    R(k).Sp_eps = sp_e; R(k).Ssh_eps = sh_e; R(k).y0 = y0;

    fprintf('\nd = %.1f mm, f = %.0f kHz  (baseline sigma=%g, epsr=%g)\n', ...
            P.d*1e3, f/1e3, P0.sigma, P0.epsr);
    fprintf('  sigma : %s\n', sprintf('%8.3g', sig_list));
    fprintf('  S_p   : %s\n', sprintf('%8.3g', sp_s));
    fprintf('  S_shp : %s\n', sprintf('%8.3g', sh_s));
    fprintf('  epsr  : %s\n', sprintf('%8.3g', eps_list));
    fprintf('  S_p   : %s\n', sprintf('%8.3g', sp_e));
    fprintf('  S_shp : %s\n', sprintf('%8.3g', sh_e));

    meta.version = version; meta.date = datestr(now);
    save('sweepA3_results.mat','R','P0','iA','dlist','flist','meta');   % simpan tiap blok
  end
end
fprintf('\nSelesai. Hasil di sweepA3_results.mat\n');
