% eit_vs_cceit_tank4.m
% Hanya gambar. Tank homogen, 16 elektroda, eksitasi elektroda 1, pengukuran elektroda 2.
%   EIT   : tanpa insulating layer, elektroda kecil
%   CCEIT : dengan insulating layer, elektroda lebih lebar
%   Gambar 1: homogen (EIT | CCEIT)
%   Gambar 2: dengan anomali besar dekat elektroda pengukuran (EIT | CCEIT)
%   Gambar 3: peta konduktivitas (cek bentuk anomali dan insulator)
% Warna   = log10(|J| R / I), skala sama untuk semua panel (arus injeksi sama).
% Panah   = arah J pada saat arus injeksi puncak (nilai riil, tanpa rotasi fase),
%           jadi arahnya dari elektroda injeksi (merah) ke elektroda pengukuran (biru).
1;

function draw_panel_cc(Dc, cdata, clim, lm, na, ttl, xl, P, show_anom)
  th = linspace(0, 2*pi, 300);
  patch('Faces',Dc.elems,'Vertices',Dc.nodes,'FaceVertexCData',cdata, ...
        'FaceColor','flat','EdgeColor','none');
  hold on
  if Dc.has_ins
    plot((Dc.Rm-P.t_ins)*cos(th), (Dc.Rm-P.t_ins)*sin(th), 'k', 'LineWidth', 0.5);
  end
  plot(Dc.Rm*cos(th), Dc.Rm*sin(th), 'k', 'LineWidth', 0.5);
  for i = 1:P.n_elec
    a = atan2(Dc.ec(i,2), Dc.ec(i,1));
    if i == P.iD,     fc = [0.9 0.2 0.2];
    elseif i == P.jS, fc = [0.2 0.3 0.9];
    else,             fc = [0.7 0.7 0.7]; end
    wd = Dc.wspan(i);  Rb = Dc.Rm;  tk = P.th_plot;
    patch(Rb*cos(a) + [-1 1 1 -1]*(wd/2)*(-sin(a)) + [0 0 1 1]*tk*cos(a), ...
          Rb*sin(a) + [-1 1 1 -1]*(wd/2)*( cos(a)) + [0 0 1 1]*tk*sin(a), fc, 'EdgeColor', 'k');
  end
  if show_anom
    plot(P.xa + P.a_r*cos(th), P.ya + P.a_r*sin(th), 'k', 'LineWidth', 1.0);
  end
  if na > 0
    [xg,yg] = meshgrid(linspace(lm(1),lm(2),na), linspace(lm(3),lm(4),na));
    Qx = griddata(Dc.xc, Dc.yc, Dc.Arx, xg, yg);
    Qy = griddata(Dc.xc, Dc.yc, Dc.Ary, xg, yg);
    ok = hypot(xg,yg) < P.R - 0.002 & ~isnan(Qx) & ~isnan(Qy);
    qn = hypot(Qx,Qy) + eps;
    quiver(xg(ok), yg(ok), Qx(ok)./qn(ok), Qy(ok)./qn(ok), 0.8, 'k');
  end
  axis equal; axis(lm); caxis(clim); colormap(jet); colorbar;
  title(ttl); xlabel(xl);
end

setenv('PATH', ['C:\Netgen\bin;' getenv('PATH')]);
eidors_debug off call_netgen

%% Parameter
e0 = 8.854e-12;
f = 500e3;  w = 2*pi*f;
n_elec = 16;  R = 0.09;                % radius tank konduktif (m)
w_el   = [0.012 0.022];                % lebar elektroda (m): EIT kecil | CCEIT lebar
iD = 1;  jS = 2;                       % eksitasi dan pengukuran bersebelahan

sig_t = 0.2;  er_t = 78;               % tank (PLACEHOLDER)
t_ins = 0.003;  er_ins = 9;  sig_ins = 1e-9;   % 3 mm, er 9 ~ setara 1 mm, er 3
z_el  = 0.01;                          % Ohm.m^2, kontak elektroda (kecil)
th_plot = 0.004;                       % tebal elektroda untuk gambar saja (m)
I_eit = 1e-3;  V_cc = 1;               % EIT: injeksi arus 1 mA | CCEIT: injeksi tegangan 1 V
exc = {'injeksi arus 1 mA', 'injeksi tegangan 1 V'};

% Anomali besar dekat elektroda pengukuran (PLACEHOLDER)
a_rad = 0.056;                         % jarak pusat anomali dari pusat tank (m), searah elektroda jS
a_r   = 0.022;                         % radius anomali (m)
sig_a = 0.67;  er_a = 80;              % anomali konduktif (ganti sig_a = 0.05 untuk isolatif)

