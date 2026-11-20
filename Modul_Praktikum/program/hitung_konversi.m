%% hitung_konversi.m
% Menghitung faktor konversi kecepatan-posisi C (Modul 3, Percobaan 2) dari
% data kalang terbuka sketch SKD_Modul3 (ClosedLoop = false).
% Kolom data: Time | Delta | SP | Pos | Kec | MV | Motor
% Baris konfigurasi (diawali '#') dan baris judul kolom diabaikan otomatis.
%
% Data dibagi menjadi segmen dengan masukan MV tetap dan tidak nol. Pada tiap
% segmen, bagian awal (transien) diabaikan, posisi dibuka (unwrap) agar tidak
% berpindah dari 100 ke 0, lalu kemiringan posisi terhadap waktu dihitung
% dengan regresi linier. C = kemiringan / kecepatan rata-rata.

clc; clear; close all;

NamaFile = 'data_konversi.txt';
TAbaikan = 1000;    % lama awal tiap segmen yang diabaikan (ms)

Data = readmatrix(NamaFile, 'FileType', 'text', 'Delimiter', '\t', ...
    'NumHeaderLines', 0, 'CommentStyle', '#');
Data = Data(all(~isnan(Data(:, 1:7)), 2), :);
t   = Data(:,1);
Pos = Data(:,4);
Kec = Data(:,5);
MV  = Data(:,6);
PosU = buka(Pos);

% Batas segmen: indeks tempat masukan berubah
Batas = [1; find(diff(MV) ~= 0) + 1; numel(MV) + 1];
Hasil = zeros(0, 4);
fprintf('%9s %12s %16s %16s %12s\n', 'Masukan', 'Kec rata2', 'Kemiringan', 'C', 'Durasi');
fprintf('%9s %12s %16s %16s %12s\n', '(%)', '(%)', '(%/ms)', '(%/(ms.%))', '(ms)');
figure('Name', 'Faktor konversi'); hold on; grid on;
plot(t, PosU, 'Color', [0.7 0.7 0.7]);
for j = 1:numel(Batas) - 1
    Idx = (Batas(j):Batas(j+1) - 1)';
    if MV(Idx(1)) == 0, continue; end
    Idx = Idx(t(Idx) - t(Idx(1)) >= TAbaikan);
    if numel(Idx) < 20, continue; end
    Pf = polyfit(t(Idx), PosU(Idx), 1);
    V  = mean(Kec(Idx)) * sign(MV(Idx(1)));    % kecepatan bertanda sesuai arah masukan
    C  = Pf(1) / V;
    Hasil(end+1, :) = [MV(Idx(1)), V, Pf(1), C]; %#ok<SAGROW>
    fprintf('%9.0f %12.2f %16.5f %16.5f %12.0f\n', MV(Idx(1)), V, Pf(1), C, t(Idx(end)) - t(Idx(1)));
    plot(t(Idx), polyval(Pf, t(Idx)), 'r', 'LineWidth', 1.5);
end
xlabel('Waktu (ms)'); ylabel('Posisi tanpa batas 0-100 (%)');
legend('Posisi (unwrap)', 'Regresi tiap segmen', 'Location', 'best');

if isempty(Hasil)
    fprintf('\nTidak ada segmen yang cukup panjang. Tahan tiap masukan lebih lama dari %g ms.\n', TAbaikan);
else
    fprintf('\nRata-rata C = %.5f %%/(ms.%%)\n', mean(Hasil(:,4)));
    if any(Hasil(:,4) < 0)
        fprintf(['PERINGATAN: C bernilai negatif. Masukan positif menurunkan bacaan posisi,\n' ...
                 'sehingga kontrol posisi akan menjauhi set point. Laporkan kepada asisten.\n']);
    end
end

%% Fungsi bantu
function y = buka(x)
    % unwrap posisi dengan periode 100%
    y = x;
    for k = 2:numel(x)
        dx = mod(x(k) - x(k-1) + 50, 100) - 50;
        y(k) = y(k-1) + dx;
    end
end
