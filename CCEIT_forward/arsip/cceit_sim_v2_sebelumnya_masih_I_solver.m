% cceit_sim3.m  (versi ringkas)
% CCEIT: forward (insulator asli di mesh) -> peta GT -> CSV data pengukuran -> inverse (NOSER kompleks).
% Eksitasi tegangan 1 V di elektroda i, elektroda j = 0 V (virtual ground TIA), lainnya floating.
% Pasangan i<j: n_elec = 16 -> 120 pengukuran; n_elec = 12 -> 66.
1;

function [fm, nodes, elems, xc, yc] = mesh_cc(Rb, h, hel, n_elec, w_el)
  fm = ng_mk_cyl_models([0, Rb, h], [n_elec], [w_el, 0, hel]);
  fm.nodes = fm.nodes * (Rb / max(hypot(fm.nodes(:,1), fm.nodes(:,2))));   % pastikan radius luar
  nodes = fm.nodes(:,1:2);  elems = fm.elems;
  if size(elems,2) ~= 3, error('Script ini untuk mesh 2D (segitiga).'); end
  nE = size(elems,1);
  xc = mean(reshape(nodes(elems(:),1), nE, 3), 2);
  yc = mean(reshape(nodes(elems(:),2), nE, 3), 2);
end

function [ec, wspan] = elec_geom_cc(fm, nodes, Rb)
  n = numel(fm.electrode);  ec = zeros(n,2);  wspan = zeros(n,1);
  for i = 1:n
    nn = nodes(fm.electrode(i).nodes,:);
    ec(i,:) = mean(nn,1);
    a0 = atan2(ec(i,2), ec(i,1));
    da = angle(exp(1i*(atan2(nn(:,2),nn(:,1)) - a0)));
    wspan(i) = (max(da) - min(da)) * Rb;
  end
end

function frac = frac_inside_cc(nodes, elems, fin)
  % fraksi luas tiap elemen di dalam daerah fin(px,py), 16 titik sampel per segitiga
  nb = 4;  Bc = zeros(nb*nb, 2);  q = 0;
  for i = 0:nb-1
    for j = 0:nb-1-i
      q = q + 1;  Bc(q,:) = [(i+1/3)/nb, (j+1/3)/nb];
    end
  end
  for i = 0:nb-2
    for j = 0:nb-2-i
      q = q + 1;  Bc(q,:) = [(i+2/3)/nb, (j+2/3)/nb];
    end
  end
  frac = zeros(size(elems,1), 1);
  for q = 1:size(Bc,1)
    l1 = Bc(q,1);  l2 = Bc(q,2);  l3 = 1 - l1 - l2;
    px = l1*nodes(elems(:,1),1) + l2*nodes(elems(:,2),1) + l3*nodes(elems(:,3),1);
    py = l1*nodes(elems(:,1),2) + l2*nodes(elems(:,2),2) + l3*nodes(elems(:,3),2);
    frac = frac + double(fin(px, py));
  end
  frac = frac / size(Bc,1);
end

function draw_map_cc(nodes, elems, cdata, clim, ttl, ec, wspan, Rb, tk, lm, r_in)
  th = linspace(0, 2*pi, 300);
  patch('Faces',elems,'Vertices',nodes,'FaceVertexCData',cdata,'FaceColor','flat','EdgeColor','none');
  hold on
  if r_in > 0, plot(r_in*cos(th), r_in*sin(th), 'k', 'LineWidth', 0.5); end
  plot(Rb*cos(th), Rb*sin(th), 'k', 'LineWidth', 0.5);
  for i = 1:size(ec,1)                               % elektroda: persegi panjang menyinggung lingkaran
    a = atan2(ec(i,2), ec(i,1));  wd = wspan(i);
    patch(Rb*cos(a) + [-1 1 1 -1]*(wd/2)*(-sin(a)) + [0 0 1 1]*tk*cos(a), ...
          Rb*sin(a) + [-1 1 1 -1]*(wd/2)*( cos(a)) + [0 0 1 1]*tk*sin(a), [0.7 0.7 0.7], 'EdgeColor','k');
  end
  axis equal; axis(lm); caxis(clim); colormap(jet); colorbar; title(ttl);
end

setenv('PATH', ['C:\Netgen\bin;' getenv('PATH')]);
eidors_debug off call_netgen

