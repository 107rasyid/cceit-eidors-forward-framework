function frac = cceit_ring_frac(fmdl, R)
% Fraksi luas tiap elemen yang berada di r >= R (titik sampel dalam segitiga).
nb = 6; Bc = [];
for i = 0:nb-1
  for j = 0:nb-1-i
    Bc(end+1,:) = [(i+1/3)/nb, (j+1/3)/nb];
  end
end
for i = 0:nb-2
  for j = 0:nb-2-i
    Bc(end+1,:) = [(i+2/3)/nb, (j+2/3)/nb];
  end
end
n = fmdl.nodes(:,1:2); e = fmdl.elems;
frac = zeros(size(e,1),1);
for q = 1:size(Bc,1)
  l1 = Bc(q,1); l2 = Bc(q,2); l3 = 1-l1-l2;
  px = l1*n(e(:,1),1) + l2*n(e(:,2),1) + l3*n(e(:,3),1);
  py = l1*n(e(:,1),2) + l2*n(e(:,2),2) + l3*n(e(:,3),2);
  frac = frac + double(hypot(px,py) >= R);
end
frac = frac / size(Bc,1);
end
