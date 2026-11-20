%% simulasi_kontrol_posisi.m
% Simulasi kontrol posisi motor DC (Modul 3).
% Model posisi diturunkan dari model kecepatan (Modul 1):
%   G_p(s) = C * K * exp(-Theta s) / ( s (Tau s + 1) )
% dengan C adalah faktor konversi kecepatan (%) ke laju posisi (%/ms).
%
% Skrip ini:
%   1. mensimulasikan respons kalang terbuka posisi,
%   2. mensimulasikan kontrol P dengan Kp uji untuk mencari Kcr dan Pcr
%      secara manual (metode Ziegler-Nichols kalang tertutup),
%   3. menghitung Kcr dan Pcr dari model diskrit sebagai pembanding,
%   4. mensimulasikan parameter Ziegler-Nichols kalang tertutup dan kustom.

clc; clear; close all;

%% 1. Model sistem (waktu dalam ms)
K     = 0.85;      % penguatan model kecepatan (Modul 1)
Tau   = 60;        % konstanta waktu (ms)
Theta = 30;        % waktu tunda (ms)
C     = 0.02;      % konversi kecepatan ke laju posisi (%/ms per %), dari Percobaan 2
Ts    = 10;        % waktu cacah (ms), gunakan waktu cacah pertama

UMax     = 40;     % batas aksi kontrol (%)
Awal     = 50;     % posisi awal (%)
SetPoint = 70;     % set point posisi (%)
TSim     = 3000;   % durasi simulasi (ms)

%% 2. Kalang terbuka: masukan step 20%
[t, p] = simulasi(K, Tau, Theta, C, Ts, Awal, 0, TSim, 0, 0, 0, UMax, 20);
figure('Name', 'Kalang terbuka');
plot(t, p, 'LineWidth', 1.2); grid on;
xlabel('Waktu (ms)'); ylabel('Posisi (%, tanpa batas 0-100)');
title('Respons posisi kalang terbuka untuk masukan step 20%');

%% 3. Mencari Kcr dan Pcr secara manual
% Naikkan KpUji sampai respons berosilasi dengan amplitudo tetap.
KpUji = 1.0;
[t, p] = simulasi(K, Tau, Theta, C, Ts, Awal, SetPoint, TSim, KpUji, 0, 0, Inf, []);
figure('Name', 'Uji Kcr');
stairs(t, p); grid on; yline(SetPoint, 'k--');
xlabel('Waktu (ms)'); ylabel('Posisi (%)'); title(sprintf('Kontrol P, Kp = %g', KpUji));

%% 4. Pembanding: Kcr dan Pcr dari model diskrit
[Kcr, Pcr] = titik_kritis(K, Tau, Theta, C, Ts);
fprintf('Dari model diskrit: Kcr = %.3f, Pcr = %.1f ms\n', Kcr, Pcr);

%% 5. Ziegler-Nichols kalang tertutup
% baris: P, PI, PID, PID overshoot kecil, PID tanpa overshoot; kolom: Kp, Ti, Td
ZN = [ 0.5*Kcr,   Inf,      0;
       0.45*Kcr,  Pcr/1.2,  0;
       0.6*Kcr,   Pcr/2,    Pcr/8;
       0.33*Kcr,  Pcr/2,    Pcr/3;
       0.2*Kcr,   Pcr/2,    Pcr/3 ];
Nama = {'P', 'PI', 'PID', 'PID OS kecil', 'PID tanpa OS'};
figure('Name', 'Ziegler-Nichols kalang tertutup'); hold on; grid on;
fprintf('\n%-13s %8s %8s %7s %9s %8s | %7s %7s %6s %7s %7s\n', 'Kontrol', 'Kp', 'Ti', 'Td', 'Ki', 'Kd', ...
    'td', 'tr', 'OS', 'ts', 'offset');
for j = 1:5
    Kp = ZN(j, 1);
    if isinf(ZN(j, 2)), Ki = 0; else, Ki = Kp / ZN(j, 2); end
    Kd = Kp * ZN(j, 3);
    [t, p] = simulasi(K, Tau, Theta, C, Ts, Awal, SetPoint, TSim, Kp, Ki, Kd, UMax, []);
    P = kinerja(t, p, Awal, SetPoint);
    fprintf('%-13s %8.3f %8.1f %7.1f %9.5f %8.2f | %7.1f %7.1f %6.1f %7.1f %7.2f\n', ...
        Nama{j}, Kp, ZN(j,2), ZN(j,3), Ki, Kd, P);
    stairs(t, p, 'DisplayName', Nama{j});
