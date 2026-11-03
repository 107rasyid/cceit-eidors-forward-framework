function report = run_all()
% RUN_ALL Run the forward-model study stages and record each stage status.
% Purpose: provide one repeatable entry point for verification, comparison,
% parameter sweeps, summaries, and figures.
% Inputs: none; uses the active A2/B5 workflow and current sweep parameters.
% Outputs: report struct with stage names, statuses, and messages.
% Manuscript ref: Sections IV.A-IV.D.

project_root = fileparts(mfilename('fullpath'));
outdir = fullfile(project_root, 'results');
if exist(outdir, 'dir') ~= 7
    mkdir(outdir);
end
log_path = fullfile(outdir, 'run_all_log.txt');
console_csv_path = fullfile(outdir, 'run_all_console.csv');
log_id = fopen(log_path, 'w');
if log_id < 0
    error('run_all: cannot create stage log: %s', log_path);
end
log_cleanup = onCleanup(@() fclose(log_id));
console_csv_id = fopen(console_csv_path, 'w');
if console_csv_id < 0
    error('run_all: cannot create console CSV: %s', console_csv_path);
end
fprintf(console_csv_id, 'stage,status,start_time,end_time,message,console_output\n');
fprintf(log_id, 'CC-EIT run_all started: %s\n', datestr(now));

% Capture initialization too: path/configuration errors happen before any
% workflow stage and must still be recoverable from the saved run log.
preflight_path = fullfile(outdir, 'run_all_preflight_console.tmp');
if exist(preflight_path, 'file') == 2
    delete(preflight_path);
end
preflight_start = datestr(now);
diary(preflight_path);
fprintf('START setup_paths and cceit_params\n');
try
    setup_paths();
    P = cceit_params();
    preflight_status = 'completed';
    preflight_message = '';
    fprintf('DONE setup_paths and cceit_params\n');
catch preflight_error
    preflight_status = 'failed';
    preflight_message = preflight_error.message;
    fprintf(2, 'FAIL setup_paths and cceit_params: %s\n', preflight_message);
end
diary off;
preflight_end = datestr(now);
preflight_output = '';
if exist(preflight_path, 'file') == 2
    preflight_output = fileread(preflight_path);
    delete(preflight_path);
end
fprintf(console_csv_id, '"%s","%s","%s","%s","%s","%s"\n', ...
    'setup_paths+cceit_params', preflight_status, preflight_start, ...
    preflight_end, strrep(preflight_message, '"', '""'), ...
    strrep(preflight_output, '"', '""'));
if strcmp(preflight_status, 'failed')
    fprintf(log_id, 'FAIL setup_paths and cceit_params: %s\n', preflight_message);
    fclose(console_csv_id);
    rethrow(preflight_error);
end

stage_names = {'run_verify_models', 'run_AB_A2_B5_coarse', ...
    'run_B5_resolution_study', 'run_sweepA', 'run_sweepA2', 'run_sweepA3', ...
    'summary_sweeps', 'plot_results', 'plot_AB_pair_admittance_current', ...
    'plot_mesh_AB'};
stage_dirs = {'scripts', 'scripts', 'scripts', 'scripts', 'scripts', ...
    'scripts', 'plots', 'plots', 'plots', 'plots'};
report = repmat(struct('name', '', 'status', '', 'message', ''), ...
    numel(stage_names), 1);

for k = 1:numel(stage_names)
    report(k).name = stage_names{k};
    stage_path = fullfile(project_root, stage_dirs{k}, ...
        [stage_names{k} '.m']);
    capture_path = fullfile(P.outdir, [stage_names{k} '_console.tmp']);
    if exist(capture_path, 'file') == 2
        delete(capture_path);
    end
    stage_start = datestr(now);
    diary(capture_path);
    fprintf('START %s\n', stage_names{k});
    try
        cceit_run_stage(stage_path);
        report(k).status = 'completed';
        report(k).message = '';
        fprintf('DONE  %s\n', stage_names{k});
        fprintf(log_id, 'DONE  %s\n', stage_names{k});
    catch stage_error
        report(k).status = 'failed';
        report(k).message = stage_error.message;
        fprintf(2, 'FAIL  %s: %s\n', stage_names{k}, stage_error.message);
        fprintf(log_id, 'FAIL  %s: %s\n', stage_names{k}, stage_error.message);
    end
    diary off;
    stage_end = datestr(now);
    output_text = '';
    if exist(capture_path, 'file') == 2
        output_text = fileread(capture_path);
        delete(capture_path);
    end
    fprintf(console_csv_id, '"%s","%s","%s","%s","%s","%s"\n', ...
        stage_names{k}, report(k).status, stage_start, stage_end, ...
        strrep(report(k).message, '"', '""'), ...
        strrep(output_text, '"', '""'));
end

fprintf(log_id, 'CC-EIT run_all finished: %s\n', datestr(now));
fclose(console_csv_id);
fprintf('Stage log: %s\n', log_path);
fprintf('Stage console CSV: %s\n', console_csv_path);
end
