clear all; eidors_cache clear
P = cceit_params();
[fB, ringB, iB] = cceit_mesh_B(P);
fprintf('B OK: %d elemen, %d cincin\n', iB.nElems, iB.nRing);
