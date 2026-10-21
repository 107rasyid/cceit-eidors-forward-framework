setenv('PATH', ['C:\Netgen\bin;' getenv('PATH')]);

%% 0. Parameter fisik
f    = 500e3;   w = 2*pi*f;   e0 = 8.854e-12;
Vexc = 1;                               % V

t_ins  = 1e-3;                          % tebal insulating layer (m)
er_ins = 3;                             % permitivitas relatif insulator
z_c    = t_ins / (1i*w*e0*er_ins);      % Ohm.m^2 (kopling kapasitif)

adm = @(sig, er) sig + 1i*w*e0*er;      % admitivitas kompleks
% PLACEHOLDER: ganti dengan nilai material dari COMSOL/ANSYS-mu
Y_bg    = adm(0.20, 78);
Y_lung  = adm(0.05, 20);
Y_heart = adm(0.67, 80);

%% 1. Tank dan 12 elektroda
n_elec = 12;  R = 0.15;
fmdl = ng_mk_cyl_models([0, R, 0.004], [n_elec], [0.015, 0, 0.002]);
for i = 1:n_elec
    fmdl.electrode(i).z_contact = z_c;
end

%% 2. Pola: 1-2..1-12, 2-3..2-12, ... 11-12 (66 pasang)
clear stim
p = 0;
for i = 1:n_elec-1
  for j = i+1:n_elec
    p = p + 1;
    sp = zeros(n_elec,1);  sp(i) = 1;  sp(j) = -1;
    stim(p).stimulation  = 'Amps';
    stim(p).stim_pattern = sp;      % injeksi di i, tarik di j
    stim(p).meas_pattern = sp';     % ukur V_i - V_j
  end
end
fmdl.stimulation = stim;

%% 3. Material dan anomali
img_h = mk_image(fmdl, Y_bg);
img   = img_h;

nodes = fmdl.nodes;  elems = fmdl.elems;
ctr = zeros(size(elems,1), size(nodes,2));
for k = 1:size(elems,2)
    ctr = ctr + nodes(elems(:,k), :);
end
ctr = ctr / size(elems,2);
x = ctr(:,1);  y = ctr(:,2);

lung_L = ((x+0.07)/0.04).^2 + (y/0.07).^2 < 1;
lung_R = ((x-0.07)/0.04).^2 + (y/0.07).^2 < 1;
heart  = (x.^2 + (y-0.01).^2) < 0.03^2;

img.elem_data(lung_L) = Y_lung;
img.elem_data(lung_R) = Y_lung;
img.elem_data(heart)  = Y_heart;
fprintf('Elemen: %d | paru L: %d | paru R: %d | jantung: %d\n', ...
    numel(x), sum(lung_L), sum(lung_R), sum(heart));

%% 4. Forward: impedansi dua-terminal tiap pasang
Z_h = fwd_solve(img_h).meas;
Z_i = fwd_solve(img).meas;
fprintf('Jumlah pengukuran: %d (harus 66), data kompleks: %d\n', ...
    numel(Z_i), ~isreal(Z_i));

%% 5. Arus ke TIA, lalu (opsional) TIA ideal + demodulator I/Q
I_h = Vexc ./ Z_h;
I_i = Vexc ./ Z_i;

Rf = 10e3;                               % contoh
Vtia_h = -Rf * I_h;   Vtia_i = -Rf * I_i;
Vre_h = real(Vtia_h); Vim_h = imag(Vtia_h);   % keluaran demodulator
Vre_i = real(Vtia_i); Vim_i = imag(Vtia_i);

%% 6. Cek kewajaran
Z_cap = 2*z_c/0.015;                     % dua kapasitor seri, lebar elektroda 15 mm
fprintf('Im(Z) rata-rata = %.1f | perkiraan kapasitif = %.1f\n', ...
    mean(imag(Z_h)), imag(Z_cap));
fprintf('Re(Z) rata-rata = %.2f\n', mean(real(Z_h)));
fprintf('Perubahan relatif: Re %.2e | Im %.2e\n', ...
    max(abs(real(Z_i-Z_h)))/mean(abs(real(Z_h))), ...
    max(abs(imag(Z_i-Z_h)))/mean(abs(imag(Z_h))));

figure; show_fem(img, [1 0]); title('Geometri (bagian riil)');
figure;
subplot(2,1,1); plot(real(I_i-I_h)); ylabel('\Delta Re(I)'); xlabel('pengukuran');
subplot(2,1,2); plot(imag(I_i-I_h)); ylabel('\Delta Im(I)'); xlabel('pengukuran');

