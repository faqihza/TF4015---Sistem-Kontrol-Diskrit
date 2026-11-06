"""Data untuk slide Pertemuan 1: respons FOPDT + PID (ZN) kontinu dan diskrit.

Plant  : G(s) = K e^{-theta s} / (tau s + 1)
PID    : u = Kp [ e + (1/Ti) int e dt - Td dy_f/dt ]   (D pada pengukuran, filter N)
Diskrit: PID dihitung tiap T detik, keluaran ditahan (ZOH), satu langkah tunda komputasi diabaikan.
"""
import numpy as np
from pathlib import Path

K, tau, theta = 2.0, 1.5, 0.3
# Ziegler-Nichols kurva reaksi (PID)
Kp = 1.2 * tau / (K * theta)
Ti = 2.0 * theta
Td = 0.5 * theta
N = 10.0

dt = 1e-3
t_end = 8.0
n = int(round(t_end / dt)) + 1
t = np.arange(n) * dt
r = np.ones(n)
nd = int(round(theta / dt))

out = Path(__file__).resolve().parent.parent / "data"
out.mkdir(exist_ok=True)


def simulate(T=None):
    y = np.zeros(n)
    u_hist = np.zeros(n)
    x = 0.0          # keadaan plant orde-1 (tanpa tunda)
    I = 0.0          # integral
    Df = 0.0         # derivatif terfilter
    y_prev = 0.0
    u = 0.0
    steps_per_T = None if T is None else int(round(T / dt))
    for k in range(n):
        y[k] = x
        if T is None:
            e = r[k] - y[k]
            I += e * dt
            # filter derivatif: Tf dDf/dt + Df = Td dy/dt, Tf = Td/N
            Tf = Td / N
            dy = (y[k] - y_prev) / dt
            Df += dt / Tf * (Td * dy - Df)
            u = Kp * (e + I / Ti - Df)
            y_prev = y[k]
        elif k % steps_per_T == 0:
            e = r[k] - y[k]
            I += e * T
            Tf = Td / N
            # Euler mundur untuk filter derivatif
            Df = (Tf * Df + Td * (y[k] - y_prev)) / (Tf + T)
            u = Kp * (e + I / Ti - Df)
            y_prev = y[k]
        u_hist[k] = u
        ud = u_hist[k - nd] if k >= nd else 0.0
        x += dt / tau * (-x + K * ud)
    return y


def save(name, y, step=20):
    idx = np.arange(0, n, step)
    np.savetxt(out / name, np.column_stack([t[idx], y[idx]]),
               header="t y", comments="", fmt="%.4f")


def metrics(y):
    yss = 1.0
    Mp = (y.max() - yss) / yss * 100
    outside = np.where(np.abs(y - yss) > 0.02)[0]
    ts = t[outside[-1]] if len(outside) else 0.0
    return Mp, ts


# Respons tangga terbuka FOPDT (untuk slide kurva reaksi)
y_ol = np.where(t >= theta, K * (1 - np.exp(-(t - theta) / tau)), 0.0)
save("fopdt_open.dat", y_ol)

results = {}
for label, T in [("cont", None), ("T002", 0.02), ("T005", 0.05), ("T010", 0.10)]:
    y = simulate(T)
    save(f"pid_{label}.dat", y)
    results[label] = metrics(y)

print(f"Kp={Kp:.3f}, Ti={Ti:.3f}, Td={Td:.3f}")
for k, (Mp, ts) in results.items():
    print(f"{k}: Mp={Mp:.1f}%  ts(2%)={ts:.2f}s")
