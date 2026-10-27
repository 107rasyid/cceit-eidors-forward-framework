function [y, ne] = local_runA(P, f)
  w   = 2*pi*f;
  gam = P.sigma + 1i*w*P.eps0*P.epsr;
  [fA, iA] = cceit_mesh_A(P);
  zc = 1 / (P.sigma_d/P.d + 1i*w*P.eps0*P.epsr_d/P.d);   % tanpa kappa
  for e = 1:P.nElec, fA.electrode(e).z_contact = zc; end
  out = cceit_pairscan(fA, gam*ones(size(fA.elems,1),1), P);
  idx = sub2ind(size(out.Y), out.pairs(:,1), out.pairs(:,2));
  y = out.Y(idx);
  ne = iA.nElems;
end