%% Parameter
e0 = 8.854e-12;  f = 500e3;  w = 2*pi*f;  Vexc = 1;
adm = @(sig, er) sig + 1i*w*e0*er;
n_elec = 16;  R = 0.09;  w_el = 0.026;           % radius tank konduktif, lebar elektroda (m)
t_ins = 0.003;  er_ins = 9;  sig_ins = 1e-9;     % 3 mm, er 9 ~ setara 1 mm, er 3
z_el  = 0.01;                                    % Ohm.m^2, kontak elektroda (kecil)
Rf = 10e3;  SNR = 100;                           % TIA ideal; SNR terhadap max|dI| (Inf = tanpa noise)
alpha_rel = 1e-2;                                % regularisasi (relatif), tala manual
phantom = 1;                                     % 1 = lingkaran besar dekat elektroda 2 | 2 = paru + jantung
a_rad = 0.056;  a_r = 0.022;                     % phantom 1: jarak pusat, radius (m)

Ybg = adm(0.20, 78);  Yins = adm(sig_ins, er_ins);          % PLACEHOLDER material
Yanom = adm(0.67, 80);  Ylung = adm(0.05, 20);  Yheart = adm(0.67, 80);

%% 1. Forward: mesh tank + cincin insulator, anomali, peta GT
Rf_mesh = R + t_ins;
[fm, nodes, elems, xc, yc] = mesh_cc(Rf_mesh, 0.003, 0.0015, n_elec, w_el);
nE_f = size(elems,1);
ring = hypot(xc,yc) >= R;
if sum(ring) < 50, error('Cincin insulator hanya %d elemen.', sum(ring)); end
for i = 1:n_elec, fm.electrode(i).z_contact = z_el; end
[ec, wspan] = elec_geom_cc(fm, nodes, Rf_mesh);

if phantom == 1
    aj = atan2(ec(2,2), ec(2,1));  xa = a_rad*cos(aj);  ya = a_rad*sin(aj);
    reg  = {@(px,py) hypot(px-xa, py-ya) < a_r};
    Yreg = {Yanom};
else
    s = R/0.15;
    reg  = {@(px,py) ((px+0.07*s)/(0.04*s)).^2 + (py/(0.07*s)).^2 < 1, ...
            @(px,py) ((px-0.07*s)/(0.04*s)).^2 + (py/(0.07*s)).^2 < 1, ...
            @(px,py) px.^2 + (py-0.01*s).^2 < (0.03*s)^2};
    Yreg = {Ylung, Ylung, Yheart};
end

Y_h = Ybg * ones(nE_f,1);  Y_i = Y_h;
for k = 1:numel(reg)
    Y_i = Y_i + frac_inside_cc(nodes, elems, reg{k}) * (Yreg{k} - Ybg);
end
Y_h(ring) = Yins;  Y_i(ring) = Yins;

lm = [-1 1 -1 1] * (R + t_ins + 0.012);
figure('Position', [60 80 600 520]);
draw_map_cc(nodes, elems, real(Y_i), [0 0.8], 'GT: konduktivitas \sigma (S/m)', ec, wspan, Rf_mesh, 0.004, lm, R);

%% 2. Forward: pengukuran semua pasangan i<j, arus -> TIA -> demodulator
clear stim
nd = n_elec*(n_elec-1)/2;  pairs = zeros(nd,2);  p = 0;
for i = 1:n_elec-1
    for j = i+1:n_elec
        p = p + 1;  pairs(p,:) = [i j];
        sp = zeros(n_elec,1);  sp(i) = 1;  sp(j) = -1;
        stim(p).stimulation  = 'Amps';
        stim(p).stim_pattern = sp;           % solve dengan arus 1 A; arus pada 1 V = Vexc/Z (model linear)
        stim(p).meas_pattern = sp';          % V_i - V_j
    end
end
fm.stimulation = stim;
img = mk_image(fm, 1);
img.elem_data = Y_h;  Z_h = fwd_solve(img).meas;
img.elem_data = Y_i;  Z_i = fwd_solve(img).meas;
fprintf('Pengukuran: %d | kompleks: %d\n', numel(Z_i), ~isreal(Z_i));

I_h = Vexc ./ Z_h;  I_i = Vexc ./ Z_i;
Vtia_h = -Rf * I_h;  Vtia_i = -Rf * I_i;     % demodulator I/Q: riil = real(Vtia), imajiner = imag(Vtia)

%% 3. Simpan CSV data pengukuran (keluaran demodulator, tanpa noise)
outdir = fullfile(pwd, 'hasil_cceit');
if ~exist(outdir, 'dir'), mkdir(outdir); end
fn  = fullfile(outdir, 'cceit_data.csv');
fid = fopen(fn, 'w');
if fid < 0                                   % cadangan: folder temp
    fn  = fullfile(tempdir, 'cceit_data.csv');
    fid = fopen(fn, 'w');
