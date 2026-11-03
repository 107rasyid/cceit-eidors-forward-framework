function log_path = run_logged(script_name)
% RUN_LOGGED Run one project script and save its terminal output as text.
% Purpose: retain console output from a manually selected workflow stage.
% Inputs: script_name, a script filename or project-relative path.
% Outputs: log_path, the timestamped text log under results/.
% Manuscript ref: reproducibility records for Sections IV.A-IV.D.

project_root = fileparts(fileparts(mfilename('fullpath')));
setup_paths();

if isempty(regexp(script_name, '\.m$', 'once'))
    script_name = [script_name '.m'];
end
if exist(script_name, 'file') == 2
    script_path = script_name;
else
    candidates = {fullfile(project_root, 'scripts', script_name), ...
        fullfile(project_root, 'plots', script_name)};
    script_path = '';
    for k = 1:numel(candidates)
        if exist(candidates{k}, 'file') == 2
            script_path = candidates{k};
            break;
        end
    end
    if isempty(script_path)
        error('run_logged: script not found: %s', script_name);
    end
end

[~, stem] = fileparts(script_path);
stamp = datestr(now, 'yyyymmdd_HHMMSS');
log_path = fullfile(project_root, 'results', ...
    [stem '_console_' stamp '.txt']);
if exist(log_path, 'file') == 2
    error('run_logged: log already exists; wait one second and retry: %s', log_path);
end

diary(log_path);
fprintf('Running %s\nLog file: %s\nStarted: %s\n\n', ...
    script_path, log_path, datestr(now));
try
    cceit_run_stage(script_path);
    fprintf('\nCompleted: %s\n', datestr(now));
catch run_error
    fprintf(2, '\nFailed: %s\n', run_error.message);
    diary off;
    fprintf('Console output saved to: %s\n', log_path);
    rethrow(run_error);
end
diary off;
fprintf('Console output saved to: %s\n', log_path);
end
