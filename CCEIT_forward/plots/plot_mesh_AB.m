% PLOT_MESH_AB Compare the A2 and locally refined B5 meshes.
% Implements: Section IV.B, mesh construction and explicit ring resolution.
clear; close all; clc;

P = cceit_params();
P.d = 2e-3;
eidors_cache clear
[fmdl_A, info_A] = cceit_mesh_A(P);
[fmdl_B, ring_B, info_B] = cceit_mesh_B5(P, P.h_ring_B);

fig = figure('Name', 'Model A/B mesh close-up', ...
    'Position', [80 80 1180 560], 'Color', 'w');
view_x = [P.R-0.012, P.R+P.d+0.004];
view_y = [-0.010, 0.010];

subplot(1, 2, 1);
show_fem(fmdl_A);
axis equal;
xlim(view_x); ylim(view_y);
set(gca, 'FontSize', 10, 'LineWidth', 0.8);
xlabel('x (m)'); ylabel('y (m)');
title(sprintf('Model A mesh (%d elements)', info_A.nElems));

subplot(1, 2, 2);
show_fem(fmdl_B);
hold on;
h_ring = patch('Faces', fmdl_B.elems(ring_B,:), ...
    'Vertices', fmdl_B.nodes(:,1:2), 'FaceColor', [0.96 0.66 0.20], ...
    'EdgeColor', [0.34 0.34 0.34], 'LineWidth', 0.25);
axis equal;
xlim(view_x); ylim(view_y);
set(gca, 'FontSize', 10, 'LineWidth', 0.8);
xlabel('x (m)'); ylabel('y (m)');
title(sprintf('Model B5, h_{ring}=%.2f mm (%d ring elements)', ...
    P.h_ring_B*1e3, info_B.nRing));
legend(h_ring, {'Explicit dielectric ring'}, 'Location', 'northeast');

meta = cceit_make_metadata(P);
png_path = fullfile(P.outdir, 'fig_mesh.png');
mesh_summary = struct('info_A', info_A, 'info_B', info_B, ...
    'nElems_medium_B', info_B.nElems-info_B.nRing, ...
    'nElems_ring_B', sum(ring_B(:)), 'd_m', P.d, 'h_ring_m', P.h_ring_B);
result_path = fullfile(P.outdir, 'fig_mesh.mat');
save(result_path, 'P', 'mesh_summary', 'meta');
if exist('OCTAVE_VERSION', 'builtin')
    try
        print('-dpng', sprintf('-r%d', P.plot_export_dpi), '-opengl', png_path);
    catch raster_error
        warning('plot_mesh_AB: OpenGL PNG export failed (%s); trying default renderer', ...
            raster_error.message);
        print('-dpng', sprintf('-r%d', P.plot_export_dpi), png_path);
    end
else
    print('-dpng', sprintf('-r%d', P.plot_export_dpi), png_path);
end
fprintf('Mesh figure: %s\nData: %s\n', png_path, result_path);
