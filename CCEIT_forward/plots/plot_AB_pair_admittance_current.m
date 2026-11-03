% PLOT_AB_PAIR_ADMITTANCE_CURRENT Export individual A/B admittance and current plots.
% Uses acquisition order from cceit_pair_list: tx ascending, rx ascending.
% Figures are separate single-panel files to keep each result readable.
P = cceit_params();
resolution_path = fullfile(P.outdir,'B5_resolution_study.mat');
coarse_path = fullfile(P.outdir,'AB_A2_B5_coarse_results.mat');

use_resolution = false;
if exist(resolution_path,'file') == 2
    R = load(resolution_path);
    use_resolution = isfield(R,'P') && cceit_same_baseline(R.P,P) && ...
        isfield(R,'freq_Hz') && R.freq_Hz == P.f && ...
        isfield(R,'y_A') && isfield(R,'levels') && ~isempty(R.levels) && ...
        isfield(R.levels,'y_B') && ~isempty(R.levels(end).y_B);
end

if use_resolution
    y_A = R.y_A(:);
    y_B = R.levels(end).y_B(:);
    freq_Hz = R.freq_Hz;
    h_ring = R.levels(end).h_ring_m;
    source = 'B5 resolution study';
elseif exist(coarse_path,'file') == 2
    R = load(coarse_path);
    if ~isfield(R,'P') || ~cceit_same_baseline(R.P,P) || ...
            ~isfield(R,'y_A') || ~isfield(R,'y_B')
        error('plot_AB_pair_admittance_current: coarse A2/B5 results are incomplete or baseline-mismatched');
    end
    y_A = R.y_A(:);
    y_B = R.y_B(:);
    freq_Hz = R.freq_Hz;
    h_ring = R.h_ring;
    source = 'coarse A2/B5 comparison';
    if exist(resolution_path,'file') == 2
        warning(['plot_AB_pair_admittance_current: B5 resolution MAT is absent ' ...
            'required pair data or uses another baseline; using the valid 1 mm coarse A2/B5 result.']);
    end
else
    error('plot_AB_pair_admittance_current: run the A2/B5 comparison first');
end

pairs = cceit_pair_list(P.nElec);
if numel(y_A) ~= size(pairs,1) || numel(y_B) ~= size(pairs,1)
    error('plot_AB_pair_admittance_current: expected one A and B value for each measured pair');
end
pair_index = (1:size(pairs,1)).';
current_A = P.Vtx*y_A;
current_B = P.Vtx*y_B;
magY_A = abs(y_A); magY_B = abs(y_B);
phaseY_A = angle(y_A)*180/pi; phaseY_B = angle(y_B)*180/pi;
magI_A = abs(current_A); magI_B = abs(current_B);

 cceit_plot_pair_series(pair_index,magY_A,'Pair admittance magnitude (S per m depth)', ...
    'Model A2 pair admittance magnitude',fullfile(P.outdir,'fig_A2_Y_magnitude.png'));
 cceit_plot_pair_series(pair_index,magY_B,'Pair admittance magnitude (S per m depth)', ...
    sprintf('Model B5 pair admittance magnitude, h_{ring}=%.2f mm',h_ring*1e3), ...
    fullfile(P.outdir,'fig_B5_Y_magnitude.png'));
 cceit_plot_pair_series(pair_index,phaseY_A,'Pair admittance phase (degrees)', ...
    'Model A2 pair admittance phase',fullfile(P.outdir,'fig_A2_Y_phase.png'));
 cceit_plot_pair_series(pair_index,phaseY_B,'Pair admittance phase (degrees)', ...
    sprintf('Model B5 pair admittance phase, h_{ring}=%.2f mm',h_ring*1e3), ...
    fullfile(P.outdir,'fig_B5_Y_phase.png'));
 cceit_plot_pair_series(pair_index,magI_A,'Transmitter current magnitude (A per m depth)', ...
    'Model A2 transmitter current magnitude',fullfile(P.outdir,'fig_A2_I_magnitude.png'));
 cceit_plot_pair_series(pair_index,magI_B,'Transmitter current magnitude (A per m depth)', ...
    sprintf('Model B5 transmitter current magnitude, h_{ring}=%.2f mm',h_ring*1e3), ...
    fullfile(P.outdir,'fig_B5_I_magnitude.png'));

csv_path = fullfile(P.outdir,'AB_pair_admittance_current_acquisition_order.csv');
fid = fopen(csv_path,'w');
if fid < 0, error('plot_AB_pair_admittance_current: cannot write CSV'); end
fprintf(fid,['pair_index,tx,rx,abs_yA,phase_yA_deg,abs_yB,phase_yB_deg,' ...
    'abs_Itx_A,abs_Itx_B\n']);
for k = 1:numel(pair_index)
    fprintf(fid,'%d,%d,%d,%.12g,%.9g,%.12g,%.9g,%.12g,%.12g\n', ...
        k,pairs(k,1),pairs(k,2),magY_A(k),phaseY_A(k),magY_B(k), ...
        phaseY_B(k),magI_A(k),magI_B(k));
end
fclose(fid);
fprintf('Source: %s | f=%.0f kHz | h_ring=%.2f mm\n',source,freq_Hz/1e3,h_ring*1e3);
fprintf('With Vtx=%.6g V: |Itx| = |Ypair|*|Vtx|; current and admittance magnitudes differ only by units.\n',P.Vtx);
fprintf('CSV: %s\n',csv_path);
