%% analisis_kontrol_posisi.m
% Menghitung performa kontrol posisi (Modul 3, Percobaan 4) dari data sketch
% SKD_Modul3 (ClosedLoop = true): delay time (50%), rise time (10-90%),
% overshoot, settling time (2%), dan offset untuk setiap perubahan set point.
% Kolom data: Time | Delta | SP | Pos | Kec | MV | Motor
% Baris konfigurasi (diawali '#') dan baris judul kolom diabaikan otomatis.
%
% Posisi dibuka (unwrap) dan target dihitung melalui jalur terpendek, sama
% seperti fungsi wrap_error() pada program, sehingga perubahan 90 -> 20 yang
% melewati 100/0 tetap dihitung dengan benar.

clc; clear; close all;

NamaFile = 'data_kontrol.txt';

Data = readmatrix(NamaFile, 'FileType', 'text', 'Delimiter', '\t', ...
    'NumHeaderLines', 0, 'CommentStyle', '#');
Data = Data(all(~isnan(Data(:, 1:7)), 2), :);
t   = Data(:,1);
SP  = Data(:,3);
Pos = Data(:,4);
MV  = Data(:,6);
PosU = buka(Pos);

% Awal tiap segmen set point (segmen pertama dimulai dari posisi awal)
Mulai = [1; find(diff(SP) ~= 0) + 1];
Akhir = [Mulai(2:end) - 1; numel(SP)];

fprintf('%15s %8s %8s %8s %8s %8s %8s\n', 'Step', 'td', 'tr', 'Mp', 'ts', 'Offset', '|u|maks');
fprintf('%15s %8s %8s %8s %8s %8s %8s\n', '(%)', '(ms)', '(ms)', '(%)', '(ms)', '(%)', '(%)');
for j = 1:numel(Mulai)
    Idx = Mulai(j):Akhir(j);
    if j == 1, Awal = PosU(1); Dari = Pos(1); else, Awal = PosU(Mulai(j) - 1); Dari = SP(Mulai(j) - 1); end
    Target = Awal + bungkus(SP(Mulai(j)) - mod(Awal, 100));
    if abs(Target - Awal) < 2, continue; end    % perubahan terlalu kecil untuk dianalisis
    P = kinerja(t(Idx) - t(Idx(1)), PosU(Idx), Awal, Target);
    fprintf('%6.0f -> %5.0f %8.0f %8.0f %8.1f %8.0f %8.2f %8.1f\n', Dari, SP(Mulai(j)), P, max(abs(MV(Idx))));
end
fprintf('\nCatatan: NaN berarti respons tidak mencapai kriteria (misalnya tidak masuk pita 2%%).\n');

figure('Name', 'Kontrol posisi');
subplot(2,1,1); stairs(t, SP, 'k--'); hold on; plot(t, Pos, 'b'); grid on;
ylabel('Posisi (%)'); legend('Set point', 'Posisi');
subplot(2,1,2); plot(t, MV, 'r'); grid on;
xlabel('Waktu (ms)'); ylabel('MV (%)');

%% Fungsi bantu
function P = kinerja(t, y, Awal, SP)
    % [delay time, rise time 10-90%, overshoot, settling time 2%, offset]
    s = (y - Awal) / (SP - Awal);
    sf = mean(s(end - max(1, round(0.1*numel(s))) + 1:end));
    td = waktu_pertama(t, s >= 0.5);
    tr = waktu_pertama(t, s >= 0.9) - waktu_pertama(t, s >= 0.1);
    OS = max(0, (max(s) - 1) * 100);
    Luar = find(abs(s - 1) > 0.02);
    if isempty(Luar), ts = t(1); elseif Luar(end) < numel(t), ts = t(Luar(end) + 1); else, ts = NaN; end
    P = [td, tr, OS, ts, (1 - sf)*(SP - Awal)];
end

function tw = waktu_pertama(t, Kondisi)
    k = find(Kondisi, 1);
    if isempty(k), tw = NaN; else, tw = t(k); end
end

function e = bungkus(e)
    % Membatasi selisih posisi pada rentang -50 hingga 50
    e = mod(e + 50, 100) - 50;
end

function y = buka(x)
    % unwrap posisi dengan periode 100%
    y = x;
    for k = 2:numel(x)
        dx = mod(x(k) - x(k-1) + 50, 100) - 50;
        y(k) = y(k-1) + dx;
    end
end
