% cceit_recon.m
% Forward (anomali) -> arus -> TIA -> tegangan kompleks -> rekonstruksi sigma dan epsr.
% Forward memakai rute voltage-driven (cceit_pairscan). Jacobian memakai rute arus
% (calc_jacobian), karena belum dicek apakah calc_jacobian mendukung volt_pattern.
% Perlu: cceit_params, cceit_mesh_A, cceit_mesh_B4, cceit_pairscan.
1;

function frac = frac_in(nodes, elems, fin)
  nb = 4; Bc = zeros(0,2);
  for i = 0:nb-1
    for j = 0:nb-1-i, Bc(end+1,:) = [(i+1/3)/nb, (j+1/3)/nb]; end
  end
  for i = 0:nb-2
    for j = 0:nb-2-i, Bc(end+1,:) = [(i+2/3)/nb, (j+2/3)/nb]; end
  end
  frac = zeros(size(elems,1),1);
  for q = 1:size(Bc,1)
    l1 = Bc(q,1); l2 = Bc(q,2); l3 = 1-l1-l2;
    px = l1*nodes(elems(:,1),1) + l2*nodes(elems(:,2),1) + l3*nodes(elems(:,3),1);
    py = l1*nodes(elems(:,1),2) + l2*nodes(elems(:,2),2) + l3*nodes(elems(:,3),2);
    frac = frac + double(fin(px,py));
  end
  frac = frac / size(Bc,1);
end

function dg = dgam_build(nodes, elems, reg, Yreg, Ybg)
  dg = zeros(size(elems,1),1);
  for k = 1:numel(reg)
    dg = dg + frac_in(nodes, elems, reg{k}) * (Yreg{k} - Ybg);
  end
end

function z = z_lumped(P, w)
  z = 1 / (P.sigma_d/P.d + 1i*w*P.eps0*P.epsr_d/P.d);
end

function draw_map(nodes, elems, cdata, clim, ttl, R)
  patch('Faces',elems,'Vertices',nodes,'FaceVertexCData',cdata, ...
        'FaceColor','flat','EdgeColor','none');
  hold on; th = linspace(0,2*pi,300);
  plot(R*cos(th), R*sin(th), 'k', 'LineWidth', 0.5);
  axis equal tight; caxis(clim); colormap(jet); colorbar; title(ttl);
end

%% ===================== PARAMETER =====================
clear; close all; clc;
% run('C:\Users\user\Documents\GitHub\eidors-v3.12\eidors\startup.m');
P = cceit_params();
P.f = 3e6;          % Hz   (sengaja lebih tinggi dari baseline agar jaringan lebih terlihat)
P.d = 1e-3;         % m    (lebih tipis dari baseline, alasan sama). Untuk data_src='B' pakai 3e-3
data_src  = 'A';    % 'A' = mesh A halus (lumped), 'B' = cincin centroid (B lama, belum valid)
phantom   = 2;      % 1 = lingkaran dekat elektroda 2 | 2 = paru + jantung
Rf        = 10e3;   % Ohm, TIA ideal (hanya skala; hilang saat dikonversi balik)
SNR       = 100;    % terhadap max|dI|; Inf = tanpa noise
alpha_rel = 1e-2;   % regularisasi relatif, tala manual
a_rad = 0.056; a_r = 0.022;          % phantom 1: jarak pusat dan radius [m]

w  = 2*pi*P.f;  n = P.nElec;  nd = n*(n-1)/2;
adm = @(s,er) s + 1i*w*P.eps0*er;
Ybg    = adm(P.sigma, P.epsr);        % PLACEHOLDER
Yanom  = adm(0.67, 80);               % PLACEHOLDER
Ylung  = adm(0.05, 20);  Yheart = adm(0.67, 80);   % PLACEHOLDER
gam_d  = adm(P.sigma_d, P.epsr_d);
if strcmp(data_src,'B') && P.d < 2.5e-3
  warning('data_src=B dengan d tipis: cincin centroid terlalu kasar, hasil tidak sahih.');
end

%% ===================== 1. FORWARD DENGAN ANOMALI =====================
eidors_cache clear
switch data_src
  case 'A'
    Pd = P;  Pd.h_int = P.h_int*0.9;  Pd.h_el = P.h_el*0.6;   % mesh data != mesh rekonstruksi
    [fD, iD] = cceit_mesh_A(Pd);
    zc = z_lumped(P, w);
    for e = 1:n, fD.electrode(e).z_contact = zc; end
    ringD = false(size(fD.elems,1),1);
  case 'B'
    [fD, ringD, iD] = cceit_mesh_B4(P, 'tank', P.h_ring_B);
  otherwise
    error('data_src harus A atau B');
