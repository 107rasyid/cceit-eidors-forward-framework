function out = cceit_pairscan(fmdl, gamma_elem, P)
% 120 pasangan t<r, eksitasi tegangan via volt_pattern + NaN.
n = P.nElec;
Y = zeros(n);                      % Y(t,r) = I_t / Vtx
dcc = []; dfloat = []; dU = [];
pairs = [];

for t = 1:n-1
  for r = t+1:n
    stim.stim_pattern = zeros(n,1);
    stim.volt_pattern = zeros(n,1);
    stim.stim_pattern([t r]) = NaN;
    stim.volt_pattern(t) = P.Vtx;
    stim.volt_pattern(r) = 0;
    stim.meas_pattern = speye(n);
    fmdl.stimulation = stim;

    img = mk_image(fmdl, gamma_elem);
    img.fwd_solve.get_all_meas  = 1;
    img.fwd_solve.get_elec_curr = 1;
    data = fwd_solve(img);

    I = data.elec_curr(:,1);       % CHECK: konvensi tanda
    U = data.meas(:,1);

    Y(t,r) = I(t) / P.Vtx;
    Y(r,t) = Y(t,r);               % simetris dari resiprokalitas (diuji terpisah)

    fl = setdiff(1:n, [t r]);
    dcc(end+1,1)    = abs(sum(I)) / abs(I(t));
    dfloat(end+1,1) = max(abs(I(fl))) / abs(I(t));
    dU(end+1,1)     = max(abs(U(t)-P.Vtx), abs(U(r)));
    pairs(end+1,:)  = [t r];
  end
end

out.Y = Y; out.pairs = pairs;
out.dcc = dcc; out.dfloat = dfloat; out.dU = dU;
end
