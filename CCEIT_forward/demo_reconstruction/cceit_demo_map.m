function cceit_demo_map(nodes,elems,values,label_text,clim)
% CCEIT_DEMO_MAP Draw values stored per triangle on a mesh.
% Purpose: display ground truth or one reconstructed complex component.
% Inputs: nodes (N-by-2 coordinates), elems (M-by-3 triangle indices),
%         values (M values), label_text, and optional symmetric color limits.
% Outputs: adds the colored mesh, axes labels, title, and colorbar to gca.
% Manuscript ref: standalone educational reconstruction demonstration.
patch('Faces',elems,'Vertices',nodes,'FaceVertexCData',values, ...
    'FaceColor','flat','EdgeColor','none');
axis equal tight; colorbar; title(label_text); xlabel('x (m)'); ylabel('y (m)');
if nargin >= 5 && ~isempty(clim), caxis(clim); end
end
