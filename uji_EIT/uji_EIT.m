setenv('PATH', ['C:\Netgen\bin;' getenv('PATH')]);

%% 1. Tank dan elektroda
n_elec = 16;
R      = 0.15;
fmdl = ng_mk_cyl_models([0, R, 0.004], [n_elec], [0.015, 0, 0.002]);

%% 2. Stimulasi dan contact impedance
[fmdl.stimulation, fmdl.meas_select] = mk_stim_patterns( ...
    n_elec, 1, '{ad}', '{ad}', {'no_meas_current'}, 1e-3);

for i = 1:n_elec
    fmdl.electrode(i).z_contact = 0.01;
end

%% 3. Material dan anomali
img_h = mk_image(fmdl, 0.2);          % homogen (S/m)
img   = img_h;                        % salinan untuk ditambah anomali

% titik tengah tiap elemen
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

img.elem_data(lung_L) = 0.15;
img.elem_data(lung_R) = 0.15;
img.elem_data(heart)  = 0.67;

fprintf('Elemen total: %d | paru kiri: %d | paru kanan: %d | jantung: %d\n', ...
    numel(x), sum(lung_L), sum(lung_R), sum(heart));

figure; show_fem(img, [1 1]);
title('Model dengan anomali');

%% 4. Forward solve
vh = fwd_solve(img_h);
vi = fwd_solve(img);

v_homog = vh.meas;
v_inhom = vi.meas;
fprintf('Ukuran data: %d x %d (harus 208 x 1)\n', size(v_inhom));

figure; plot(v_homog, 'b'); hold on; plot(v_inhom, 'r');
legend('homogen', 'dengan anomali'); xlabel('indeks pengukuran'); ylabel('tegangan (V)');

%% 5. Simpan data
% CSV: buka di Excel atau baca di pyEIT/Colab
dlmwrite('v_homog.csv', v_homog, 'precision', '%.10e');
dlmwrite('v_inhom.csv', v_inhom, 'precision', '%.10e');

% Semua sekaligus dalam satu file (untuk dipakai lagi di Octave)
save('-mat', 'data_eit.mat', 'v_homog', 'v_inhom');

disp(['Tersimpan di: ' pwd]);

%% 6. Rekonstruksi
% Mesh kasar untuk inverse
fmdl_inv = ng_mk_cyl_models([0, R, 0.012], [n_elec], [0.015, 0, 0.004]);
fmdl_inv.stimulation = fmdl.stimulation;
fmdl_inv.meas_select = fmdl.meas_select;
for i = 1:n_elec
    fmdl_inv.electrode(i).z_contact = 0.01;
end

imdl = eidors_obj('inv_model', 'jac_noser');
imdl.fwd_model = fmdl_inv;
imdl.solve = @inv_solve_diff_GN_one_step;     % satu langkah Gauss-Newton
imdl.RtR_prior = @prior_noser;
imdl.prior_noser.exponent = 0.5;              % p pada diag(J'J)^p
imdl.jacobian_bkgnd.value = 0.2;              % samakan dengan background
imdl.hyperparameter.value = 1e-3;             % lambda, perlu ditala
imdl.reconstruction_type = 'difference';

img_rec = inv_solve(imdl, vh, vi);

figure; show_fem(img_rec, [1 1]);
title('Rekonstruksi NOSER/Kotre, lambda = 1e-3');
