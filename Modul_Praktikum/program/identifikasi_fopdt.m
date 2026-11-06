%% identifikasi_fopdt.m
% Identifikasi model orde satu dengan waktu tunda (FOPDT) dari data respons
% step kit praktikum Sistem Kontrol Diskrit (Modul 1).
%
% Data berasal dari program utama 7_main_step yang disalin dari Serial
% Monitor ke file teks (.txt) atau .csv dengan kolom:
%   Time (ms) | Delta (ms) | Input (%) | Motor (%) | Kec (%)
%
% Skrip ini:
%   1. mencari setiap step masukan naik (Delta U > 0),
%   2. menghitung K, tau, dan theta setiap step dengan metode dua titik
%      (28,3% dan 63,2%),
%   3. menghitung model diskrit (ZOH) untuk dua waktu cacah,
%   4. membandingkan respons model diskrit dengan data.

clc; clear; close all;

%% 1. Pengaturan
NamaFile      = 'data_step.txt';  % nama file data
KolomWaktu    = 1;                % kolom waktu (ms)
KolomMasukan  = 3;                % kolom masukan (%)
KolomKeluaran = 5;                % kolom kecepatan (%)
FraksiTunak   = 0.3;              % porsi akhir tiap segmen untuk nilai tunak
LebarFilter   = 3;                % lebar rata-rata bergerak untuk mencari titik lintas

Ts1 = 10;                         % waktu cacah pertama (ms), ubah sesuai pilihan kelompok
Ts2 = 3*Ts1;                      % waktu cacah kedua (ms)

% Parameter manual: isi dengan model final kelompok untuk memvalidasi model
% pada data baru (Percobaan 6). Bila false, digunakan median hasil step.
GunakanParameterManual = false;
K_manual     = 0.9;               % (-)
Tau_manual   = 60;                % (ms)
Theta_manual = 30;                % (ms)

%% 2. Membaca data
Data = readmatrix(NamaFile);
Kolom = [KolomWaktu KolomMasukan KolomKeluaran];
Data = Data(all(~isnan(Data(:, Kolom)), 2), :);   % buang baris teks / kosong
t = Data(:, KolomWaktu);
u = Data(:, KolomMasukan);
y = Data(:, KolomKeluaran);
t = t - t(1);
N = numel(t);

%% 3. Identifikasi parameter setiap step naik
IndeksStep = find(diff(u) ~= 0) + 1;     % sampel pertama setelah masukan berubah
Batas = [1; IndeksStep; N + 1];          % segmen ke-j: Batas(j) .. Batas(j+1)-1

Hasil = [];
for i = 1:numel(IndeksStep)
    SegSebelum = Batas(i):Batas(i+1)-1;
    SegSesudah = Batas(i+1):Batas(i+2)-1;
    U0 = u(SegSebelum(1));
    U1 = u(SegSesudah(1));
    dU = U1 - U0;
    if dU <= 0
        continue;                        % hanya step naik yang diidentifikasi
    end

    Y0 = mean(y(SegSebelum(end - porsi(numel(SegSebelum), FraksiTunak) + 1:end)));
    Y1 = mean(y(SegSesudah(end - porsi(numel(SegSesudah), FraksiTunak) + 1:end)));
    dY = Y1 - Y0;
    K  = dY / dU;

    tt = t(SegSesudah) - t(SegSesudah(1));
    r  = (movmean(y(SegSesudah), LebarFilter) - Y0) / dY;   % respons ternormalisasi
    t28 = waktu_lintas(tt, r, 0.283);
    t63 = waktu_lintas(tt, r, 0.632);
    Tau   = 1.5 * (t63 - t28);
    Theta = t63 - Tau;
    if Theta < 0
        warning('Step %g -> %g: waktu tunda negatif (%.1f ms), periksa data.', U0, U1, Theta);
    end

    Hasil(end+1, :) = [U0 U1 dU Y0 Y1 dY K Tau Theta]; %#ok<SAGROW>
end

if isempty(Hasil)
    error('Tidak ditemukan step masukan naik pada data.');
end

TabelHasil = array2table(Hasil, 'VariableNames', ...
    {'U0','U1','dU','Y0','Y1','dY','K','Tau_ms','Theta_ms'});
disp('Hasil identifikasi setiap step:');
disp(TabelHasil);

%% 4. Nilai yang mewakili sistem
% Secara bawaan digunakan median. Ganti dengan nilai pilihan kelompok bila
% ada alasan yang lebih kuat (misalnya hanya memakai daerah linier).
if GunakanParameterManual
    K     = K_manual;
    Tau   = Tau_manual;
    Theta = Theta_manual;
else
    K     = median(Hasil(:, 7));
    Tau   = median(Hasil(:, 8));
    Theta = max(median(Hasil(:, 9)), 0);
end
fprintf('\nModel kontinu: G(s) = %.3f e^(-%.1f s) / (%.1f s + 1)   [s dalam ms]\n', ...
    K, Theta, Tau);

%% 5. Model diskrit (ZOH) untuk dua waktu cacah
fprintf('\nModel diskrit y[k+1] = a y[k] + b u[k-d]:\n');
for Ts = [Ts1 Ts2]
    a = exp(-Ts / Tau);
    b = K * (1 - a);
    d = round(Theta / Ts);
    fprintf('  Ts = %3g ms : a = %.4f, b = %.4f, d = %d  ->  G(z) = %.4f z^-%d / (1 - %.4f z^-1)\n', ...
        Ts, a, b, d, b, d + 1, a);
end

%% 6. Validasi: simulasi model diskrit pada waktu cacah data
Tdata = median(diff(t));
a = exp(-Tdata / Tau);
b = K * (1 - a);
d = round(Theta / Tdata);
ym = zeros(N, 1);
ym(1) = y(1);
for k = 1:N-1
    if k - d >= 1
        uk = u(k - d);
    else
        uk = u(1);
    end
    ym(k + 1) = a * ym(k) + b * uk;
end
RMSE = sqrt(mean((y - ym).^2));
fprintf('\nValidasi pada Ts data = %g ms: RMSE = %.2f %%\n', Tdata, RMSE);

figure;
stairs(t, u, 'k-.'); hold on;
plot(t, y, 'b-');
stairs(t, ym, 'r-', 'LineWidth', 1.2);
grid on;
xlabel('Waktu (ms)'); ylabel('Persen');
legend('Masukan', 'Kecepatan terukur', 'Model diskrit', 'Location', 'best');
title(sprintf('K = %.3f, \\tau = %.1f ms, \\theta = %.1f ms, RMSE = %.2f%%', K, Tau, Theta, RMSE));

%% Fungsi bantu
function n = porsi(Panjang, Fraksi)
    n = max(1, round(Fraksi * Panjang));
end

function tc = waktu_lintas(tt, r, Level)
    % waktu pertama respons ternormalisasi r melintasi Level (interpolasi linier)
    k = find(r >= Level, 1, 'first');
    if isempty(k)
        tc = NaN;
    elseif k == 1
        tc = tt(1);
    else
        tc = tt(k-1) + (Level - r(k-1)) * (tt(k) - tt(k-1)) / (r(k) - r(k-1));
    end
end
