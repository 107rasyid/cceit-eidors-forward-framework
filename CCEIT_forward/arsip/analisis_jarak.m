% analisis_jarak.m : pola selisih A vs B per jarak elektroda, dari tes_B4_results.mat
L = load('tes_B4_results.mat');             % berisi R, yA, hrs, P0
yA = L.yA;
k = find(L.R.tank.ok, 1, 'last');           % level tank terhalus yang berhasil
yB = L.R.tank.yB{k};
fprintf('Level tank h_ring = %.2f mm\n', L.hrs(k)*1e3);

pairs = [];
for t = 1:15, for q = t+1:16, pairs(end+1,:) = [t q]; end, end
c = pairs(:,2) - pairs(:,1);  sep = min(c, 16-c);

for s = 1:8
  m = (sep == s);
  fprintf('jarak %d | n=%3d | median|yA|/|yB| = %.4f | galat relatif = %.4f | selisih fase = %.3f deg\n', ...
    s, nnz(m), median(abs(yA(m))./abs(yB(m))), ...
    norm(yA(m)-yB(m))/norm(yB(m)), median(angle(yA(m)./yB(m)))*180/pi);
end
fprintf('Total: rasio median = %.4f | delta_layer = %.4f\n', ...
        median(abs(yA)./abs(yB)), norm(yA-yB)/norm(yB));
