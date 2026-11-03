% DEMO_RECONSTRUCTION Demonstrate three phantoms with Model A2 and B5.
% Forward voltage-driven scan -> TIA -> complex difference reconstruction.
% This educational demo is outside the paper's forward-only scope.
clear; close all; clc;
project_root = setup_paths();
addpath(fullfile(project_root,'demo_reconstruction'));
P = cceit_params();
outdir = fullfile(P.project_root,'results','reconstruction_demo');
if exist(outdir,'dir') ~= 7, mkdir(outdir); end
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
% Data-derived composite: three phantom rows and five map columns.
fig = figure('visible','off','color','w','position',[20 40 1900 1180]);
for p = 1:3
    a = report{p,1}; b = report{p,2};
    if ~isstruct(a) || ~isfield(a,'dgamma_reconstruction') || ...
            ~isstruct(b) || ~isfield(b,'dgamma_reconstruction')
        fprintf('Combined figure incomplete for %s: both A2 and B5 are needed.\n',names{p});
        continue;
    end
    gt = real(a.delta_gamma_true);
    recA = a.dgamma_reconstruction;
    recB = b.dgamma_reconstruction;
    limGT = max(abs(gt(:)));
    limReal = max(abs([real(recA(:));real(recB(:))]));
    limImag = max(abs([imag(a.delta_gamma_true(:));imag(recA(:));imag(recB(:))]));
    if limGT == 0, limGT = 1; end
    if limReal == 0, limReal = 1; end
    if limImag == 0, limImag = 1; end
    subplot(3,5,(p-1)*5+1); cceit_demo_map(a.nodes,a.elements,gt, ...
        'Ground truth: \Delta\sigma (S/m)',[-limGT limGT]);
    subplot(3,5,(p-1)*5+2); cceit_demo_map(a.nodes,a.elements,real(recA), ...
        'A2: Re(\Delta\gamma) (S/m)',[-limReal limReal]);
    subplot(3,5,(p-1)*5+3); cceit_demo_map(a.nodes,a.elements,imag(recA), ...
        'A2: Im(\Delta\gamma) (S/m)',[-limImag limImag]);
    subplot(3,5,(p-1)*5+4); cceit_demo_map(b.nodes,b.elements,real(recB), ...
        'B5: Re(\Delta\gamma) (S/m)',[-limReal limReal]);
    subplot(3,5,(p-1)*5+5); cceit_demo_map(b.nodes,b.elements,imag(recB), ...
        'B5: Im(\Delta\gamma) (S/m)',[-limImag limImag]);
    fprintf('%s max |Re reconstruction|: A2=%.4g, B5=%.4g S/m; GT max=%.4g S/m\n', ...
        names{p},max(abs(real(recA))),max(abs(real(recB))),limGT);
end
set(fig,'Name','GT and A2/B5 real-imag maps for the three phantoms');
print(fig,fullfile(outdir,'three_phantoms_GT_A2_B5.png'),'-dpng','-r150');
close(fig);
save(fullfile(outdir,'demo_run_status.mat'),'report','names');
fprintf('Demo results: %s\n',outdir);
