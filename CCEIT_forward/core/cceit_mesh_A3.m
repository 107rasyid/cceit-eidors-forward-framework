function [fmdl, info] = cceit_mesh_A3(P)
% CCEIT_MESH_A3 Build the circular contact-impedance model with refined medium.
% Purpose: generate Model A3 with finer medium mesh to improve accuracy.
% Inputs: P, shared model and mesh parameters in SI units. Optional fields
%         mesh_h_int_A3 and mesh_h_el_A3 override the mesh sizes for a
%         convergence study; normal model runs retain the configured defaults.
% Outputs: fmdl and mesh information including realized electrode arcs.
% Manuscript ref: Section II.C, circular Model A geometry with refined mesh.

setenv('PATH', [P.netgen_bin ';' getenv('PATH')]);
eidors_debug off call_netgen

if P.w_el >= 2*P.R
    error('cceit_mesh_A3: electrode width must be smaller than the phantom diameter');
end

% EIDORS writes Netgen geometry coordinates with three decimal places.
% Building directly in metres rounds a 53 mm phantom in 1 mm steps, which
% makes nominally identical electrode arcs depend on their angular position.
% Unit-radius coordinates reduce that quantization to about 0.05 mm here.
radius_unit = 1;
electrode_angles_deg = (0:P.nElec-1)'*(360/P.nElec);
electrode_positions = [electrode_angles_deg, zeros(P.nElec,1)];
% Keep normal Model A3 calls bit-for-bit on the same geometry settings. The
% explicit overrides let the mesh study vary resolution without changing the
% production model parameters used by verification and parameter sweeps.
h_medium = P.h_int_A3;
h_electrode = P.h_int_A3;
if isfield(P, 'mesh_h_int_A3') && ~isempty(P.mesh_h_int_A3)
    h_medium = P.mesh_h_int_A3;
end
if isfield(P, 'mesh_h_el_A3') && ~isempty(P.mesh_h_el_A3)
    h_electrode = P.mesh_h_el_A3;
end
if ~isscalar(h_medium) || ~isfinite(h_medium) || h_medium <= 0 || ...
        ~isscalar(h_electrode) || ~isfinite(h_electrode) || h_electrode <= 0
    error('cceit_mesh_A3: mesh sizes must be positive finite scalars');
end

electrode_shape_unit = [P.w_el/P.R, 0, h_electrode/P.R];
fmdl = ng_mk_cyl_models([0, radius_unit, h_medium/P.R], ...
    electrode_positions, electrode_shape_unit);

if size(fmdl.elems,2) ~= 3
    error('cceit_mesh_A3: Netgen must return a triangular 2D mesh');
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
info.h_medium = h_medium;
info.h_electrode = h_electrode;
end
