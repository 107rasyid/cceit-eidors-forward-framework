function cceit_demo_map(nodes,elems,values,label_text,clim)
% CCEIT_DEMO_MAP Draw one element-wise reconstruction map.
% Purpose: render real or imaginary admittivity change on a triangular mesh.
% Inputs: node coordinates, triangles, values, colorbar label, color limits.
% Outputs: draws in the active axes.
% Manuscript ref: standalone educational reconstruction demonstration.
patch('Faces',elems,'Vertices',nodes,'FaceVertexCData',values, ...
    'FaceColor','flat','EdgeColor','none');
axis equal tight; colorbar; title(label_text); xlabel('x (m)'); ylabel('y (m)');
if nargin >= 5 && ~isempty(clim), caxis(clim); end
end
