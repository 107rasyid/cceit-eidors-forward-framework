clear; close all; clc;
% run('C:\Users\user\Documents\GitHub\eidors-v3.12\eidors\startup.m');
P0 = cceit_params();
eidors_cache clear
[fA, iA] = cceit_mesh_A(P0);
fprintf('Mesh A: %d elemen\n', iA.nElems);

y0 = cceit_runA_mesh(fA, P0, P0.f);          % baseline

% Acuan "dua kapasitor seri": Yref = w_el/(2 z), z hanya dari lapisan (perkiraan kasar)
Yref = @(P,f) P.w_el / (2 * (1/(P.sigma_d/P.d + 1i*2*pi*f*P.eps0*P.epsr_d/P.d)));
report = @(name, val, y, P) fprintf('%-10s = %-9.3g | S_p = %-9.4g | median|y|/|Yref| = %.4f | fase y/Yref = %7.3f deg\n', ...
    name, val, norm(y-y0)/norm(y0), median(abs(y))/abs(Yref(P,P0.f)), ...
    median(angle(y/Yref(P,P0.f)))*180/pi);

%% Sweep jaringan (nilai placeholder, belum bersumber)
fprintf('\n--- sigma jaringan (S/m), epsr = %g ---\n', P0.epsr);
for v = [0.05 0.1 0.2 0.5 1.0]
  P = P0; P.sigma = v;
  report('sigma', v, cceit_runA_mesh(fA,P,P0.f), P);
end
fprintf('\n--- epsr jaringan, sigma = %g ---\n', P0.sigma);
for v = [10 40 78 150 400]
  P = P0; P.epsr = v;
  report('epsr', v, cceit_runA_mesh(fA,P,P0.f), P);
end

%% Sweep lapisan
fprintf('\n--- tebal d (mm) ---\n');
for v = [1 2 3 4.5 6 9]*1e-3
  P = P0; P.d = v;
  report('d(mm)', v*1e3, cceit_runA_mesh(fA,P,P0.f), P);
end
fprintf('\n--- sigma_d (S/m) ---\n');
for v = [1e-9 1e-7 1e-5 1e-4 1e-3]
  P = P0; P.sigma_d = v;
  report('sigma_d', v, cceit_runA_mesh(fA,P,P0.f), P);
end
fprintf('\n--- epsr_d ---\n');
for v = [3 6 9 18 30]
  P = P0; P.epsr_d = v;
  report('epsr_d', v, cceit_runA_mesh(fA,P,P0.f), P);
end

%% Cek degenerasi model lumped: (d, epsr_d) dengan rasio sama harus identik
P = P0; P.d = 2*P0.d; P.epsr_d = 2*P0.epsr_d;
yd = cceit_runA_mesh(fA, P, P0.f);
fprintf('\nCek degenerasi (2d, 2*epsr_d): S_p = %.3g (harusnya ~0)\n', norm(yd-y0)/norm(y0));

meta.version = version; meta.date = datestr(now);
save('sweepA2_results.mat','P0','iA','meta');
