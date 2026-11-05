function y = cceit_runA_mesh(fA, P, f)
% Model A pada mesh yang sudah ada. Mengembalikan 120 admitansi transfer.
  w   = 2*pi*f;
  gam = P.sigma + 1i*w*P.eps0*P.epsr;
  zc  = 1 / (P.sigma_d/P.d + 1i*w*P.eps0*P.epsr_d/P.d);   % tanpa kappa
  for e = 1:P.nElec, fA.electrode(e).z_contact = zc; end
  out = cceit_pairscan(fA, gam*ones(size(fA.elems,1),1), P);
  idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
  y = out.Y(idx);
end
