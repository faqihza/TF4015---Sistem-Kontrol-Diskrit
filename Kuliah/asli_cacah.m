clear; clf; clc;

% 1. Parameter Sinyal Asli & Waktu
f_max = 2;                  % Frekuensi maksimum sinyal (Hz)
t_end = 2;                  % Durasi waktu (detik)
t_fine = linspace(0, t_end, 2000); % Waktu kontinyu beresolusi tinggi

% Sinyal analog f(t) gabungan beberapa komponen frekuensi
f_t = sin(2 * pi * 1 * t_fine) + 0.5 * sin(2 * pi * f_max * t_fine);

% 2. Parameter Sampling (Pencacahan)
f_s = 3;                   % Frekuensi sampling (Hz) -> Memenuhi syarat Nyquist (f_s > 2*f_max)
h = 1 / f_s;                % Periode sampling (h)
t_samples = 0:h:t_end;      % Titik-titik waktu pencacahan (kh)
f_samples = sin(2 * pi * 1 * t_samples) + 0.5 * sin(2 * pi * f_max * t_samples);

% 3. Analisis Transformasi Fourier (Domain Frekuensi Menggunakan FFT)
N = length(t_fine);
frequencies = linspace(-f_s*2, f_s*2, N);

% Spektrum Sinyal Asli F(omega) secara numerik
F_omega = fftshift(fft(f_t)) / N;

% Spektrum Sinyal Tercacah F_s(omega) (replika periodik akibat pencacahan)
% Sesuai rumus: F_s(omega) = (1/h) * sum( F(omega + k*omega_s) )
omega_s = 2 * pi * f_s;
Fs_omega = zeros(size(frequencies));
for k = -3:3
    % Menggeser spektrum sejauh kelipatan frekuensi sudut sampling (omega_s)
    shift_idx = round(k * f_s * (N / (f_s*4)));
    Fs_omega = Fs_omega + circshift(F_omega, [0, shift_idx]);
end
Fs_omega = Fs_omega / h; % Skala amplitudo sesuai rumus 1/h

% 4. Visualisasi Grafik Perbandingan
fig = figure(3);

% Grafik 1: Sinyal Asli di Domain Waktu f(t)
subplot(2, 2, 1);
plot(t_fine, f_t, 'b-', 'LineWidth', 1.5);
title('Sinyal Asli f(t) [Domain Waktu]');
xlabel('Waktu (t)'); ylabel('Amplitudo');
grid on;

% Grafik 2: Sinyal Tercacah di Domain Waktu f(kh)
subplot(2, 2, 2);
stem(t_samples, f_samples, 'r', 'filled', 'LineWidth', 1.5); hold on;
plot(t_fine, f_t, 'k--', 'LineWidth', 0.8);
title('Sinyal Tercacah f(kh) [Deretan Sampel Diskrit]');
xlabel('Waktu (t)'); ylabel('Amplitudo');
legend('Sampel f(kh)', 'Sinyal Asli', 'Location', 'northeast');
grid on;

% Grafik 3: Spektrum Frekuensi Sinyal Asli F(omega)
subplot(2, 2, 3);
plot(frequencies, abs(F_omega), 'b-', 'LineWidth', 1.5);
title('Spektrum Sinyal Asli F(\omega) [Batas Nyquist]');
xlabel('Frekuensi (Hz)'); ylabel('|F(\omega)|');
xlim([-10 10]);
grid on;

% Grafik 4: Spektrum Sinyal Tercacah F_s(omega) (Pergeseran Spektral / Aliasing)
subplot(2, 2, 4);
plot(frequencies, abs(Fs_omega), 'r-', 'LineWidth', 1.2);
title('Spektrum Sinyal Tercacah F_s(\omega) [Replika Periodik]');
xlabel('Frekuensi (Hz)'); ylabel('|F_s(\omega)|');
xlim([-15 15]);
grid on;