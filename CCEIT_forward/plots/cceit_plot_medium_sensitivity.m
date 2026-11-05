function output_paths = cceit_plot_medium_sensitivity(P0, R, outdir, dpi)
% CCEIT_PLOT_MEDIUM_SENSITIVITY Plot Delta_p against medium properties.
% Purpose: show conductivity and permittivity sweeps at each frequency.
% Inputs: P0 baseline parameters, R A3 results, output folder, PNG dpi.
% Outputs: one 4-by-2 PNG containing both medium sweeps at all frequencies.
% Manuscript ref: Section IV.D, Model A medium-parameter sensitivity.

if isempty(R) || ~isfield(R, 'Delta_p_sig') || ~isfield(R, 'Delta_p_eps')
    error('cceit_plot_medium_sensitivity: incomplete A3 sweep results');
end
d_values = unique([R.d]);
f_values = unique([R.f]);
colors = lines(numel(d_values));
markers = {'o','s','^','d','v','>'};
fig = figure('Name', 'Medium sensitivity', 'Units', 'pixels', ...
    'Position', [40 30 1550 1750], 'Color', 'w', 'PaperPositionMode', 'auto');
legend_handles = cell(1, numel(d_values));
legend_labels = cell(1, numel(d_values));

% Manual axes positions leave clear room for panel titles, labels, and a shared
% legend. The baseline is intentionally omitted: each plotted point is a
% perturbed value, so the figure communicates nonzero changes directly.
lefts = [0.09 0.56];
width = 0.37;
height = 0.145;
bottoms = [0.755 0.55 0.345 0.14];

for fi = 1:numel(f_values)
    ax_sigma = axes('Parent', fig, 'Position', ...
        [lefts(1), bottoms(fi), width, height]);
    hold(ax_sigma, 'on'); grid(ax_sigma, 'on'); box(ax_sigma, 'on');
    ax_eps = axes('Parent', fig, 'Position', ...
        [lefts(2), bottoms(fi), width, height]);
    hold(ax_eps, 'on'); grid(ax_eps, 'on'); box(ax_eps, 'on');

    for di = 1:numel(d_values)
        idx = find(abs([R.d]-d_values(di)) < 1e-12 & ...
            abs([R.f]-f_values(fi)) < 1e-6, 1);
        if isempty(idx), continue; end

        sig_x = R(idx).sig_vals(:);
        sig_y = R(idx).Delta_p_sig(:);
        [sig_x, order] = sort(sig_x);
        sig_y = sig_y(order);
        marker = markers{1 + mod(di-1, numel(markers))};
        h = semilogx(ax_sigma, sig_x, sig_y, ['-' marker], ...
            'Color', colors(di,:), 'MarkerFaceColor', 'w', ...
            'MarkerSize', 6, 'LineWidth', 1.6);

        eps_x = R(idx).eps_vals(:);
        eps_y = R(idx).Delta_p_eps(:);
        [eps_x, order] = sort(eps_x);
        eps_y = eps_y(order);
        semilogx(ax_eps, eps_x, eps_y, ['-' marker], ...
            'Color', colors(di,:), 'MarkerFaceColor', 'w', ...
            'MarkerSize', 6, 'LineWidth', 1.6);

        if fi == 1
            legend_handles{di} = h;
            legend_labels{di} = sprintf('d = %.1f mm', d_values(di)*1e3);
        end
    end

    set([ax_sigma ax_eps], 'FontSize', 10, 'LineWidth', 0.9);
    xlabel(ax_sigma, 'Tissue conductivity (S/m)');
    ylabel(ax_sigma, 'Delta_p');
    title(ax_sigma, sprintf('Delta_p vs. conductivity, f = %.0f kHz', ...
        f_values(fi)/1e3), 'FontSize', 12);
    xlabel(ax_eps, 'Tissue relative permittivity');
    ylabel(ax_eps, 'Delta_p');
    title(ax_eps, sprintf('Delta_p vs. permittivity, f = %.0f kHz', ...
        f_values(fi)/1e3), 'FontSize', 12);
end

have_legend = ~cellfun(@isempty, legend_handles);
if any(have_legend)
    % Draw the shared key as figure annotations. Octave 11 raises an error
    % while deleting manually positioned legend objects during close().
    visible_items = find(have_legend);
    n_items = numel(visible_items);
    item_width = 0.72 / n_items;
    first_x = (1 - 0.72) / 2;
    for li = 1:n_items
        di = visible_items(li);
        x0 = first_x + (li-1)*item_width;
        y0 = 0.955;
        annotation(fig, 'line', [x0 x0+0.035], [y0 y0], ...
            'Color', colors(di,:), 'LineWidth', 1.8);
        annotation(fig, 'textbox', [x0+0.042 y0-0.012 item_width-0.045 0.025], ...
            'String', legend_labels{di}, 'EdgeColor', 'none', ...
            'FontSize', 10, 'VerticalAlignment', 'middle');
    end
end

output_paths = {fullfile(outdir, 'fig4c_tissue.png')};
print(fig, '-dpng', sprintf('-r%d', dpi), output_paths{1});
close(fig);
fprintf('Saved medium sensitivity figure: %s\n', output_paths{1});
end
