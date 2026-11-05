function result = cceit_demo_case(P, phantom_id, model_id, outdir)
% CCEIT_DEMO_CASE Run and save one synthetic reconstruction case.
% Purpose: pass homogeneous and inclusion scans through the demo pipeline.
% Inputs: P shared parameters; phantom_id 1..3; model_id 1=A3, 2=B6;
%         outdir folder for per-case MAT and TIA CSV files.
% Outputs: result struct with pair data, TIA voltages, differential impedance,
%          reconstruction, ground truth, mesh, and forward-check metrics.
% Scope: educational reconstruction demonstration, not paper validation.
% Manuscript ref: supplementary workflow demonstration only.

%% Fixed illustrative settings
% Local copies keep these example choices separate from paper sweep settings.
P.f = 3e6; P.d = 1e-3;
n = P.nElec; w = 2*pi*P.f; Rf = 10e3; alpha_rel = 1e-3;  % reduced regularization for better imaginary recovery
gamma_bg = P.sigma + 1i*w*P.eps0*P.epsr;
% The large inclusion permittivity makes the imaginary change visible here;
% these illustrative material values are not tissue-property estimates.
gamma_obj = 0.10 + 1i*w*P.eps0*5000;  % epsr_obj = 5000 (vs 80 background)
%% Build the selected active mesh model
eidors_cache clear
if model_id == 1
    [fmdl,mesh_info] = cceit_mesh_A3(P);
    zc = 1/(P.sigma_d/P.d + 1i*w*P.eps0*P.epsr_d/P.d);
    for e = 1:n, fmdl.electrode(e).z_contact = zc; end
    ring = false(size(fmdl.elems,1),1); model = 'A3';
else
    [fmdl,ring,mesh_info] = cceit_mesh_B6(P,P.h_ring_B6_coarse);
    for e = 1:n, fmdl.electrode(e).z_contact = P.z_el; end
    model = 'B6';
end
%% Mark the inclusion on element centroids
nodes = fmdl.nodes(:,1:2); elems = fmdl.elems;
cent = (nodes(elems(:,1),:) + nodes(elems(:,2),:) + nodes(elems(:,3),:))/3;
x = cent(:,1); y = cent(:,2);
roi_obj = false(size(x));
switch phantom_id
    case 1
        roi_obj = (x-0.55*P.R).^2 + y.^2 < (0.22*P.R)^2;
    case 2
        roi_obj = ((x-0.36*P.R).^2+y.^2 < (0.18*P.R)^2) | ...
            ((x+0.36*P.R).^2+y.^2 < (0.18*P.R)^2);
    case 3
        roi_obj = (x.^2+(y-0.40*P.R).^2 < (0.16*P.R)^2) | ...
            ((x+0.36*P.R).^2+(y+0.30*P.R).^2 < (0.16*P.R)^2) | ...
            ((x-0.36*P.R).^2+(y+0.30*P.R).^2 < (0.16*P.R)^2);
    otherwise
        error('cceit_demo_case: phantom_id must be 1, 2, or 3');
end
%% Solve homogeneous and inclusion forward scans
% Keep any explicit dielectric ring unchanged; only selected medium elements
% change from background to inclusion admittivity.
medium = ~ring;
gamma_h = gamma_bg*ones(size(elems,1),1);
gamma_i = gamma_h;
gamma_layer = P.sigma_d + 1i*w*P.eps0*P.epsr_d;
gamma_h(ring) = gamma_layer; gamma_i(ring) = gamma_layer;
gamma_i(medium & roi_obj) = gamma_obj;
out_h = cceit_pairscan(fmdl,gamma_h,P);
out_i = cceit_pairscan(fmdl,gamma_i,P);
%% Convert transmitter currents to ideal TIA voltages and differential data
% Pair admittance times prescribed drive voltage gives transmitter current;
% the ideal transimpedance stage follows Vtia = -Rf * I.
pairs = out_h.pairs; ix = sub2ind([n n],pairs(:,1),pairs(:,2));
I_h = out_h.Y(ix)*P.Vtx; I_i = out_i.Y(ix)*P.Vtx;
Vtia_h = -Rf*I_h; Vtia_i = -Rf*I_i;
Irec_h = -Vtia_h/Rf; Irec_i = -Vtia_i/Rf;
dZ = P.Vtx./Irec_i - P.Vtx./Irec_h;
fprintf('dZ stats: |Re(dZ)|_max=%.4g, |Im(dZ)|_max=%.4g, ratio=%.4g\n', ...
    max(abs(real(dZ))), max(abs(imag(dZ))), max(abs(imag(dZ)))/max(abs(real(dZ))));