end
yline(SetPoint, 'k--', 'HandleVisibility', 'off');
xlabel('Waktu (ms)'); ylabel('Posisi (%)'); legend('Location', 'southeast');

%% 6. Parameter kustom
KpKustom = 0.6; KiKustom = 0; KdKustom = 20;
[t, p] = simulasi(K, Tau, Theta, C, Ts, Awal, SetPoint, TSim, KpKustom, KiKustom, KdKustom, UMax, []);
P = kinerja(t, p, Awal, SetPoint);
fprintf('\nKustom: td=%.1f tr=%.1f OS=%.1f ts=%.1f offset=%.2f\n', P);
figure('Name', 'Kustom'); stairs(t, p); grid on; yline(SetPoint, 'k--');
xlabel('Waktu (ms)'); ylabel('Posisi (%)'); title('Parameter kustom');

%% Fungsi bantu
function [tk, pk] = simulasi(K, Tau, Theta, C, Ts, P0, SP, TSim, Kp, Ki, Kd, UMax, UBuka)
    % Bila UBuka tidak kosong, simulasi kalang terbuka dengan masukan UBuka.
    N = TSim; d = round(Theta);
    ubuf = zeros(N + d + 1, 1);
    v = 0; p = P0; u = 0; Acc = 0; LastE = 0; First = true;
    nk = floor((N - 1) / Ts) + 1; tk = zeros(nk, 1); pk = zeros(nk, 1); i = 0;
    for k = 0:N-1
        if mod(k, Ts) == 0
            if isempty(UBuka)
                e = SP - p;
                de = 0; if ~First, de = (e - LastE) / Ts; end
                First = false;
                u = Kp*e + Ki*(Acc + e*Ts) + Kd*de;
                if u > UMax
                    u = UMax; if e < 0, Acc = Acc + e*Ts; end
                elseif u < -UMax
                    u = -UMax; if e > 0, Acc = Acc + e*Ts; end
                else
                    Acc = Acc + e*Ts;
                end
                LastE = e;
            else
                u = UBuka;
            end
            i = i + 1; tk(i) = k; pk(i) = p;
        end
        ubuf(k + 1 + d) = u;
        v = v + (K*ubuf(k + 1) - v) / Tau;   % kecepatan (%)
        p = p + C*v;                         % posisi (%), langkah 1 ms
    end
end

function [Kcr, Pcr] = titik_kritis(K, Tau, Theta, C, Ts)
    % Gain P terkecil yang membuat model diskrit (dengan waktu tunda) tidak stabil
    a = exp(-Ts/Tau);
    A = [1, C*Tau*(1 - a); 0, a];
    B = [C*K*(Ts - Tau*(1 - a)); K*(1 - a)];
    d = round(Theta/Ts);
    Kcr = NaN; Pcr = NaN;
    for Kp = 0.005:0.005:50
        M = matriks_tertutup(A, B, d, Kp);
        ev = eig(M);
        [rho, idx] = max(abs(ev));
        if rho > 1
            Kcr = Kp;
            Pcr = 2*pi / abs(angle(ev(idx))) * Ts;
            return;
        end
    end
end

function M = matriks_tertutup(A, B, d, Kp)
    % Keadaan: [posisi; kecepatan; u[k-1]; ...; u[k-d]], u[k] = -Kp*posisi
    n = 2 + d;
    M = zeros(n);
    M(1:2, 1:2) = A;
    if d == 0
        M(1:2, 1) = M(1:2, 1) - Kp*B;
    else
        M(1:2, n) = B;
        M(3, 1) = -Kp;
        for i = 2:d
            M(2 + i, 1 + i) = 1;
        end
    end
end

function P = kinerja(t, y, Awal, SP)
    % [delay time, rise time 10-90%, overshoot, settling time 2%, offset] terhadap perubahan set point
    s = (y - Awal) / (SP - Awal);
    sf = mean(s(end - max(1, round(0.1*numel(s))) + 1:end));
    td = waktu_pertama(t, s >= 0.5);
    tr = waktu_pertama(t, s >= 0.9) - waktu_pertama(t, s >= 0.1);
    OS = max(0, (max(s) - 1) * 100);
    luar = find(abs(s - 1) > 0.02);
    if isempty(luar), ts = t(1); elseif luar(end) < numel(t), ts = t(luar(end) + 1); else, ts = NaN; end
    P = [td, tr, OS, ts, (1 - sf)*(SP - Awal)];
end

function tw = waktu_pertama(t, Kondisi)
    k = find(Kondisi, 1);
    if isempty(k), tw = NaN; else, tw = t(k); end
end