%% 7. Simpan
% kolom: Re(I_h) Im(I_h) Re(I_i) Im(I_i)
dlmwrite('cceit_data.csv', [real(I_h) imag(I_h) real(I_i) imag(I_i)], ...
         'precision', '%.12e');
save('-mat', 'cceit_data.mat', 'I_h', 'I_i', 'Z_h', 'Z_i', 'Vexc', 'f');

%% 8. Model inverse (mesh kasar)
fmdl_inv = ng_mk_cyl_models([0, R, 0.015], [n_elec], [0.015, 0, 0.005]);
for i = 1:n_elec
    fmdl_inv.electrode(i).z_contact = z_c;
end
fmdl_inv.stimulation = stim;                 % pola 66 pasang yang sama
img_inv0 = mk_image(fmdl_inv, Y_bg);
nE = size(fmdl_inv.elems, 1);

% titik tengah elemen mesh inverse
ctr_inv = zeros(nE, size(fmdl_inv.nodes,2));
for k = 1:size(fmdl_inv.elems,2)
    ctr_inv = ctr_inv + fmdl_inv.nodes(fmdl_inv.elems(:,k), :);
end
ctr_inv = ctr_inv / size(fmdl_inv.elems,2);
xi = ctr_inv(:,1);  yi = ctr_inv(:,2);

% kebenaran (ground truth) di mesh inverse, untuk perbandingan
dY_true = zeros(nE,1);
dY_true(((xi+0.07)/0.04).^2 + (yi/0.07).^2 < 1) = Y_lung  - Y_bg;
dY_true(((xi-0.07)/0.04).^2 + (yi/0.07).^2 < 1) = Y_lung  - Y_bg;
dY_true((xi.^2 + (yi-0.01).^2) < 0.03^2)         = Y_heart - Y_bg;

%% 9. Jacobian dan cek dengan finite difference
J = calc_jacobian(img_inv0);                 % nd x nE, harus kompleks
fprintf('J: %d x %d | kompleks: %d\n', size(J,1), size(J,2), ~isreal(J));

[~, kc] = min((xi-0.05).^2 + yi.^2);         % satu elemen untuk uji
dp  = 1e-3 * Y_bg;
img_p = img_inv0;  img_p.elem_data(kc) = img_p.elem_data(kc) + dp;
col_fd = (fwd_solve(img_p).meas - fwd_solve(img_inv0).meas) / dp;
fprintf('Galat relatif Jacobian vs finite difference: %.2e\n', ...
        norm(col_fd - J(:,kc)) / norm(J(:,kc)));

%% 10. Data (dengan noise di domain arus)
SNR = 100;                                   % terhadap max|dI|; Inf = tanpa noise
randn('state', 1);
sig_n = max(abs(I_i - I_h)) / SNR;
cn = @(v) sig_n/sqrt(2) * (randn(size(v)) + 1i*randn(size(v)));
I_hn = I_h + cn(I_h);   I_in = I_i + cn(I_i);
dZ = Vexc./I_in - Vexc./I_hn;                % data difference (kompleks)

%% 11. Regularisasi NOSER/Kotre dan solve
p    = 0.5;                                  % eksponen
d    = real(diag(J'*J));
Rd   = d.^p;  Rd = Rd * mean(d)/mean(Rd);    % samakan skala dengan J'J
Rinv = 1 ./ Rd;
Jh   = J';                                   % transpose konjugat
nd   = size(J,1);
solve_dY = @(alpha) (Rinv .* Jh) * ((J*(Rinv .* Jh) + alpha*eye(nd)) \ dZ);

alphas = [1e-3 1e-2 1e-1 1];
img_show = img_inv0;
figure;
subplot(2,3,1);
img_show.elem_data = real(dY_true); show_fem(img_show, 1); title('Truth: Re(dY)');
for a = 1:numel(alphas)
    dY = solve_dY(alphas(a));
    img_show.elem_data = real(dY);
    subplot(2,3,a+1); show_fem(img_show, 1);
    c = corrcoef(real(dY), real(dY_true));
    title(sprintf('alpha=%g | r=%.2f', alphas(a), c(1,2)));
end

%% 12. Pilih alpha terbaik, lihat bagian riil dan imajiner
alpha = 1e-2;                                % isi dari hasil scan di atas
dY = solve_dY(alpha);
figure;
img_show.elem_data = real(dY);            subplot(1,2,1); show_fem(img_show,1);
title('Re(dY) = \Delta\sigma (S/m)');
img_show.elem_data = imag(dY)/(w*e0);     subplot(1,2,2); show_fem(img_show,1);
title('Im(dY)/(\omega\epsilon_0) = \Delta\epsilon_r');

save('-mat', 'cceit_recon.mat', 'dY', 'dY_true', 'alpha', 'SNR');