end
nodesD = fD.nodes(:,1:2);  elemsD = fD.elems;
fprintf('Mesh data (%s): %d elemen\n', data_src, size(elemsD,1));

if phantom == 1
  ec2 = mean(nodesD(fD.electrode(2).nodes,:),1);  aj = atan2(ec2(2),ec2(1));
  xa = a_rad*cos(aj);  ya = a_rad*sin(aj);
  reg  = {@(px,py) hypot(px-xa,py-ya) < a_r};
  Yreg = {Yanom};
else
  s = P.R/0.15;
  reg  = {@(px,py) ((px+0.07*s)/(0.04*s)).^2 + (py/(0.07*s)).^2 < 1, ...
          @(px,py) ((px-0.07*s)/(0.04*s)).^2 + (py/(0.07*s)).^2 < 1, ...
          @(px,py) px.^2 + (py-0.01*s).^2 < (0.03*s)^2};
  Yreg = {Ylung, Ylung, Yheart};
end

gH = Ybg*ones(size(elemsD,1),1);
gI = gH + dgam_build(nodesD, elemsD, reg, Yreg, Ybg);
gH(ringD) = gam_d;  gI(ringD) = gam_d;

outH = cceit_pairscan(fD, gH, P);
outI = cceit_pairscan(fD, gI, P);
fprintf('Cek forward data: max dcc = %.2g | max floating/It = %.2g | max dev U = %.2g\n', ...
        max([outH.dcc; outI.dcc]), max([outH.dfloat; outI.dfloat]), max([outH.dU; outI.dU]));
pairs = outH.pairs;
idx = sub2ind([n n], pairs(:,1), pairs(:,2));
I_h = outH.Y(idx) * P.Vtx;           % arus transmitter [per m kedalaman 2D]
I_i = outI.Y(idx) * P.Vtx;

%% ===================== 2. TIA -> TEGANGAN KOMPLEKS =====================
Vtia_h = -Rf * I_h;   Vtia_i = -Rf * I_i;      % Re/Im = keluaran demodulator I/Q

