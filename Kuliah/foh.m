clear; clf; clc;

% 1. Parameter Sinyal Asli
f = 1;                  % Frekuensi sinyal sinus (Hz)
t_end = 1;              % Durasi total (detik)
t_fine = linspace(0, t_end, 2000); % Waktu kontinyu resolusi tinggi
x_orig = sin(2 * pi * f * t_fine); % Sinyal analog asli

% 2. Parameter Sampling
T_s = 1/(f*10);                % Periode sampling (h)
t_samples = 0:T_s:t_end;  % Titik-titik waktu pencacahan (t_k)
x_samples = sin(2 * pi * f * t_samples); % Nilai sampel f(t_k)

% 3. Proses Rekonstruksi First-Order Hold (FOH)
% Menggunakan interpolasi linier antar titik sampel berurutan
x_foh = zeros(size(t_fine));

for i = 1:length(t_fine)
    t_val = t_fine(i);
    % Cari indeks k di mana t_k <= t_val
    idx = find(t_samples <= t_val, 1, 'last');
    
    if isempty(idx)
        x_foh(i) = x_samples(1);
    elseif idx >= length(t_samples)
        x_foh(i) = x_samples(end);
    else
        % Mengambil dua titik sampel: t_k dan t_{k+1} untuk interpolasi linier
        tk = t_samples(idx);
        tk_next = t_samples(idx+1);
        fk = x_samples(idx);
        fk_next = x_samples(idx+1);
        
        % Formula FOH (Interpolasi Linier antar segmen sampel)
        x_foh(i) = fk + ((t_val - tk) / (tk_next - tk)) * (fk_next - fk);
    end
end

% 4. Visualisasi Grafik
fig=figure(1);

plot(t_fine, x_orig, 'k--', 'LineWidth', 1.2); hold on;
stem(t_samples, x_samples, 'r', 'filled', 'LineWidth', 1.5);
plot(t_fine, x_foh, 'b-', 'LineWidth', 1.8);

legend('Sinyal Asli (Analog)', 'Sampel Diskrit', 'Rekonstruksi First-Order Hold (FOH)', ...
       'Location', 'northeast');
xlabel('Waktu (detik)');
ylabel('Amplitudo');
title('Simulasi Rekonstruksi Sinyal dengan First-Order Hold (FOH)');
grid on;
ylim([-1.4 1.4]);