function cceit_run_stage(script_path)
% CCEIT_RUN_STAGE Execute one script in an isolated function workspace.
% Purpose: let run_all catch a failed script without its clear command
% erasing the run_all state.
% Inputs: script_path, absolute path to one project runner or plotting script.
% Outputs: none; script errors are propagated to the caller.
% Manuscript ref: orchestration of Sections IV.A-IV.D.

if exist(script_path, 'file') ~= 2
    error('cceit_run_stage: script not found: %s', script_path);
end
run(script_path);
end