outdir = fullfile(pwd,'hasil_cceit');  if ~exist(outdir,'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir,'cceit_recon_data.csv'),'w');
fprintf(fid,'exc,meas,Re_Vtia_homog,Im_Vtia_homog,Re_Vtia_anomali,Im_Vtia_anomali\n');
for k = 1:nd
  fprintf(fid,'%d,%d,%.12e,%.12e,%.12e,%.12e\n', pairs(k,1), pairs(k,2), ...
    real(Vtia_h(k)), imag(Vtia_h(k)), real(Vtia_i(k)), imag(Vtia_i(k)));
end
fclose(fid);

% Noise di domain arus, lalu kembali ke impedansi
randn('state',1);
if isinf(SNR), sig_n = 0; else sig_n = max(abs(I_i - I_h))/SNR; end
cn = @(v) sig_n/sqrt(2) * (randn(size(v)) + 1i*randn(size(v)));
Z_h0 = P.Vtx ./ (-Vtia_h/Rf);                  % tanpa noise (untuk kalibrasi)
Z_h  = P.Vtx ./ (-Vtia_h/Rf + cn(Vtia_h));
Z_i  = P.Vtx ./ (-Vtia_i/Rf + cn(Vtia_i));
dZ   = Z_i - Z_h;

%% ===================== 3. MODEL REKONSTRUKSI (mesh A, lumped) =====================
eidors_cache clear
[fR, iR] = cceit_mesh_A(P);
nodesR = fR.nodes(:,1:2);  elemsR = fR.elems;  nE = size(elemsR,1);

clear stim
for p = 1:nd
  sp = zeros(n,1);  sp(pairs(p,1)) = 1;  sp(pairs(p,2)) = -1;
  stim(p).stimulation  = 'Amps';
  stim(p).stim_pattern = sp;
  stim(p).meas_pattern = sp';
end
fR.stimulation = stim;
z0 = z_lumped(P, w);
for e = 1:n, fR.electrode(e).z_contact = z0; end
imgR = mk_image(fR, Ybg);
Zm = fwd_solve(imgR).meas;

% Cek ekuivalensi rute tegangan dan rute arus pada mesh yang sama: Y_tr * Z_tr = 1
outR = cceit_pairscan(fR, Ybg*ones(nE,1), P);
Yv = outR.Y(sub2ind([n n], pairs(:,1), pairs(:,2)));
fprintf('Cek rute: max |Y_volt * Z_amps - 1| = %.3g (harusnya ~0; jika ~2, tanda arus terbalik)\n', ...
        max(abs(Yv.*Zm - 1)));

kappa = mean(imag(Z_h0)) / mean(imag(Zm));
fprintf('Rasio imag(Z) data / model rekonstruksi = %.3f\n', kappa);
if strcmp(data_src,'B')                       % kalibrasi seperti cceit_sim3 (hanya untuk B)
  for e = 1:n, fR.electrode(e).z_contact = kappa*z0; end
  imgR = mk_image(fR, Ybg);
  fprintf('Kalibrasi kappa dipakai: %.3f\n', kappa);
end

J = calc_jacobian(imgR);                      % nd x nE, kompleks
[~, kc] = min(hypot(nodesR(elemsR(:,1),1)-0.03, nodesR(elemsR(:,1),2)-0.02));
dp = 1e-3*Ybg;  ip = imgR;  ip.elem_data(kc) = ip.elem_data(kc) + dp;
err_fd = norm((fwd_solve(ip).meas - fwd_solve(imgR).meas)/dp - J(:,kc)) / norm(J(:,kc));
fprintf('Galat Jacobian vs finite difference: %.2e\n', err_fd);
if err_fd > 5e-2, warning('Jacobian tidak cocok dengan finite difference, hasil meragukan'); end

%% ===================== 4. SOLVE (NOSER/Kotre, difference data) =====================
dg   = sum(abs(J).^2, 1).';
Rd   = dg.^0.5;  Rd = Rd * mean(dg)/mean(Rd);
Rinv = 1 ./ Rd;
Jh   = J';
A    = J * (Rinv .* Jh);
dgam = (Rinv .* Jh) * ((A + alpha_rel*real(trace(A))/nd*eye(nd)) \ dZ);

dg_true = dgam_build(nodesR, elemsR, reg, Yreg, Ybg);
dsig_t = real(dg_true);          deps_t = imag(dg_true)/(w*P.eps0);
dsig_r = real(dgam);             deps_r = imag(dgam)/(w*P.eps0);
ncc = @(a,b) (a'*b)/(norm(a)*norm(b) + eps);
fprintf('NCC sigma = %.3f | NCC epsr = %.3f | SNR = %g\n', ncc(dsig_r,dsig_t), ncc(deps_r,deps_t), SNR);

%% ===================== 5. PLOT =====================
Rp = P.R;
figure('Position',[60 60 1000 850],'Name','Rekonstruksi');
cl = max(abs(dsig_t))+eps;  subplot(2,2,1); draw_map(nodesR,elemsR,dsig_t,[-cl cl],'GT: \Delta\sigma (S/m)',Rp);
cl = max(abs(dsig_r))+eps;  subplot(2,2,2); draw_map(nodesR,elemsR,dsig_r,[-cl cl],'Rekonstruksi: \Delta\sigma (skala per panel)',Rp);
cl = max(abs(deps_t))+eps;  subplot(2,2,3); draw_map(nodesR,elemsR,deps_t,[-cl cl],'GT: \Delta\epsilon_r',Rp);
cl = max(abs(deps_r))+eps;  subplot(2,2,4); draw_map(nodesR,elemsR,deps_r,[-cl cl],'Rekonstruksi: \Delta\epsilon_r (skala per panel)',Rp);
print('-dpng', fullfile(outdir,'fig_recon.png'));

figure('Position',[80 80 1000 800],'Name','Pengukuran 120 pasangan');
k = 1:nd;
subplot(2,2,1); plot(k,real(Vtia_h),'b.-',k,real(Vtia_i),'r.-'); grid on;
xlabel('pair index'); ylabel('Re(V_{TIA}) [V]'); legend('homogen','anomali');
subplot(2,2,2); plot(k,imag(Vtia_h),'b.-',k,imag(Vtia_i),'r.-'); grid on;
xlabel('pair index'); ylabel('Im(V_{TIA}) [V]'); legend('homogen','anomali');
subplot(2,2,3); semilogy(k, abs(Vtia_i - Vtia_h), 'k.-'); grid on;
xlabel('pair index'); ylabel('|\DeltaV_{TIA}| [V]');
M = nan(n);  M(idx) = abs(Vtia_i - Vtia_h);  M = max(M, M');   % simetris, diagonal NaN
subplot(2,2,4); imagesc(M); axis square; colorbar; title('|\DeltaV_{TIA}| per pasangan');
xlabel('electrode'); ylabel('electrode');
print('-dpng', fullfile(outdir,'fig_measurements.png'));

meta.version = version;  meta.date = datestr(now);
save(fullfile(outdir,'cceit_recon_results.mat'), 'P','data_src','phantom','Rf','SNR','alpha_rel', ...
     'pairs','Vtia_h','Vtia_i','dZ','dgam','dg_true','kappa','err_fd','iD','iR','meta');
fprintf('Selesai. Hasil di %s\n', outdir);
