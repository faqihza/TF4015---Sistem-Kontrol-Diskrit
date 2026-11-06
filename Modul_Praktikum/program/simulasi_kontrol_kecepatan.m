%% simulasi_kontrol_kecepatan.m
% Simulasi kontrol kecepatan motor DC (Modul 2).
% Plant FOPDT disimulasikan dengan langkah 1 ms, sedangkan pengontrol PID
% diskrit dijalankan setiap waktu cacah Ts dengan pembatas keluaran dan
% anti-windup yang sama dengan tab 5_control.ino.
%
% Skrip ini:
%   1. menghitung parameter Ziegler-Nichols dan Cohen-Coon,
%   2. mensimulasikan P, PI, PID untuk dua waktu cacah,
%   3. menghitung parameter performa (delay time, rise time, overshoot,
%      settling time, offset),
%   4. mensimulasikan parameter kustom hasil penalaan halus.

clc; clear; close all;

%% 1. Model sistem dari Modul 1 (waktu dalam ms)
K     = 0.85;      % penguatan
Tau   = 60;        % konstanta waktu (ms)
Theta = 30;        % waktu tunda (ms)
Ts1   = 10;        % waktu cacah pertama (ms)
Ts2   = 3*Ts1;     % waktu cacah kedua (ms)

SetPoint = 60;     % set point (%), sekitar 75% kecepatan maksimum
TSim     = 2000;   % durasi simulasi (ms)
UMin = 0; UMax = 100;

%% 2. Parameter Ziegler-Nichols dan Cohen-Coon
r = Theta / Tau;
% baris: P, PI, PID; kolom: Kp, Ti, Td (Ti = Inf berarti tanpa aksi integral)
ZN = [ Tau/(K*Theta),        Inf,                 0;
       0.9*Tau/(K*Theta),    3.33*Theta,          0;
       1.2*Tau/(K*Theta),    2*Theta,             0.5*Theta ];
CC = [ (Tau/(K*Theta))*(1 + r/3),     Inf,                            0;
       (Tau/(K*Theta))*(0.9 + r/12),  Theta*(30 + 3*r)/(9 + 20*r),    0;
       (Tau/(K*Theta))*(4/3 + r/4),   Theta*(32 + 6*r)/(13 + 8*r),    4*Theta/(11 + 2*r) ];
NamaKontrol = {'P', 'PI', 'PID'};
NamaMetode  = {'ZN', 'CC'};
Tabel = {ZN, CC};

fprintf('Parameter kontrol (Ti, Td dalam ms; Ki dalam 1/ms; Kd dalam ms)\n');
for m = 1:2
    for j = 1:3
        [Kp, Ki, Kd] = konversi(Tabel{m}(j, :));
        fprintf('  %s %-3s : Kp = %7.3f  Ti = %7.1f  Td = %6.1f  Ki = %8.5f  Kd = %7.2f\n', ...
            NamaMetode{m}, NamaKontrol{j}, Tabel{m}(j,1), Tabel{m}(j,2), Tabel{m}(j,3), Ki, Kd);
    end
end

%% 3. Simulasi kalang terbuka (pembanding data kit)
[tOL, yOL] = simulasi(K, Tau, Theta, Ts1, SetPoint, TSim, 0, 0, 0, UMin, UMax, false);
figure('Name', 'Kalang terbuka');
plot(tOL, yOL, 'LineWidth', 1.2); grid on;
xlabel('Waktu (ms)'); ylabel('Kecepatan (%)');
title(sprintf('Kalang terbuka, masukan %g%%', SetPoint));