end
if fid < 0
    error('Tidak bisa menulis CSV. Tutup cceit_data.csv kalau terbuka di Excel, dan pastikan %s bisa ditulis.', pwd);
end
fprintf(fid, 'exc,meas,Re_Vtia_homog,Im_Vtia_homog,Re_Vtia_anomali,Im_Vtia_anomali\n');
for k = 1:nd
    fprintf(fid, '%d,%d,%.12e,%.12e,%.12e,%.12e\n', pairs(k,1), pairs(k,2), ...
        real(Vtia_h(k)), imag(Vtia_h(k)), real(Vtia_i(k)), imag(Vtia_i(k)));
end
fclose(fid);
fprintf('CSV tersimpan: %s (Rf = %g Ohm, arus = -Vtia/Rf)\n', fn, Rf);

%% 4. Inverse: mesh kasar, insulator lumped (z_contact kapasitif), dikalibrasi ke data homogen
[fi, nodes_i, elems_i, xi, yi] = mesh_cc(R, 0.010, 0.004, n_elec, w_el);
nE = size(elems_i,1);
[ec_i, wspan_i] = elec_geom_cc(fi, nodes_i, R);
fi.stimulation = stim;
z_c0 = t_ins / (1i*w*e0*er_ins);
for i = 1:n_elec, fi.electrode(i).z_contact = z_c0; end
kappa = mean(imag(Z_h)) / mean(imag(fwd_solve(mk_image(fi, Ybg)).meas));
for i = 1:n_elec, fi.electrode(i).z_contact = kappa * z_c0; end
img0 = mk_image(fi, Ybg);
fprintf('Mesh inverse: %d elemen | faktor kalibrasi = %.3f\n', nE, kappa);

dY_true = zeros(nE,1);
for k = 1:numel(reg)
    dY_true = dY_true + frac_inside_cc(nodes_i, elems_i, reg{k}) * (Yreg{k} - Ybg);
end

J = calc_jacobian(img0);                     % kompleks, nd x nE
[~, kc] = min(hypot(xi-0.03, yi-0.02));
dp = 1e-3 * Ybg;  ip = img0;  ip.elem_data(kc) = ip.elem_data(kc) + dp;
err_fd = norm((fwd_solve(ip).meas - fwd_solve(img0).meas)/dp - J(:,kc)) / norm(J(:,kc));
fprintf('Galat Jacobian vs finite difference: %.2e\n', err_fd);
if err_fd > 5e-2, warning('Jacobian tidak cocok dengan finite difference, hasil rekonstruksi meragukan'); end

%% 5. Data difference (noise di domain arus) dan solve NOSER/Kotre
randn('state', 1);
sig_n = max(abs(I_i - I_h)) / SNR;
cn = @(v) sig_n/sqrt(2) * (randn(size(v)) + 1i*randn(size(v)));
dZ = Vexc./(I_i + cn(I_i)) - Vexc./(I_h + cn(I_h));

dg   = sum(abs(J).^2, 1).';                  % diag(J'*J)
Rd   = dg.^0.5;  Rd = Rd * mean(dg)/mean(Rd);
Rinv = 1 ./ Rd;
Jh   = J';
A    = J * (Rinv .* Jh);
dY   = (Rinv .* Jh) * ((A + alpha_rel*real(trace(A))/nd*eye(nd)) \ dZ);

%% 6. Gambar rekonstruksi
figure('Position', [100 100 1350 450]);
subplot(1,3,1);
cl = max(abs(real(dY_true))) + eps;
draw_map_cc(nodes_i, elems_i, real(dY_true), [-cl cl], 'GT: \Delta\sigma (S/m)', ec_i, wspan_i, R, 0.004, lm, 0);
subplot(1,3,2);
cl = max(abs(real(dY))) + eps;
draw_map_cc(nodes_i, elems_i, real(dY), [-cl cl], 'Rekonstruksi: \Delta\sigma (skala per panel)', ec_i, wspan_i, R, 0.004, lm, 0);
subplot(1,3,3);
cl = max(abs(imag(dY)/(w*e0))) + eps;
draw_map_cc(nodes_i, elems_i, imag(dY)/(w*e0), [-cl cl], 'Rekonstruksi: \Delta\epsilon_r (skala per panel)', ec_i, wspan_i, R, 0.004, lm, 0);