stim = struct([]);
for k = 1:size(pairs,1)
    sp = zeros(n,1); sp(pairs(k,1))=1; sp(pairs(k,2))=-1;
    stim(k).stimulation='Amps'; stim(k).stim_pattern=sp;
    stim(k).meas_pattern=sp';
end
fmdl.stimulation=stim; img=mk_image(fmdl,gamma_h);
J=calc_jacobian(img);
if size(J,1) ~= numel(dZ) && size(J,2)==numel(dZ), J=J.'; end
if size(J,1) ~= numel(dZ)
    error('cceit_demo_case: Jacobian rows do not match the 120 pair data');
end
%% Reconstruct complex admittivity change from differential impedance data
% The diagonal sensitivity weighting and separate real/imaginary lambdas are
% demonstration choices, not a validated or tuned imaging method.
diagJ=sum(abs(J).^2,1).'; reg=1./max(diagJ,eps);
normal=J*(reg.*J');
lambda_real=alpha_rel*real(trace(normal))/size(normal,1);
lambda_imag=lambda_real*0.5;  % 50% less regularization for imaginary
dZ_real=real(dZ); dZ_imag=imag(dZ);
dgamma_real=(reg.*J')*((normal+lambda_real*eye(size(normal)))\dZ_real);
dgamma_imag=(reg.*J')*((normal+lambda_imag*eye(size(normal)))\dZ_imag);
dgamma=dgamma_real + 1i*dgamma_imag;
fprintf('Reconstruction: |Re(dgamma)|_max=%.4g, |Im(dgamma)|_max=%.4g, ratio=%.4g\n', ...
    max(abs(dgamma_real)), max(abs(dgamma_imag)), max(abs(dgamma_imag))/max(abs(dgamma_real)));

phantom_names={'one_circle','two_circles_left_right','three_circles_triangle'};
base=sprintf('%s_%s',phantom_names{phantom_id},model);
%% Save pair-wise TIA data and the full case result
% CSV columns separate homogeneous and inclusion TIA voltages in the pair
% acquisition order returned by cceit_pairscan.
csv_path=fullfile(outdir,[base '_tia.csv']);
if exist(csv_path,'file'), delete(csv_path); end
fid=fopen(csv_path,'w');
if fid<0, error('cceit_demo_case: cannot write TIA CSV'); end
fprintf(fid,'pair_index,tx,rx,Re_Vtia_hom,Im_Vtia_hom,Re_Vtia_obj,Im_Vtia_obj\n');
for k=1:numel(I_h)
    fprintf(fid,'%d,%d,%d,%.12g,%.12g,%.12g,%.12g\n',k,pairs(k,1),pairs(k,2), ...
        real(Vtia_h(k)),imag(Vtia_h(k)),real(Vtia_i(k)),imag(Vtia_i(k)));
end
fclose(fid);
result=struct('model',model,'phantom_id',phantom_id,'mesh_info',mesh_info, ...
    'pairs',pairs,'I_h',I_h,'I_i',I_i,'Vtia_h',Vtia_h,'Vtia_i',Vtia_i, ...
    'dZ',dZ,'dgamma_reconstruction',dgamma,'delta_gamma_true',gamma_i-gamma_h, ...
    'nodes',nodes,'elements',elems,'Rf_ohm',Rf, ...
    'alpha_rel',alpha_rel,'max_dcc',max([out_h.dcc;out_i.dcc]), ...
    'max_dfloat',max([out_h.dfloat;out_i.dfloat]), ...
    'max_dU',max([out_h.dU;out_i.dU]),'csv_path',csv_path);
meta=cceit_make_metadata(P); result_path=fullfile(outdir,[base '_results.mat']);
if exist(result_path,'file'), delete(result_path); end
save(result_path,'P','result','meta'); result.result_path=result_path;
end