cname   = {'EIT', 'CCEIT'};
has_ins = [false true];
Ytank = sig_t   + 1i*w*e0*er_t;
Yins  = sig_ins + 1i*w*e0*er_ins;
Yanom = sig_a   + 1i*w*e0*er_a;

%% Bangun model dan solve: D{kasus, skenario}; skenario 1 = homogen, 2 = dengan anomali
D = cell(2,2);
for c = 1:2
    Rreq = R + has_ins(c)*t_ins;
    fm = ng_mk_cyl_models([0, Rreq, 0.003], [n_elec], [w_el(c), 0, 0.0015]);
    Rm0 = max(hypot(fm.nodes(:,1), fm.nodes(:,2)));
    fm.nodes = fm.nodes * (Rreq / Rm0);                 % pastikan radius luar sesuai
    nodes = fm.nodes(:,1:2);  elems = fm.elems;  nE = size(elems,1);
    if size(elems,2) ~= 3, error('Script ini untuk mesh 2D (segitiga).'); end
    Rm = Rreq;

    xc = mean(reshape(nodes(elems(:),1), nE, 3), 2);
    yc = mean(reshape(nodes(elems(:),2), nE, 3), 2);
    rc = hypot(xc,yc);
    band = rc >= (Rm - t_ins);                          % insulator untuk CCEIT
    if has_ins(c) && sum(band) < 50, error('Cincin insulator hanya %d elemen.', sum(band)); end

    for i = 1:n_elec, fm.electrode(i).z_contact = z_el; end
    ec = zeros(n_elec,2);  wspan = zeros(n_elec,1);
    for i = 1:n_elec
        nn = nodes(fm.electrode(i).nodes,:);
        ec(i,:) = mean(nn,1);
        a0 = atan2(ec(i,2), ec(i,1));
        da = angle(exp(1i*(atan2(nn(:,2),nn(:,1)) - a0)));
        wspan(i) = (max(da) - min(da)) * Rm;
    end

    aj = atan2(ec(jS,2), ec(jS,1));
    xa = a_rad*cos(aj);  ya = a_rad*sin(aj);
    % fraksi luas tiap elemen yang berada di dalam lingkaran (16 titik sampel per segitiga),
    % supaya tepi anomali halus, bukan bergerigi per elemen
    nb = 4;  Bc = zeros(nb*nb, 2);  q = 0;
    for i = 0:nb-1
        for j = 0:nb-1-i
            q = q + 1;  Bc(q,:) = [(i+1/3)/nb, (j+1/3)/nb];
        end
    end
    for i = 0:nb-2
        for j = 0:nb-2-i
            q = q + 1;  Bc(q,:) = [(i+2/3)/nb, (j+2/3)/nb];
        end
    end
    frac = zeros(nE,1);
    for q = 1:size(Bc,1)
        l1 = Bc(q,1);  l2 = Bc(q,2);  l3 = 1 - l1 - l2;
        px = l1*nodes(elems(:,1),1) + l2*nodes(elems(:,2),1) + l3*nodes(elems(:,3),1);
        py = l1*nodes(elems(:,1),2) + l2*nodes(elems(:,2),2) + l3*nodes(elems(:,3),2);
        frac = frac + (hypot(px-xa, py-ya) < a_r);
    end
    frac = frac / size(Bc,1);
    anom = frac > 0.5;
    if sum(anom) < 20, error('Anomali hanya %d elemen.', sum(anom)); end

    sp = zeros(n_elec,1);  sp(iD) = 1;  sp(jS) = -1;     % +1 A masuk di iD, keluar di jS
    fm1 = fm;
    fm1.stimulation(1).stimulation  = 'Amps';
    fm1.stimulation(1).stim_pattern = sp;
    fm1.stimulation(1).meas_pattern = sp';

    X1 = nodes(elems(:,1),1); Y1 = nodes(elems(:,1),2);
    X2 = nodes(elems(:,2),1); Y2 = nodes(elems(:,2),2);
    X3 = nodes(elems(:,3),1); Y3 = nodes(elems(:,3),2);
    detA = (X2-X1).*(Y3-Y1) - (X3-X1).*(Y2-Y1);

    for s = 1:2
        Yel = Ytank * ones(nE,1);
        if s == 2, Yel = Yel + frac*(Yanom - Ytank); end
        if has_ins(c), Yel(band) = Yins; end

        img = mk_image(fm1, 1);
        img.elem_data = Yel;
        img.fwd_solve.get_all_meas = 1;
        d = fwd_solve(img);
        if ~isfield(d,'volt'), error('fwd_solve tidak mengembalikan d.volt'); end
        Zp = d.meas(1);                                 % impedansi pasangan untuk arus 1 A
        if c == 1, Iexc = I_eit; else, Iexc = V_cc/abs(Zp); end   % CCEIT: arus = 1 V / |Z|
        phi = d.volt(:,1);                              % potensial untuk arus injeksi +1 A (fase 0)
        if numel(phi) ~= size(nodes,1)
            error('Ukuran d.volt (%d) != jumlah node (%d)', numel(phi), size(nodes,1));
        end

        Ex = -(((Y2-Y3).*phi(elems(:,1)) + (Y3-Y1).*phi(elems(:,2)) + (Y1-Y2).*phi(elems(:,3))) ./ detA);
        Ey = -(((X3-X2).*phi(elems(:,1)) + (X1-X3).*phi(elems(:,2)) + (X2-X1).*phi(elems(:,3))) ./ detA);
        Jx = Yel.*Ex;  Jy = Yel.*Ey;
        J1 = sqrt(abs(Jx).^2 + abs(Jy).^2);             % |J| untuk arus 1 A

        D{c,s} = struct('elems',elems, 'nodes',nodes, 'xc',xc, 'yc',yc, 'ec',ec, ...
            'wspan',wspan, 'Rm',Rm, 'has_ins',has_ins(c), ...
            'Arx',real(Jx), 'Ary',real(Jy), ...          % arah J pada arus injeksi puncak
            'Jn', J1*Iexc, 'm_I', mean(J1(anom))*Iexc, 'Sig', real(Yel), 'Zp', Zp, 'Iexc', Iexc);
    end
    if c == 1, xa1 = xa;  ya1 = ya; end
