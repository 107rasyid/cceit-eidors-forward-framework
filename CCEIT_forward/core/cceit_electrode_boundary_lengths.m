function arc_length = cceit_electrode_boundary_lengths(fmdl)
% CCEIT_ELECTRODE_BOUNDARY_LENGTHS Measure each CEM electrode's boundary arc.
% Purpose: quantify the actual 2D boundary represented by electrode nodes.
% Inputs: fmdl, a triangular 2D EIDORS forward model.
% Outputs: arc_length, boundary length in model units for each electrode.
% Manuscript ref: Section II.C, electrode geometry in the CEM.

if size(fmdl.elems,2) ~= 3
    error('cceit_electrode_boundary_lengths: expected triangular 2D elements');
end
element_edges = [fmdl.elems(:,[1 2]); fmdl.elems(:,[2 3]); ...
    fmdl.elems(:,[3 1])];
element_edges = sort(element_edges, 2);
[all_edges, ~, edge_group] = unique(element_edges, 'rows');
edge_count = accumarray(edge_group, 1);
boundary_edges = all_edges(edge_count == 1, :);
edge_length = sqrt(sum((fmdl.nodes(boundary_edges(:,1),:) - ...
    fmdl.nodes(boundary_edges(:,2),:)).^2, 2));

arc_length = zeros(numel(fmdl.electrode), 1);
for e = 1:numel(fmdl.electrode)
    node_ids = unique(fmdl.electrode(e).nodes(:));
    on_electrode = ismember(boundary_edges(:,1), node_ids) & ...
        ismember(boundary_edges(:,2), node_ids);
    arc_length(e) = sum(edge_length(on_electrode));
end
end
