clear; clf; clc;

% 1. Parameter Sinyal dan Sampling
f_s = 10;               % Frekuensi sampling (Hz)
omega_s = 2 * pi * f_s; % Frekuensi sudut sampling (rad/s)
kh = 0;                 % Posisi titik sampel ke-k (misal ditetapkan pada t = 0)

% 2. Rentang Waktu (t) di sekitar titik sampel
t = linspace(-0.4, 0.4, 1000);

% 3. Perhitungan Fungsi Sinc Tunggal (Single Term)
% Rumus: s_k(t) = sin(omega_s * (t - kh) / 2) / (omega_s * (t - kh) / 2)
argument = omega_s * (t - kh) / 2;

s_k = ones(size(t));    % Inisialisasi awal
non_zero_idx = (argument ~= 0);
s_k(non_zero_idx) = sin(argument(non_zero_idx)) ./ argument(non_zero_idx);

% 4. Visualisasi Grafik
fig = figure(1);
plot(t, s_k, 'b-', 'LineWidth', 1.8); hold on;

% Menandai titik puncak amplitudo = 1 pada t = kh
plot(kh, 1, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
text(kh, 1.12, 'Amplitudo = 1 pada t = kh', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'r');

% Garis bantu sumbu
line([t(1), t(end)], [0, 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 0.8);
line([kh, kh], [-0.4, 1.2], 'Color', 'r', 'LineStyle', ':', 'LineWidth', 1);

% Pengaturan Tampilan Grafik
grid on;
xlabel('Waktu (t)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('s_k(t)', 'FontSize', 11, 'FontWeight', 'bold');
title('Ilustrasi Sinc Interpolation Function: A Single Term', 'FontSize', 12, 'FontWeight', 'bold');
ylim([-0.4, 1.3]);
xlim([t(1), t(end)]);