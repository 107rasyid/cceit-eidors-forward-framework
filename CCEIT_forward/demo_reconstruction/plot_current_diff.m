% PLOT_CURRENT_DIFF Plot homogeneous and inclusion currents for saved cases.
% Purpose: inspect the 120-pair forward-current change before TIA processing.
% Inputs: results/reconstruction_demo/demo_run_status.mat from the demo script.
% Outputs: up to six PNGs, one per completed phantom/model case.
% Note: the demo calls this after saving its case status; run it alone to
%       redraw the current figures without repeating forward solves.
% Manuscript ref: standalone educational reconstruction demonstration.
project_root = setup_paths();
status_path = fullfile(project_root,'results','reconstruction_demo','demo_run_status.mat');
if exist(status_path,'file') ~= 2
    error('plot_current_diff: run demo_reconstruction.m first to create %s',status_path);
end
saved = load(status_path);
report = saved.report;

phantom_names = {'one_circle','two_circles_left_right','three_circles_triangle'};
model_names = {'A3','B6'};

% Load all cases
cases = {};
case_labels = {};
case_files = {};
for p = 1:3
    for m = 1:2
        if isstruct(report{p,m}) && isfield(report{p,m},'I_h')
            cases{end+1} = report{p,m};
            case_labels{end+1} = sprintf('%s - %s', model_names{m}, strrep(phantom_names{p}, '_', ' '));
            case_files{end+1} = sprintf('%s_%s', model_names{m}, phantom_names{p});
        end
    end
end

nCases = length(cases);

% Find global scale for real and imaginary based on actual data range
all_real = [];
all_imag = [];
for c = 1:nCases
    data = cases{c};
    all_real = [all_real; real(data.I_h); real(data.I_i)];
    all_imag = [all_imag; imag(data.I_h); imag(data.I_i)];
end
real_min = min(all_real);
real_max = max(all_real);
imag_min = min(all_imag);
imag_max = max(all_imag);

fprintf('Real range: [%.4g, %.4g] A, Imag range: [%.4g, %.4g] A\n', ...
    real_min, real_max, imag_min, imag_max);

% Create separate figure for each case
for c = 1:nCases
    data = cases{c};
    order = 1:length(data.I_h);

    fig = figure('visible','off','color','w','position',[100 100 1200 600]);

    % Real part: I_h vs I_i
    subplot(1,2,1);
    plot(order, real(data.I_h), 'b-', 'linewidth', 1.5); hold on;
    plot(order, real(data.I_i), 'r--', 'linewidth', 1.5);
    grid on;
    ylim([real_min real_max]);
    ylabel('Re(I) [A]', 'fontsize', 12);
    title(case_labels{c}, 'fontsize', 14);
    legend('Homogeneous','Inhomogeneous','location','northeast');
    xlabel('Pair index (acquisition order)', 'fontsize', 12);

    % Imaginary part: I_h vs I_i
    subplot(1,2,2);
    plot(order, imag(data.I_h), 'b-', 'linewidth', 1.5); hold on;
    plot(order, imag(data.I_i), 'r--', 'linewidth', 1.5);
    grid on;
    ylim([imag_min imag_max]);
    ylabel('Im(I) [A]', 'fontsize', 12);
    legend('Homogeneous','Inhomogeneous','location','northeast');
    xlabel('Pair index (acquisition order)', 'fontsize', 12);

    base = case_files{c};
    print(fig, fullfile(project_root,'results','reconstruction_demo',['current_response_' base '.png']), ...
        '-dpng', '-r150');
    close(fig);
    fprintf('Saved: current_response_%s.png\n', base);
end
