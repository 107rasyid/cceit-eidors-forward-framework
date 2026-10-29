clear; close all; clc;
% run('/path/to/eidors/startup.m');   % jika perlu

P = cceit_params();
[fmdl, info] = cceit_mesh_A(P);
fprintf('Mesh A: %d node, %d elemen, rmax = %.4f m\n', info.nNodes, info.nElems, info.rmax);

w = 2*pi*P.f;
gamma = P.sigma + 1i*w*P.eps0*P.epsr;

% Kontak kapasitif model A: z = 1/(G + jwC), G = sigma_d/d, C = eps_d/d
G = P.sigma_d / P.d;
C = P.eps0*P.epsr_d / P.d;
zc = 1 / (G + 1i*w*C);
for e = 1:P.nElec, fmdl.electrode(e).z_contact = zc; end
fprintf('z_contact = %.4g %+.4gi Ohm.m\n', real(zc), imag(zc));

tic; out = cceit_pairscan(fmdl, gamma*ones(size(fmdl.elems,1),1), P); tt = toc;

fprintf('Waktu 120 solve: %.1f s\n', tt);
fprintf('max delta_cc    = %.3g\n', max(out.dcc));
fprintf('max floating/It = %.3g\n', max(out.dfloat));
fprintf('max dev U       = %.3g V\n', max(out.dU));

% Meta data untuk reproducibility
meta.matlab = version; meta.date = datestr(now); meta.eidors = eidors_obj('eidors_version');
save('step1_results.mat','out','P','info','meta');

figure; imagesc(abs(out.Y)); axis square; colorbar;
xlabel('electrode'); ylabel('electrode'); title('|Y_{tr}| [S/m^{-1} units: see CHECK]');
