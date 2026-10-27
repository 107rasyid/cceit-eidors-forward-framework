clear; close all; clc;
P = cceit_params();
w = 2*pi*P.f;
gam   = P.sigma   + 1i*w*P.eps0*P.epsr;
gam_d = P.sigma_d + 1i*w*P.eps0*P.epsr_d;

%% Model A
[fA, iA] = cceit_mesh_A(P);
zc = 1 / (P.sigma_d/P.d + 1i*w*P.eps0*P.epsr_d/P.d);   % tanpa faktor kalibrasi
for e = 1:P.nElec, fA.electrode(e).z_contact = zc; end
outA = cceit_pairscan(fA, gam*ones(size(fA.elems,1),1), P);

%% Resiprokalitas (pasangan terbalik pada subset)
sel = round(linspace(1, size(outA.pairs,1), 10));   % 10 pasangan, ubah sesuai kebutuhan
recip = zeros(numel(sel),1);
for k = 1:numel(sel)
  t = outA.pairs(sel(k),1); r = outA.pairs(sel(k),2);
  I = cceit_solve_pair(fA, gam*ones(size(fA.elems,1),1), P, r, t);  % r jadi transmitter
  Yrt = I(r) / P.Vtx;
  recip(k) = abs(Yrt - outA.Y(t,r)) / abs(outA.Y(t,r));
end
fprintf('Resiprokalitas: max |Ytr-Yrt|/|Ytr| = %.3g (%d pasangan)\n', max(recip), numel(sel));

%% Model B
[fB, ring, iB] = cceit_mesh_B(P);
fprintf('Mesh B: %d node, %d elemen, %d elemen cincin\n', iB.nNodes, iB.nElems, iB.nRing);
gB = gam*ones(iB.nElems,1);  gB(ring) = gam_d;
outB = cceit_pairscan(fB, gB, P);
fprintf('B: max dcc = %.3g, max floating/It = %.3g, max dev U = %.3g\n', ...
        max(outB.dcc), max(outB.dfloat), max(outB.dU));

%% delta_layer (120 elemen unik, tanpa kappa)
idx = sub2ind(size(outA.Y), outA.pairs(:,1), outA.pairs(:,2));
yA = outA.Y(idx);  yB = outB.Y(idx);
delta_layer = norm(yA - yB) / norm(yB);
fprintf('delta_layer = %.3g\n', delta_layer);
fprintf('rasio |yA|/|yB| (median) = %.3g\n', median(abs(yA)./abs(yB)));

meta.version = version; meta.date = datestr(now);
save('step2_results.mat','outA','outB','recip','delta_layer','P','iA','iB','meta');
