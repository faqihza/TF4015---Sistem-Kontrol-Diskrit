clear; clc; clf;

% 1. Parameter Sinyal Asli (Kontinyu yang disimulasikan dengan resolusi tinggi)
f1 = 4;               % Frekuensi komponen 1 (Hz)
f2 = 1;               % Frekuensi komponen 2 (Hz)
t_end = 2;          % Durasi waktu total (detik)
t_fine = linspace(0, t_end, 2000); % Waktu kontinyu beresolusi tinggi

% Sinyal analog f(t) gabungan dua sinus
f_orig = 1.2 * sin(2 * pi * f1 * t_fine) + 0.5 * sin(2 * pi * f2 * t_fine);

% 2. Parameter Sampling
f_s = 9;             % Frekuensi sampling (Hz) -> Memenuhi syarat Nyquist (> 2*f2)
h = 1 / f_s;          % Periode sampling / interval waktu pencacahan (h)
t_samples = 0:h:t_end;% Titik-titik waktu sampling (kh)

% Mengambil nilai sampel sinyal f(kh)
f_samples = 1.2 * sin(2 * pi * f1 * t_samples) + 0.5 * sin(2 * pi * f2 * t_samples);

% 3. Proses Rekonstruksi Sinyal Menggunakan Rumus Interpolasi Shannon
% Rumus: f(t) = sum_{k} f(kh) * [sin(omega_s * (t - kh) / 2) / (omega_s * (t - kh) / 2)]
omega_s = 2 * pi * f_s; 
f_reconstructed = zeros(size(t_fine));

for i = 1:length(t_fine)
    sum_val = 0;
    for k = 1:length(t_samples)
        % Argumen untuk fungsi sinc sesuai rumus slide
        argument = omega_s * (t_fine(i) - t_samples(k)) / 2;
        
        % Menghindari pembagian dengan nol saat t_fine(i) == t_samples(k)
        if argument == 0
            sinc_val = 1;
        else
            sinc_val = sin(argument) / argument;
        end
        
        % Akumulasi superposisi dari setiap sampel f(kh) dikali fungsi sinc
        sum_val = sum_val + f_samples(k) * sinc_val;
    end
    f_reconstructed(i) = sum_val;
end

% 4. Visualisasi Hasil
fig = figure(2);
fig.Color='white';

plot(t_fine, f_orig, 'k--', 'LineWidth', 1.5); hold on;
stem(t_samples, f_samples, 'r', 'filled', 'LineWidth', 1.5);
plot(t_fine, f_reconstructed, 'b-', 'LineWidth', 1.2);

legend('Sinyal Asli f(t)', 'Sinyal Tercacah f(kh)', 'Sinyal Rekonstruksi Shannon', ...
       'Location', 'northeast');
xlabel('Waktu t (detik)');
ylabel('Amplitudo');
title('Rekonstruksi Sinyal Menggunakan Rumus Interpolasi Shannon');
grid on;
ylim([-2 2]);