function [fmdl, info] = cceit_mesh_A(P)
% CCEIT_MESH_A Build the circular contact-impedance model.
% Purpose: generate Model A without meter-scale geometry rounding in Netgen.
% Inputs: P, shared model and mesh parameters in SI units.
% Outputs: fmdl and mesh information including realized electrode arcs.
% Manuscript ref: Section II.C, circular Model A geometry.

setenv('PATH', [P.netgen_bin ';' getenv('PATH')]);
eidors_debug off call_netgen

if P.w_el >= 2*P.R
    error('cceit_mesh_A: electrode width must be smaller than the phantom diameter');
end

% EIDORS writes Netgen geometry coordinates with three decimal places.
% Building directly in metres rounds a 53 mm phantom in 1 mm steps, which
% makes nominally identical electrode arcs depend on their angular position.
% Unit-radius coordinates reduce that quantization to about 0.05 mm here.
radius_unit = 1;
electrode_angles_deg = (0:P.nElec-1)'*(360/P.nElec);
electrode_positions = [electrode_angles_deg, zeros(P.nElec,1)];
electrode_shape_unit = [P.w_el/P.R, 0, P.h_el/P.R];
fmdl = ng_mk_cyl_models([0, radius_unit, P.h_int/P.R], ...
    electrode_positions, electrode_shape_unit);

if size(fmdl.elems,2) ~= 3
    error('cceit_mesh_A: Netgen must return a triangular 2D mesh');
end

% Return the model to SI units and place its circular boundary exactly at R.
fmdl.nodes = fmdl.nodes * (P.R / max(hypot(fmdl.nodes(:,1), fmdl.nodes(:,2))));

info.nNodes = size(fmdl.nodes,1);
info.nElems = size(fmdl.elems,1);
info.rmax = max(hypot(fmdl.nodes(:,1), fmdl.nodes(:,2)));
info.target_electrode_arc = 2*P.R*asin(P.w_el/(2*P.R));
info.electrode_arc = cceit_electrode_boundary_lengths(fmdl);
info.electrode_arc_max_rel_error = max(abs(info.electrode_arc - ...
    info.target_electrode_arc))/info.target_electrode_arc;
end