%% 4. Simulasi kalang tertutup untuk semua kombinasi
fprintf('\nPerforma (td, tr, ts dalam ms; OS dan offset dalam %%)\n');
for Ts = [Ts1 Ts2]
    figure('Name', sprintf('Kalang tertutup Ts = %g ms', Ts));
    for m = 1:2
        subplot(1, 2, m); hold on; grid on;
        for j = 1:3
            [Kp, Ki, Kd] = konversi(Tabel{m}(j, :));
            [t, y] = simulasi(K, Tau, Theta, Ts, SetPoint, TSim, Kp, Ki, Kd, UMin, UMax, true);
            P = kinerja(t, y, SetPoint);
            fprintf('  Ts=%2g %s %-3s : td=%6.1f tr=%6.1f OS=%6.1f ts=%7.1f offset=%6.2f\n', ...
                Ts, NamaMetode{m}, NamaKontrol{j}, P);
            stairs(t, y, 'DisplayName', NamaKontrol{j});
        end
        yline(SetPoint, 'k--', 'HandleVisibility', 'off');
        xlabel('Waktu (ms)'); ylabel('Kecepatan (%)');
        title(sprintf('%s, Ts = %g ms', NamaMetode{m}, Ts)); legend('Location', 'southeast');
    end
end

%% 5. Parameter kustom (penalaan halus)
KpKustom = 2.0; KiKustom = 0.02; KdKustom = 0; TsKustom = Ts1;
[t, y] = simulasi(K, Tau, Theta, TsKustom, SetPoint, TSim, KpKustom, KiKustom, KdKustom, UMin, UMax, true);
P = kinerja(t, y, SetPoint);
fprintf('\nKustom: td=%6.1f tr=%6.1f OS=%6.1f ts=%7.1f offset=%6.2f\n', P);
figure('Name', 'Kustom'); stairs(t, y); grid on; yline(SetPoint, 'k--');
xlabel('Waktu (ms)'); ylabel('Kecepatan (%)'); title('Parameter kustom');

%% Fungsi bantu
function [Kp, Ki, Kd] = konversi(Baris)
    Kp = Baris(1);
    if isinf(Baris(2)), Ki = 0; else, Ki = Kp / Baris(2); end
    Kd = Kp * Baris(3);
end

function [tk, yk] = simulasi(K, Tau, Theta, Ts, SP, TSim, Kp, Ki, Kd, UMin, UMax, Tertutup)
    % Plant FOPDT (langkah 1 ms) dengan pengontrol PID diskrit setiap Ts
    N = TSim; d = round(Theta);
    ubuf = zeros(N + d + 1, 1);
    v = 0; u = 0; Acc = 0; LastE = 0; First = true;
    nk = floor((N - 1) / Ts) + 1; tk = zeros(nk, 1); yk = zeros(nk, 1); i = 0;
    for k = 0:N-1
        if mod(k, Ts) == 0
            if Tertutup
                e = SP - v;
                de = 0; if ~First, de = (e - LastE) / Ts; end
                First = false;
                u = Kp*e + Ki*(Acc + e*Ts) + Kd*de;
                if u > UMax
                    u = UMax; if e < 0, Acc = Acc + e*Ts; end
                elseif u < UMin
                    u = UMin; if e > 0, Acc = Acc + e*Ts; end
                else
                    Acc = Acc + e*Ts;
                end
                LastE = e;
            else
                u = SP;
            end
            i = i + 1; tk(i) = k; yk(i) = v;
        end
        ubuf(k + 1 + d) = u;                 % masukan tertunda Theta
        v = v + (K*ubuf(k + 1) - v) / Tau;   % Euler, langkah 1 ms
    end
end

function P = kinerja(t, y, SP)
    % [delay time, rise time 10-90%, overshoot, settling time 2%, offset]
    yf = mean(y(end - max(1, round(0.1*numel(y))) + 1:end));
    td = waktu_pertama(t, y >= 0.5*yf);
    tr = waktu_pertama(t, y >= 0.9*yf) - waktu_pertama(t, y >= 0.1*yf);
    OS = max(0, (max(y) - yf) / yf * 100);
    luar = find(abs(y - yf) > 0.02*abs(yf));
    if isempty(luar), ts = t(1); elseif luar(end) < numel(t), ts = t(luar(end) + 1); else, ts = NaN; end
    P = [td, tr, OS, ts, SP - yf];
end

function tw = waktu_pertama(t, Kondisi)
    k = find(Kondisi, 1);
    if isempty(k), tw = NaN; else, tw = t(k); end
end
