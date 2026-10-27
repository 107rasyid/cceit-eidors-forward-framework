clear; close all; clc;
P0 = cceit_params();
if ~isfield(P0,'width_mode'), P0.width_mode = 'meters'; end

%% (1) Baseline: elemen sepanjang tebal + perbandingan mode lebar elektroda
modes = {'meters','angle'};
base = cell(1,2);
for k = 1:2
  P = P0;  P.width_mode = modes{k};
  base{k} = cceit_run_AB(P);
  b = base{k};
  fprintf('[%s] wB=%.4f m | elemen cincin=%d | node dalam cincin=%d | span radial rata2=%.2e m | elemen/tebal ~ %.2f | delta_layer=%.3g | rasio=%.3g\n', ...
    modes{k}, b.iB.wB, b.iB.nRing, b.iB.nInteriorRingNodes, b.iB.meanSpan, b.iB.nAcross, b.delta_layer, b.ratio);
end

%% (2) Refinement mesh (A dan B bersama, ukuran elemen sama)
scales = [1 0.7 0.5];
ref = cell(numel(scales),1);
for k = 1:numel(scales)
  P = P0;
  P.h_int = P0.h_int * scales(k);
  P.h_el  = P0.h_el  * scales(k);
  tic; ref{k} = cceit_run_AB(P); tk = toc;
  fprintf('scale %.2f | A: %d elem | B: %d elem | elemen/tebal ~ %.2f | delta_layer=%.3g | rasio=%.3g | %.0f s\n', ...
    scales(k), ref{k}.iA.nElems, ref{k}.iB.nElems, ref{k}.iB.nAcross, ref{k}.delta_layer, ref{k}.ratio, tk);
end
yA_f = ref{end}.yA;  yB_f = ref{end}.yB;
for k = 1:numel(scales)-1
  dmA = norm(ref{k}.yA - yA_f)/norm(yA_f);
  dmB = norm(ref{k}.yB - yB_f)/norm(yB_f);
  fprintf('delta_mesh (scale %.2f vs %.2f): A = %.3g, B = %.3g\n', scales(k), scales(end), dmA, dmB);
end

%% (4) Sweep ketebalan d (ukuran elemen dibatasi d/2 agar cincin terselesaikan)
dlist = [2 3 4.5 6 9]*1e-3;
sw = cell(numel(dlist),1);
for k = 1:numel(dlist)
  P = P0;  P.d = dlist(k);
  P.h_int = min(P0.h_int, P.d/2);
  P.h_el  = min(P0.h_el,  P.d/2);
  tic; sw{k} = cceit_run_AB(P); tk = toc;
  fprintf('d=%.1f mm | h_int=%.2f mm | elemen/tebal ~ %.2f | delta_layer=%.3g | rasio=%.3g | %.0f s\n', ...
    dlist(k)*1e3, P.h_int*1e3, sw{k}.iB.nAcross, sw{k}.delta_layer, sw{k}.ratio, tk);
end

meta.version = version; meta.date = datestr(now);
save('step3_results.mat','base','ref','sw','scales','dlist','P0','meta');
