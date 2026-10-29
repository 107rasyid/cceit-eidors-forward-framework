eidors_cache clear
P0 = cceit_params();  P0.width_mode = 'meters';
[fA, iA] = cceit_mesh_A(P0);
[fB, ringB, iB] = cceit_mesh_B(P0);

spanA = zeros(16,1); spanB = zeros(16,1);
nnA = zeros(16,1);   nnB = zeros(16,1);
for i = 1:16
  [spanA(i), nnA(i)] = elec_span(fA, i);
  [spanB(i), nnB(i)] = elec_span(fB, i);
end
arcA = mean(spanA) * P0.R;
arcB = mean(spanB) * (P0.R + P0.d);
fprintf('w_el diminta   = %.4f m\n', P0.w_el);
fprintf('A: busur elektroda = %.4f m (%.1f node/elektroda)\n', arcA, mean(nnA));
fprintf('B: busur elektroda = %.4f m (%.1f node/elektroda)\n', arcB, mean(nnB));

w  = 2*pi*P0.f;
zc = 1 / (P0.sigma_d/P0.d + 1i*w*P0.eps0*P0.epsr_d/P0.d);
r  = cceit_run_AB(P0);
fprintf('estimasi Y = w/(2|z|): dengan w_el = %.3e | dengan busur A = %.3e | dengan busur B = %.3e\n', ...
        P0.w_el/(2*abs(zc)), arcA/(2*abs(zc)), arcB/(2*abs(zc)));
fprintf('median |yA| = %.3e | median |yB| = %.3e\n', median(abs(r.yA)), median(abs(r.yB)));

function [sp, nn] = elec_span(fm, i)
  q = fm.nodes(fm.electrode(i).nodes, 1:2);
  a = atan2(q(:,2), q(:,1));
  a0 = atan2(mean(q(:,2)), mean(q(:,1)));
  da = angle(exp(1i*(a - a0)));
  sp = max(da) - min(da);  nn = size(q,1);
end
