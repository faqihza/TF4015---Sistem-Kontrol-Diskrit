%% desain_state_space.m
% Desain pole placement dan observer untuk kit praktikum SKD (Modul 4).
%
% Keadaan x = [posisi (%); kecepatan bertanda (%)], masukan u (%).
% Model diskrit (ZOH, waktu tunda diabaikan pada desain):
%   x[k+1] = A x[k] + B u[k]
%   A = [1, C*Tau*(1-a); 0, a],  B = [C*K*(Ts - Tau*(1-a)); K*(1-a)],  a = exp(-Ts/Tau)
%
% Skrip ini:
%   1. menghitung A dan B, keterkendalian, dan keteramatan,
%   2. menghitung gain pole placement kecepatan (1 keadaan) dan posisi (2 keadaan),
%   3. menghitung gain observer kecepatan dari potensiometer (observer A)
%      dan estimator posisi dari tachometer (observer B),
%   4. mensimulasikan sistem dengan waktu tunda, saturasi, dan derau sensor,
%   5. menampilkan baris program untuk disalin ke 11_main_state_space.ino.

clc; clear; close all;

%% 1. Parameter model (waktu dalam ms)
K     = 0.85;     % penguatan (Modul 1)
Tau   = 60;       % konstanta waktu (ms) (Modul 1)
Theta = 30;       % waktu tunda (ms) (Modul 1), hanya untuk simulasi
C     = 0.02;     % konversi kecepatan ke laju posisi (%/ms per %) (Modul 3)
Ts    = 10;       % waktu cacah (ms)
UMax  = 40;       % batas masukan kontrol posisi (%)

%% 2. Spesifikasi desain
TauSpeed = 30;    % konstanta waktu kalang tertutup kontrol kecepatan (ms)
Zeta     = 0.8;   % rasio redaman kontrol posisi
TsPos    = 400;   % settling time 2% kontrol posisi (ms)
ZetaObs  = 0.8;   % rasio redaman observer A
TsObs    = 100;   % settling time observer A (ms), lebih cepat dari kontrol
TauObsV  = 20;    % konstanta waktu koreksi kecepatan observer B (ms)

