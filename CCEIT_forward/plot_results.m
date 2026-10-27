% plot_results.m
% Plot untuk Section IV dari model A. Menyimpan angka ke plot_data.mat dan gambar ke PNG.
clear; close all; clc;
% run('C:\Users\user\Documents\GitHub\eidors-v3.12\eidors\startup.m');

P0 = cceit_params();
n  = P0.nElec;
eidors_cache clear
[fA, iA] = cceit_mesh_A(P0);
w0  = 2*pi*P0.f;
gam0 = P0.sigma + 1i*w0*P0.eps0*P0.epsr;
zc0  = 1 / (P0.sigma_d/P0.d + 1i*w0*P0.eps0*P0.epsr_d/P0.d);
for e = 1:n, fA.electrode(e).z_contact = zc0; end
gA = gam0*ones(size(fA.elems,1),1);

%% Plot 1: peta |Y| dan fase 16x16 (baseline)
out = cceit_pairscan(fA, gA, P0);
Ymap = out.Y;  Ymap(logical(eye(n))) = NaN;        % diagonal tidak diukur
figure('Name','Peta Y');
subplot(1,2,1); imagesc(abs(Ymap)); axis square; colorbar;
xlabel('electrode'); ylabel('electrode'); title('|Y_{tr}| (2D units, per m depth)');
subplot(1,2,2); imagesc(angle(Ymap)*180/pi); axis square; colorbar;
xlabel('electrode'); ylabel('electrode'); title('phase of Y_{tr} (deg)');
print('-dpng','fig1_Ymap.png');

%% Plot 2: |Y| dan fase terhadap jarak elektroda
c = out.pairs(:,2) - out.pairs(:,1);  dist = min(c, n-c);
idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
y120 = out.Y(idx);
figure('Name','Y vs jarak');
subplot(1,2,1); plot(dist, abs(y120), 'o'); grid on;
xlabel('electrode separation'); ylabel('|Y_{tr}|'); title('|Y| vs separation');
subplot(1,2,2); plot(dist, angle(y120)*180/pi, 'o'); grid on;
xlabel('electrode separation'); ylabel('phase (deg)'); title('phase vs separation');
print('-dpng','fig2_Y_vs_separation.png');

%% Plot 3: medan tegangan dan vektor arus, pasangan (t,r) = (1,9)
t = 1; r = 9;
stim.stim_pattern = zeros(n,1);  stim.volt_pattern = zeros(n,1);
stim.stim_pattern([t r]) = NaN;
stim.volt_pattern(t) = P0.Vtx;   stim.volt_pattern(r) = 0;
stim.meas_pattern = speye(n);
fA.stimulation = stim;
img = mk_image(fA, gA);
img.fwd_solve.get_all_meas = 1;
img.fwd_solve.get_elec_curr = 1;
data = fwd_solve(img);
Vnode = data.volt(1:size(fA.nodes,1),1);
try
  imgV = rmfield(img, 'elem_data');
  imgV.node_data = real(Vnode);
  figure('Name','Medan tegangan dan arus (1,9)');
  show_fem(imgV); hold on;
  q = show_current(img, Vnode);                    % CHECK: perilaku di Octave
  quiver(q.xp, q.yp, real(q.xc), real(q.yc), 2, 'k');
  axis equal tight; colorbar;
  title('Re(V) field and Re(J) vectors, pair (1,9), model A');
  print('-dpng','fig3_field_1_9.png');
catch err
  fprintf('Plot 3 gagal: %s\n', err.message);
end

%% Plot 4: kurva sweep (hitung ulang, mesh dipakai ulang)
y0 = cceit_runA_mesh(fA, P0, P0.f);
freqs = [10e3 30e3 100e3 300e3 500e3 1e6 3e6];
Yf = zeros(numel(freqs),1);
for j = 1:numel(freqs)
  yy = cceit_runA_mesh(fA, P0, freqs(j));  Yf(j) = median(abs(yy));
end
figure('Name','Sweep frekuensi');
loglog(freqs, Yf, 'o-'); grid on;
xlabel('frequency (Hz)'); ylabel('median |Y_{tr}|'); title('Frequency sweep, model A');
print('-dpng','fig4a_freq.png');

Sp = @(y) norm(y-y0)/norm(y0);
dl = [1 2 3 4.5 6 9]*1e-3;   Sd = zeros(size(dl));
el = [3 6 9 18 30];          Se = zeros(size(el));
sl = [1e-9 1e-7 1e-5 1e-4 1e-3]; Ss = zeros(size(sl));
for j = 1:numel(dl), P = P0; P.d = dl(j);      Sd(j) = Sp(cceit_runA_mesh(fA,P,P0.f)); end
for j = 1:numel(el), P = P0; P.epsr_d = el(j); Se(j) = Sp(cceit_runA_mesh(fA,P,P0.f)); end
for j = 1:numel(sl), P = P0; P.sigma_d = sl(j); Ss(j) = Sp(cceit_runA_mesh(fA,P,P0.f)); end
figure('Name','Sweep lapisan');
subplot(1,3,1); plot(dl*1e3, Sd, 'o-'); grid on; xlabel('d (mm)'); ylabel('S_p');
subplot(1,3,2); plot(el, Se, 'o-'); grid on; xlabel('\epsilon_{r,d}'); ylabel('S_p');
subplot(1,3,3); semilogx(sl, Ss, 'o-'); grid on; xlabel('\sigma_d (S/m)'); ylabel('S_p');
print('-dpng','fig4b_layer.png');

% Sweep jaringan dari sweepA3_results.mat (jika ada)
if exist('sweepA3_results.mat','file')
  L = load('sweepA3_results.mat');
  figure('Name','Sensitivitas jaringan');
  for k = 1:numel(L.R)
    subplot(1,2,1); semilogy(L.R(k).sig, max(L.R(k).Sp_sig,1e-8), 'o-'); hold on;
    subplot(1,2,2); semilogy(L.R(k).sig, max(L.R(k).Ssh_sig,1e-8), 'o-'); hold on;
  end
  subplot(1,2,1); grid on; xlabel('\sigma tissue (S/m)'); ylabel('S_p');
  title('S_p, 9 kombinasi (d, f)');
  subplot(1,2,2); grid on; xlabel('\sigma tissue (S/m)'); ylabel('S_{shape}');
  title('S_{shape}, 9 kombinasi (d, f)');
  print('-dpng','fig4c_tissue.png');
end

meta.version = version; meta.date = datestr(now);
save('plot_data.mat','P0','iA','Ymap','dist','y120','freqs','Yf','dl','Sd','el','Se','sl','Ss','meta');
fprintf('Selesai. Gambar PNG dan plot_data.mat tersimpan di %s\n', pwd);
