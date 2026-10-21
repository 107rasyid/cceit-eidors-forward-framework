function V = cceit_verify(P, R)
% CCEIT_VERIFY  Cek numerik pada solusi forward.
%   - KCL global: sum arus semua elektroda ≈ 0
%   - Elektroda floating: arusnya ≈ 0

V = struct();

% KCL global
V.max_sum_I = max(abs(sum(R.I_elec, 1)));

% Floating per solve (semua yang bukan tx dan bukan rx)
V.max_I_floating = 0;
for k = 1:numel(R.rx_list)
    floating = setdiff(1:P.nElec, [P.tx, R.rx_list(k)]);
    V.max_I_floating = max(V.max_I_floating, max(abs(R.I_elec(floating, k))));
end
end