end

P = struct('t_ins',t_ins, 'n_elec',n_elec, 'iD',iD, 'jS',jS, 'th_plot',th_plot, ...
           'R',R, 'xa',xa1, 'ya',ya1, 'a_r',a_r);
lm = [-1 1 -1 1] * (R + t_ins + 0.012);
clog = [-3.5 -0.5];

%% Gambar 1: homogen
figure('Position', [60 80 1050 500]);
for c = 1:2
    subplot(1,2,c);
    draw_panel_cc(D{c,1}, log10(max(D{c,1}.Jn, 1e-6)), clog, lm, 30, ...
        sprintf('%s, elektroda %.0f mm | homogen\nlog10(|J|) (A/m^2), panah = arah J', ...
                cname{c}, median(D{c,1}.wspan)*1000), ...
        sprintf('%s: |I| = %.3g A/m', exc{c}, abs(D{c,1}.Iexc)), P, false);
end

%% Gambar 2: dengan anomali
figure('Position', [100 100 1050 500]);
for c = 1:2
    subplot(1,2,c);
    draw_panel_cc(D{c,2}, log10(max(D{c,2}.Jn, 1e-6)), clog, lm, 30, ...
        sprintf('%s, elektroda %.0f mm | dengan anomali\nlog10(|J|) (A/m^2), panah = arah J', ...
                cname{c}, median(D{c,2}.wspan)*1000), ...
        sprintf('%s | rata-rata |J| di anomali = %.3g A/m^2', exc{c}, D{c,2}.m_I), P, true);
end

%% Gambar 3: peta konduktivitas (cek bahwa anomali lingkaran penuh dan insulator terlihat)
figure('Position', [140 120 1050 500]);
for c = 1:2
    subplot(1,2,c);
    draw_panel_cc(D{c,2}, D{c,2}.Sig, [0 0.8], lm, 0, ...
        sprintf('%s | peta konduktivitas (S/m)', cname{c}), '', P, true);
end

%% Ringkasan eksitasi (homogen)
Jm = zeros(1,2);
for c = 1:2
    Jm(c) = max(D{c,1}.Jn(hypot(D{c,1}.xc, D{c,1}.yc) < R - t_ins));
    fprintf('%s (%s): |I| = %.3g A/m | max|J| di dalam tank = %.3g A/m^2\n', ...
        cname{c}, exc{c}, abs(D{c,1}.Iexc), Jm(c));
end
fprintf('Tegangan CCEIT agar max|J| sama dengan EIT 1 mA: %.3g V\n', V_cc*Jm(1)/Jm(2));
