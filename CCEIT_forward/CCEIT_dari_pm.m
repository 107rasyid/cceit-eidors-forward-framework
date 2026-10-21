% cc_eit_16_electrode.m
% Requires EIDORS on the MATLAB path.
% If needed, run EIDORS startup first:
% run('/path/to/eidors/startup.m');

clear; close all; clc;

%% Model
nElec = 16;
sigma = 1.0;        % Homogeneous conductivity [S/m]
Vtx   = 1.0;        % Transmitter voltage [V]
tx    = 1;          % Transmitter electrode
rx    = 9;          % Return/reference electrode for single_return mode

% c2C2: circular 2D model with complete-electrode-model electrodes.
imdl = mk_common_model('c2C2', nElec);
fmdl = imdl.fwd_model;

% Starter contact impedance. In a 2D model, EIDORS uses Ohm*m.
% Replace this with a value calibrated for your interface and geometry.
zc = 0.01;
for e = 1:nElec
    fmdl.electrode(e).z_contact = zc;
end

%% Choose the electrical connection
% 'single_return': one voltage source, one return, other electrodes open
%                   circuit (high-impedance voltage sensing).
% 'common_ground':  electrode 1 at Vtx; all other electrodes at 0 V,
%                   so their individual currents can be read.
drive_mode = 'single_return';

stim.stim_pattern = zeros(nElec,1);
stim.volt_pattern = zeros(nElec,1);

switch drive_mode
    case 'single_return'
        voltage_electrodes = [tx; rx];
        prescribed_voltage = [Vtx; 0];

    case 'common_ground'
        voltage_electrodes = (1:nElec)';
        prescribed_voltage = zeros(nElec,1);
        prescribed_voltage(tx) = Vtx;

    otherwise
        error('Unknown drive_mode.');
end

% NaN marks electrodes whose voltages are prescribed.
% Other electrodes have the specified current (zero here).
stim.stim_pattern(voltage_electrodes) = NaN;
stim.volt_pattern(voltage_electrodes) = prescribed_voltage;

% Record each electrode terminal voltage.
stim.meas_pattern = speye(nElec);
fmdl.stimulation = stim;

%% Forward solve
img = mk_image(fmdl, sigma);
img.fwd_solve.get_all_meas = 1;  % Return FEM-node voltages
img.fwd_solve.get_elec_curr = 1; % Return current on each electrode
vh = fwd_solve(img);

Velec = vh.meas(:);
Ielec = vh.elec_curr(:,1);
Vnodes = vh.volt(1:num_nodes(img),1);

fprintf('Drive mode: %s\n', drive_mode);
fprintf('Transmitter electrode %d: %.4g V\n', tx, Vtx);
fprintf('Sum of electrode currents: %.6g\n', sum(Ielec));

%% Plot voltage in the circular domain
imgV = rmfield(img, 'elem_data');
imgV.node_data = Vnodes;

figure('Name','Voltage distribution');
show_fem(imgV);
axis equal tight;
colorbar;
title('Domain voltage distribution');

%% Plot current-density vectors over the voltage field
figure('Name','Current-density distribution');
show_fem(imgV);
hold on;
q = show_current(img, Vnodes);
quiver(q.xp, q.yp, q.xc, q.yc, 15, 'k', 'LineWidth', 1);
axis equal tight;
title('Current-density vectors');

%% Plot electrode terminal readings
figure('Name','Electrode measurements');

subplot(2,1,1);
stem(1:nElec, real(Velec), 'filled');
grid on;
xlim([1 nElec]);
xlabel('Electrode number');
ylabel('Voltage (V)');
title('Electrode terminal voltages');

subplot(2,1,2);
stem(1:nElec, real(Ielec), 'filled');
grid on;
xlim([1 nElec]);
xlabel('Electrode number');
ylabel('Current (EIDORS sign convention)');
title('Electrode currents');
