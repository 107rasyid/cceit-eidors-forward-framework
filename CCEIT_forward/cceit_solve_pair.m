function [I, U] = cceit_solve_pair(fmdl, gamma_elem, P, t, r)
% Satu solve: t = Vtx, r = 0 V, lainnya floating.
n = P.nElec;
stim.stim_pattern = zeros(n,1);
stim.volt_pattern = zeros(n,1);
stim.stim_pattern([t r]) = NaN;
stim.volt_pattern(t) = P.Vtx;
stim.volt_pattern(r) = 0;
stim.meas_pattern = speye(n);
fmdl.stimulation = stim;
img = mk_image(fmdl, gamma_elem);
img.fwd_solve.get_all_meas  = 1;
img.fwd_solve.get_elec_curr = 1;
data = fwd_solve(img);
I = data.elec_curr(:,1);
U = data.meas(:,1);
end
