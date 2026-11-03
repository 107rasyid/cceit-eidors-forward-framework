function [I, U] = cceit_solve_pair(fmdl, gamma_elem, P, t, r)
% CCEIT_SOLVE_PAIR  Solve one directed voltage-driven electrode pair.
%
% Implements: Section III, voltage-driven pair excitation for reciprocity checks.
%
% Inputs:
%   fmdl       EIDORS forward model with electrode contact impedances
%   gamma_elem complex element admittivity [nElem x 1]
%   P          parameter struct containing nElec and Vtx
%   t, r       transmitter and grounded receiver electrode indices
%
% Outputs:
%   I          complex terminal current for each electrode [A/m depth]
%   U          EIDORS terminal measurements for this stimulation

n = P.nElec;
stim.stim_pattern = zeros(n,1);
stim.volt_pattern = zeros(n,1);
stim.stim_pattern([t r]) = NaN;
stim.volt_pattern(t) = P.Vtx;
stim.volt_pattern(r) = 0;
stim.meas_pattern = eye(n);
fmdl.stimulation = stim;
img = mk_image(fmdl, gamma_elem);
img.fwd_solve.get_all_meas  = 1;
img.fwd_solve.get_elec_curr = 1;
data = fwd_solve(img);
if ~isfield(data, 'elec_curr') || isempty(data.elec_curr)
  error('cceit_solve_pair: electrode currents unavailable; check EIDORS get_elec_curr support');
end
I = data.elec_curr(:,1);
U = data.meas(:,1);
end
