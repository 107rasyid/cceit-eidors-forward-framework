function cceit_plot(P, fmdl, R, nElems, err_rel)
% CCEIT_PLOT  Semua figure hasil.

% --- Figure 1: receiver-current profile ---
figure('Name','Receiver current profile');
subplot(2,1,1);
bar(R.rx_list, abs(R.I_rx)); grid on;
xlabel('Receiver electrode'); ylabel('|I_{rx}| [A]');
title(sprintf('Receiver current | tx=%d, f=%.0f kHz', P.tx, P.freq_Hz(1)/1e3));

subplot(2,1,2);
bar(R.rx_list, angle(R.I_rx)*180/pi); grid on;
xlabel('Receiver electrode'); ylabel('Phase [deg]');
title('Receiver current phase');

% --- Figure 2: spatial voltage + current density ---
rx1 = R.rx_list(1);
V1  = R.V_nodes(:, 1);
imgV = mk_image(fmdl, 0);
imgV.node_data = real(V1);

figure('Name','Spatial fields');
subplot(1,2,1);
show_fem(imgV); axis equal tight; colorbar;
title(sprintf('Voltage | tx=%d, rx=%d', P.tx, rx1));

subplot(1,2,2);
imgC = mk_image(fmdl, P.sigma_bg);
hold on;
q = show_current(imgC, real(V1));
q_mag = hypot(q.xc, q.yc);
imgJ = mk_image(fmdl, log10(max(q_mag, realmin)));
show_fem(imgJ); hold on;
q_dir_x = q.xc ./ max(q_mag, realmin);
q_dir_y = q.yc ./ max(q_mag, realmin);
arrow_len = P.current_arrow_max_frac * P.radius_m;
quiver(q.xp, q.yp, arrow_len * q_dir_x, arrow_len * q_dir_y, 0, 'k');
axis equal tight;
colorbar;
title('log_{10}|J| [A/m^2] with direction arrows');

% --- Figure 3: mesh convergence ---
figure('Name','Mesh convergence');
semilogy(nElems(2:end), err_rel(2:end), 'o-', 'LineWidth', 1.5); grid on;
xlabel('Number of elements'); ylabel('Relative change in I_{rx}');
title('Mesh convergence');
end