%% 3. Model diskrit, keterkendalian, dan keteramatan
a = exp(-Ts/Tau);
A = [1, C*Tau*(1 - a); 0, a];
B = [C*K*(Ts - Tau*(1 - a)); K*(1 - a)];
Cpos = [1 0];     % keluaran potensiometer
Cvel = [0 1];     % keluaran tachometer
Wc   = [B, A*B];
WoP  = [Cpos; Cpos*A];
WoV  = [Cvel; Cvel*A];
fprintf('A = [%.5f %.5f; %.5f %.5f],  B = [%.6f; %.6f]\n', A', B);
fprintf('Rank matriks keterkendalian           : %d\n', rank(Wc));
fprintf('Rank matriks keteramatan (posisi)     : %d\n', rank(WoP));
fprintf('Rank matriks keteramatan (kecepatan)  : %d\n', rank(WoV));

%% 4. Pole placement kecepatan: u = Nspeed*r - Kspeed*v
zSpeed = exp(-Ts/TauSpeed);
Kspeed = (a - zSpeed) / B(2);
Nspeed = (1 - zSpeed) / B(2);

%% 5. Pole placement posisi: u = -(Kpos*(p - r) + Kvel*v)
zCtrl = kutub_diskrit(Zeta, TsPos, Ts);
Kf = ackermann(A, B, zCtrl);
Kpos = Kf(1); Kvel = Kf(2);

%% 6. Observer A (posisi terukur) dan observer B (kecepatan terukur)
zObs = kutub_diskrit(ZetaObs, TsObs, Ts);
Lp = ackermann(A', Cpos', zObs)';      % dualitas: L = acker(A', C', p)'
zVel = exp(-Ts/TauObsV);
Lv = [A(1,2); a - zVel];               % Lv1 = A12: posisi = integral kecepatan terukur

fprintf('\nKutub kontrol posisi : %s\n', mat2str(eig(A - B*Kf).', 4));
fprintf('Kutub observer A     : %s\n', mat2str(eig(A - Lp*Cpos).', 4));
fprintf('Kutub observer B     : %s\n', mat2str(eig(A - Lv*Cvel).', 4));

fprintf('\n// ---- salin ke setup() pada 11_main_state_space.ino ----\n');
fprintf('ModelK = %.4f;  ModelTau = %.2f;  ModelC = %.5f;\n', K, Tau, C);
fprintf('Kspeed = %.4f;  Nspeed = %.4f;\n', Kspeed, Nspeed);
fprintf('Kpos = %.4f;  Kvel = %.4f;\n', Kpos, Kvel);
fprintf('Lp1 = %.4f;  Lp2 = %.4f;\n', Lp(1), Lp(2));
fprintf('Lv1 = %.4f;  Lv2 = %.4f;\n', Lv(1), Lv(2));
fprintf('// TimeSampling = %g;\n', Ts);

%% 7. Simulasi
Prm = struct('K', K, 'Tau', Tau, 'Theta', Theta, 'C', C, 'Ts', Ts, 'UMax', UMax, ...
    'Kspeed', Kspeed, 'Nspeed', Nspeed, 'Kpos', Kpos, 'Kvel', Kvel, 'Lp', Lp, 'Lv', Lv, ...
    'A', A, 'B', B, 'TachoMin', 3, 'Derau', 0.5);

% (a) Kalang terbuka: uji kedua observer
S = simulasi(Prm, 0, [0 30 0 -30 0 60 0 -60 0], 3000, true);
figure('Name', 'Observer (kalang terbuka)');
subplot(2,1,1); plot(S.t, S.v, 'k', S.t, S.vT, 'b.', S.t, S.vHat, 'r'); grid on;
legend('Kecepatan sebenarnya', 'Tachometer bertanda', 'Estimasi observer A');
ylabel('Kecepatan (%)');
subplot(2,1,2); plot(S.t, S.pTrue, 'k', S.t, S.pHatT, 'r'); grid on;
legend('Posisi sebenarnya (tanpa batas)', 'Estimasi observer B');
xlabel('Waktu (ms)'); ylabel('Posisi (%)');

% (b) Pole placement kecepatan
S = simulasi(Prm, 1, [0 40 70 30 0], 1500, true);
figure('Name', 'Pole placement kecepatan');
stairs(S.t, S.r, 'k--'); hold on; plot(S.t, S.v, 'b'); grid on;
xlabel('Waktu (ms)'); ylabel('Kecepatan (%)'); legend('Set point', 'Kecepatan');

% (c) Pole placement posisi: observer vs tachometer bertanda
Ref = [50 20 50 90 20 50];
S1 = simulasi(Prm, 2, Ref, 2000, true);
S2 = simulasi(Prm, 2, Ref, 2000, false);
figure('Name', 'Pole placement posisi');
stairs(S1.t, S1.r, 'k--'); hold on;
plot(S1.t, S1.p, 'b', S2.t, S2.p, 'r'); grid on;
xlabel('Waktu (ms)'); ylabel('Posisi (%)');
legend('Set point', 'Umpan balik observer', 'Umpan balik tachometer');

%% Fungsi bantu
function z = kutub_diskrit(Zeta, TSettle, Ts)
    % Pasangan kutub diskrit dari rasio redaman dan settling time 2%
    wn = 4 / (Zeta * TSettle);
    s  = -Zeta*wn + 1i*wn*sqrt(1 - Zeta^2);
    z  = exp([s; conj(s)] * Ts);
end

function Kg = ackermann(A, B, Kutub)
    % Rumus Ackermann untuk sistem orde dua
    al  = real(poly(Kutub));               % [1 alpha1 alpha0]
    Phi = A^2 + al(2)*A + al(3)*eye(2);
    Kg  = [0 1] / [B, A*B] * Phi;
end

function S = simulasi(Prm, Mode, Seq, Hold, PakaiObserver)
    % Plant kontinu (langkah 1 ms) dengan waktu tunda, saturasi, dan derau.
    Ts = Prm.Ts; d = round(Prm.Theta); N = Hold * numel(Seq);
    ubuf = zeros(N + d + 1, 1);
    v = 0; p = 50; u = 0; Arah = 1;
    xA = [50; 0]; xB = [50; 0];
    nk = floor((N - 1)/Ts) + 1;
    S = struct('t', zeros(nk,1), 'r', zeros(nk,1), 'v', zeros(nk,1), 'vT', zeros(nk,1), ...
        'vHat', zeros(nk,1), 'p', zeros(nk,1), 'pTrue', zeros(nk,1), 'pHatT', zeros(nk,1));
    i = 0;
    for k = 0:N-1
        if mod(k, Ts) == 0
            r = Seq(min(numel(Seq), floor(k/Hold) + 1));
            pm = mod(p + 0.1*randn, 100);                    % potensiometer
            vt = abs(v); if vt < Prm.TachoMin, vt = 0; end   % tachometer
            vt = max(0, vt + Prm.Derau*randn*(vt > 0));
            if u ~= 0, Arah = sign(u); end
            vs = Arah * vt;
            switch Mode
                case 0
                    u = r;
                case 1
                    if r <= 0, u = 0; else, u = Prm.Nspeed*r - Prm.Kspeed*vt; end
                    u = min(100, max(0, u));
                otherwise
                    if PakaiObserver, vf = xA(2); else, vf = vs; end
                    u = -(Prm.Kpos*bungkus(pm - r) + Prm.Kvel*vf);
                    u = min(Prm.UMax, max(-Prm.UMax, u));
            end
            % observer A (posisi terukur) dan observer B (kecepatan terukur)
            xA = Prm.A*xA + Prm.B*u + Prm.Lp*bungkus(pm - xA(1)); xA(1) = mod(xA(1), 100);
            xB = Prm.A*xB + Prm.B*u + Prm.Lv*(vs - xB(2));
            i = i + 1;
            S.t(i) = k; S.r(i) = r; S.v(i) = v; S.vT(i) = vs; S.vHat(i) = xA(2);
            S.p(i) = pm; S.pTrue(i) = p; S.pHatT(i) = xB(1);
        end
        ubuf(k + 1 + d) = u;
        v = v + (Prm.K*ubuf(k + 1) - v) / Prm.Tau;
        p = p + Prm.C * v;
    end
end

function e = bungkus(e)
    % Membatasi error posisi pada rentang -50 hingga 50
    e = mod(e + 50, 100) - 50;
end
