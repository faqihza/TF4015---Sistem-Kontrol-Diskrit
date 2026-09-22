clear; clf; clc;

% 1. Parameter Sinyal Asli
f = 1;                  % Frekuensi sinyal sinus (Hz)
t_end = 1;              % Durasi total (detik)
t_fine = linspace(0, t_end, 2000); % Waktu kontinyu resolusi tinggi
x_orig = sin(2 * pi * f * t_fine); % Sinyal analog asli

% 2. Parameter Sampling
T_s = 1/(f*5);               % Periode sampling (detik)
t_samples = 0:T_s:t_end;  % Titik-titik waktu pencacahan
x_samples = sin(2 * pi * f * t_samples); % Nilai amplitudo sampel diskrit

% 3. Proses Rekonstruksi Zero-Order Hold (ZOH)
% Menahan nilai sampel konstan selama satu periode sampling T_s
x_zoh = zeros(size(t_fine));
for i = 1:length(t_fine)
    % Mencari indeks sampel aktif yang paling dekat di sebelah kiri waktu t_fine(i)
    idx = find(t_samples <= t_fine(i), 1, 'last');
    if isempty(idx)
        idx = 1;
    end
    x_zoh(i) = x_samples(idx);
end

% 4. Visualisasi Grafik
fig=figure(2)

plot(t_fine, x_orig, 'k--', 'LineWidth', 1.2); hold on;
stem(t_samples, x_samples, 'r', 'filled', 'LineWidth', 1.5);
stairs(t_fine, x_zoh, 'b-', 'LineWidth', 1.8);

legend('Sinyal Asli (Analog)', 'Sampel Diskrit', 'Rekonstruksi Zero-Order Hold (ZOH)', ...
       'Location', 'northeast');
xlabel('Waktu (detik)');
ylabel('Amplitudo');
title('Simulasi Rekonstruksi Sinyal dengan Zero-Order Hold (ZOH)');
grid on;
ylim([-1.4 1.4]);