% DEMO_RECONSTRUCTION Run a separate six-case reconstruction demonstration.
% Purpose: check that voltage-driven forward data can be carried through an
% ideal TIA model and a simple complex-Jacobian reconstruction example.
% Cases: one circle, two circles left/right, and three circles in a triangle;
%        each case uses active Model A3 and coarse Model B6 meshes.
% Outputs: one MAT and TIA CSV per case, six reconstruction PNGs, six
%          homogeneous/inclusion current PNGs, plus a status MAT under
%          results/reconstruction_demo/.
% Scope: educational verification only; this is not paper validation.
% Manuscript ref: supplementary workflow demonstration only.
clear; close all; clc;

%% Project setup and output folder
project_root = setup_paths();
addpath(fullfile(project_root,'demo_reconstruction'));
P = cceit_params();
outdir = fullfile(P.project_root,'results','reconstruction_demo');
if exist(outdir,'dir') ~= 7, mkdir(outdir); end
%% Run each phantom/model combination independently
% A case failure is recorded and does not prevent the remaining cases.
status_file = fullfile(outdir,'demo_run_status.mat');
if exist(status_file,'file'), delete(status_file); end
names = {'one_circle','two_circles_left_right','three_circles_triangle'};
report = cell(3,2);
for p = 1:3
    for m = 1:2
        try
            report{p,m} = cceit_demo_case(P,p,m,outdir);
            fprintf('DONE %s / %s\n',names{p},report{p,m}.model);
        catch err
            report{p,m} = struct('status','failed','message',err.message);
            fprintf(2,'FAIL %s / model %d: %s\n',names{p},m,err.message);
        end
    end
end

%% Plot ground truth and reconstructed complex components
% Each PNG shows truth, real reconstruction, and imaginary reconstruction.
model_names = {'A3','B6'};
for p = 1:3
    for m = 1:2
        data = report{p,m};
        if ~isstruct(data) || ~isfield(data,'dgamma_reconstruction')
            fprintf('Skip %s model %d: incomplete data\n',names{p},m);
            continue;
        end

        gt = real(data.delta_gamma_true);
        rec = data.dgamma_reconstruction;
        limGT = max(abs(gt(:)));
        limRec = max(abs([real(rec(:));imag(rec(:))]));
        if limGT == 0, limGT = 1; end
        if limRec == 0, limRec = 1; end

        fig = figure('visible','off','color','w','position',[100 100 1600 500]);

        subplot(1,3,1); cceit_demo_map(data.nodes,data.elements,gt, ...
            'Ground truth: \Delta\sigma (S/m)',[-limGT limGT]);

        subplot(1,3,2); cceit_demo_map(data.nodes,data.elements,real(rec), ...
            sprintf('%s: Re(\Delta\gamma) (S/m)',model_names{m}),[-limRec limRec]);

        subplot(1,3,3); cceit_demo_map(data.nodes,data.elements,imag(rec), ...
            sprintf('%s: Im(\Delta\gamma) (S/m)',model_names{m}),[-limRec limRec]);

        base = sprintf('%s_%s',strrep(names{p},'_','_'),model_names{m});
        print(fig,fullfile(outdir,['reconstruction_' base '.png']),'-dpng','-r150');
        close(fig);
        fprintf('Saved: reconstruction_%s.png\n', base);
    end
end
%% Save the complete in-memory case status for optional follow-up plots
save(fullfile(outdir,'demo_run_status.mat'),'report','names');
fprintf('Demo results: %s\n',outdir);

%% Plot the 120-pair forward-current responses
% Compare homogeneous and inclusion transmitter currents for each phantom
% and model. The plotting helper reads the status MAT saved above.
run(fullfile(project_root,'demo_reconstruction','plot_current_diff.m'));
