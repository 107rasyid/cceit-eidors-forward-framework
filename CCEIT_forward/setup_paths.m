function project_root = setup_paths()
% SETUP_PATHS Add the project and external EIDORS folders to the search path.
% Purpose: make the reorganized project runnable from any current directory.
% Inputs: none; configures the local EIDORS and NETGEN installation paths.
% Outputs: project_root, the absolute CCEIT_forward directory.
% Manuscript ref: reproducible implementation setup for Sections II-IV.

project_root = fileparts(mfilename('fullpath'));
% Local workstation installs. Override these two values if either folder moves.
eidors_root = 'C:/Users/user/Documents/GitHub/eidors-v3.12';
netgen_bin = 'C:/Netgen/bin';
setenv('EIDORS_ROOT', eidors_root);
setenv('CCEIT_NETGEN_BIN', netgen_bin);

addpath(project_root);
addpath(fullfile(project_root, 'core'));
addpath(fullfile(project_root, 'scripts'));
addpath(fullfile(project_root, 'plots'));

startup_file = fullfile(eidors_root, 'startup.m');
if exist(startup_file, 'file') ~= 2
    error('setup_paths: EIDORS startup.m not found at configured path: %s', startup_file);
end
if exist('eidors_obj', 'file') ~= 2
    % EIDORS derives its installation root from pwd; call its startup function
    % from that directory instead of run(startup.m), which Octave can reject
    % for an absolute Windows path.
    previous_dir = pwd;
    addpath(eidors_root);
    try
        cd(eidors_root);
        eidors_startup();
        cd(previous_dir);
    catch startup_error
        cd(previous_dir);
        rethrow(startup_error);
    end
end

netgen_exe = fullfile(netgen_bin, 'netgen.exe');
if exist(netgen_exe, 'file') ~= 2
    error('setup_paths: netgen.exe not found at configured path: %s', netgen_exe);
end
end
