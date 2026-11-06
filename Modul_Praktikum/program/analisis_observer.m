%% analisis_observer.m
% Analisis data percobaan observer (Modul 4) dari program 11_main_state_space.
% Kolom data: Time | Delta | Ref | Pos | PosHat | PosHatT | VelT | VelHat | U

clc; clear; close all;

NamaFile = 'data_observer.txt';
C  = 0.02;          % konversi kecepatan ke laju posisi (%/ms per %), dari Modul 3
VelMin = 5;         % batas kecepatan (%) untuk membandingkan estimasi dengan tachometer

Data = readmatrix(NamaFile);
Data = Data(all(~isnan(Data(:, 1:9)), 2), :);
t      = Data(:,1) - Data(1,1);
Ref    = Data(:,3);
Pos    = Data(:,4);
PosHat = Data(:,5);
PosHatT= Data(:,6);
VelT   = Data(:,7);
VelHat = Data(:,8);
U      = Data(:,9);

% Posisi tanpa batas 0-100 (unwrap dengan periode 100%)
PosU     = buka(Pos);
PosHatTU = buka(PosHatT);

% Kecepatan dari turunan numerik posisi (pembanding sederhana)
VelDiff = [0; diff(PosU) ./ diff(t)] / C;

%% Observer A: estimasi kecepatan dari potensiometer
Bergerak = abs(VelT) > VelMin;
RMSE_A = sqrt(mean((VelHat(Bergerak) - VelT(Bergerak)).^2));
RMSE_D = sqrt(mean((VelDiff(Bergerak) - VelT(Bergerak)).^2));
fprintf('RMSE kecepatan observer A terhadap tachometer : %.2f %%\n', RMSE_A);
fprintf('RMSE kecepatan turunan numerik posisi        : %.2f %%\n', RMSE_D);

figure('Name', 'Observer A');
plot(t, VelT, 'b.', t, VelDiff, 'Color', [0.6 0.6 0.6]); hold on;
plot(t, VelHat, 'r', 'LineWidth', 1.2); grid on;
xlabel('Waktu (ms)'); ylabel('Kecepatan (%)');
legend('Tachometer bertanda', 'Turunan numerik posisi', 'Estimasi observer A');

%% Observer B: estimasi posisi dari tachometer
ErrB = PosHatTU - PosU;
fprintf('Error posisi observer B: awal %.2f %%, akhir %.2f %%, maksimum %.2f %%\n', ...
    ErrB(1), ErrB(end), max(abs(ErrB)));

figure('Name', 'Observer B');
subplot(2,1,1); plot(t, PosU, 'k', t, PosHatTU, 'r'); grid on;
ylabel('Posisi (%, tanpa batas)'); legend('Potensiometer', 'Estimasi observer B');
subplot(2,1,2); plot(t, ErrB, 'r'); grid on;
xlabel('Waktu (ms)'); ylabel('Error posisi (%)');

%% Fungsi bantu
function y = buka(x)
    % unwrap posisi dengan periode 100%
    y = x;
    for k = 2:numel(x)
        dx = x(k) - x(k-1);
        dx = mod(dx + 50, 100) - 50;
        y(k) = y(k-1) + dx;
    end
end
