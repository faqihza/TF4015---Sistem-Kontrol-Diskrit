"""Contoh numerik dan data grafik untuk slide P2--P15 dan diktat TF4015.

Plant acuan sepanjang semester (kit praktikum, dinormalisasi):
  kecepatan : Gv(s) = K/(tau s + 1)
  posisi    : Gp(s) = K/(s (tau s + 1))
  K = 1, tau = 0.5 s, T = 0.1 s
Jalankan:  python3 gen_data.py  > ../data/hasil_contoh.txt
"""
import numpy as np
import control as ct
import sympy as sp
from scipy.linalg import expm, solve_discrete_are
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "data"
OUT.mkdir(exist_ok=True)
np.set_printoptions(precision=5, suppress=True)
rng = np.random.default_rng(4015)

K, tau, T = 1.0, 0.5, 0.1
a = np.exp(-T / tau)
b = K * (1 - a)


def save(name, cols, header):
    np.savetxt(OUT / name, np.column_stack(cols), header=header, comments="", fmt="%.6g")


def hdr(s):
    print("\n" + "=" * 70 + "\n" + s + "\n" + "=" * 70)


def step_info(t, y, yss=None, band=0.02):
    yss = y[-1] if yss is None else yss
    Mp = max(0.0, (y.max() - yss) / abs(yss) * 100)
    out = np.where(np.abs(y - yss) > band * abs(yss))[0]
    ts = t[out[-1] + 1] if len(out) and out[-1] + 1 < len(t) else (t[-1] if len(out) else 0.0)
    return Mp, ts


hdr("Parameter acuan")
print(f"K={K}, tau={tau}, T={T}, a=exp(-T/tau)={a:.5f}, b=K(1-a)={b:.5f}")

# ---------------------------------------------------------------- P2
hdr("P2 kuantisasi")
for n, fsr in [(10, 5.0), (12, 5.0), (16, 10.0)]:
    Q = fsr / 2**n
    print(f"{n}-bit, FSR={fsr} V: Q={Q*1e3:.4f} mV, sigma_q=Q/sqrt(12)={Q/np.sqrt(12)*1e3:.4f} mV")
print("Alias 9 Hz @ fs=10 Hz -> |9-10| = 1 Hz")
for f, fs in [(9, 10), (60, 50), (130, 100)]:
    fa = abs(f - fs * round(f / fs))
    print(f"f={f} Hz, fs={fs} Hz -> alias {fa} Hz")

# ---------------------------------------------------------------- P3
hdr("P3 persamaan beda y[k+2]-0.7y[k+1]+0.1y[k]=u[k], tangga, KA nol")
z, k = sp.symbols("z k")
Y = z / ((z - 1) * (z**2 - sp.Rational(7, 10) * z + sp.Rational(1, 10)))
pf = sp.apart(Y / z, z)
print("Y(z)/z =", pf)
yk = sp.simplify(sp.inverse_laplace_transform(0, k, z) if False else 0)
# solusi dari pecahan parsial
c1 = sp.limit((z - 1) * Y / z, z, 1)
c2 = sp.limit((z - sp.Rational(1, 2)) * Y / z, z, sp.Rational(1, 2))
c3 = sp.limit((z - sp.Rational(1, 5)) * Y / z, z, sp.Rational(1, 5))
print("koef:", c1, c2, c3, "-> y[k] = c1 + c2 0.5^k + c3 0.2^k")
yv = [0, 0]
for i in range(2, 10):
    yv.append(0.7 * yv[-1] - 0.1 * yv[-2] + 1)
yfor = [float(c1 + c2 * sp.Rational(1, 2)**i + c3 * sp.Rational(1, 5)**i) for i in range(10)]
print("rekursi :", np.round(yv, 4))
print("rumus   :", np.round(yfor, 4))
print("nilai akhir:", float(c1))
# pembagian panjang Y(z)=z/(z^3-1.7z^2+0.8z-0.1)
den = sp.Poly(sp.expand((z - 1) * (z**2 - sp.Rational(7, 10) * z + sp.Rational(1, 10))), z)
print("penyebut:", den.as_expr())
save("p3_seq.dat", [np.arange(10), yv], "k y")

hdr("P3 contoh 2: y[k]=0.8y[k-1]+0.2u[k-1], tangga")
yy = [0.0]
for i in range(1, 15):
    yy.append(0.8 * yy[-1] + 0.2)
print(np.round(yy[:8], 4), "rumus 1-0.8^k")
save("p3_first.dat", [np.arange(15), yy], "k y")

# ---------------------------------------------------------------- P4
hdr("P4 ekuivalen ZOH")
Gv = ct.tf([K], [tau, 1])
Gp = ct.tf([K], [tau, 1, 0])
Gvz = ct.c2d(Gv, T, "zoh")
Gpz = ct.c2d(Gp, T, "zoh")
print("Gv(z) =", Gvz)
print("Gp(z) =", Gpz)
b1 = K * (T - tau + tau * a)
b0 = K * (tau - a * tau - a * T)
print(f"rumus posisi: b1={b1:.6f}, b0={b0:.6f}, zero={-b0/b1:.4f}")
print("Integrator K/s -> K T/(z-1) =", ct.c2d(ct.tf([K], [1, 0]), T, "zoh"))

hdr("P4 identifikasi ARX dari data berderau")
N = 120
u = np.zeros(N)
seq = [0.5, 1.0, 0.3, 0.8, 0.0, 0.6]
for i, v in enumerate(seq):
    u[i * 20:(i + 1) * 20] = v
x = np.zeros(N)
for i in range(1, N):
    x[i] = a * x[i - 1] + b * u[i - 1]
ym = x + rng.normal(0, 0.02, N)
Phi = np.column_stack([ym[:-1], u[:-1]])
th, *_ = np.linalg.lstsq(Phi, ym[1:], rcond=None)
ah, bh = th
tauh = -T / np.log(ah)
Kh = bh / (1 - ah)
print(f"benar a={a:.4f} b={b:.4f}; estimasi a={ah:.4f} b={bh:.4f}")
print(f"-> tau_hat={tauh:.4f} s, K_hat={Kh:.4f}")
yh = np.zeros(N)
for i in range(1, N):
    yh[i] = ah * yh[i - 1] + bh * u[i - 1]
fit = 100 * (1 - np.linalg.norm(ym - yh) / np.linalg.norm(ym - ym.mean()))
print(f"fit = {fit:.1f}%")
save("p4_arx.dat", [np.arange(N) * T, u, ym, yh], "t u ym yh")

hdr("P4 metode dua titik (Smith) pada FOPDT K=2, tau=1.5, theta=0.3")
Kf, tf_, th_ = 2.0, 1.5, 0.3
t28 = th_ + tf_ * np.log(1 / 0.717)
t63 = th_ + tf_
taus = 1.5 * (t63 - t28)
ths = t63 - taus
print(f"t28.3={t28:.3f}, t63.2={t63:.3f} -> tau={taus:.3f}, theta={ths:.3f}")

# ---------------------------------------------------------------- P5
hdr("P5 emulasi lead C(s)=10(s+2)/(s+10), T=0.05")
Te = 0.05
Cs = ct.tf([10, 20], [1, 10])
ze = sp.symbols("z")
s = sp.symbols("s")
Csym = 10 * (s + 2) / (s + 10)
for name, sub in [("maju", (ze - 1) / Te), ("mundur", (ze - 1) / (ze * Te)), ("Tustin", 2 / Te * (ze - 1) / (ze + 1))]:
    Dz = sp.simplify(sp.together(Csym.subs(s, sub)))
    n, d = sp.fraction(Dz)
    n, d = sp.Poly(sp.expand(n), ze), sp.Poly(sp.expand(d), ze)
    lc = d.LC()
    print(f"{name:7s}: D(z) = ({sp.Poly(n.as_expr()/lc, ze).as_expr()}) / ({sp.Poly(d.as_expr()/lc, ze).as_expr()})".replace("1.0*", ""))
zm = np.exp(-2 * Te)
pm = np.exp(-10 * Te)
km = 10 * 2 / 10 * (1 - pm) / (1 - zm)
print(f"matched: D(z) = {km:.4f} (z - {zm:.4f})/(z - {pm:.4f})")
w = np.logspace(-1, np.log10(np.pi / Te * 0.999), 200)
mag_c = np.abs(10 * (1j * w + 2) / (1j * w + 10))
ph_c = np.angle(10 * (1j * w + 2) / (1j * w + 10), deg=True)
cols = [w, 20 * np.log10(mag_c), ph_c]
for name, method in [("forward", "euler"), ("backward", "backward_diff"), ("tustin", "tustin"), ("matched", "matched")]:
    Dz = ct.c2d(Cs, Te, method)
    zz = np.exp(1j * w * Te)
    H = np.polyval(Dz.num[0][0], zz) / np.polyval(Dz.den[0][0], zz)
    cols += [20 * np.log10(np.abs(H)), np.angle(H, deg=True)]
save("p5_emul.dat", cols, "w mc pc mf pf mb pb mt pt mm pm")

hdr("P5 PID diskrit: koreksi tunda T/2 (FOPDT P1)")
Kf, tf_, th_ = 2.0, 1.5, 0.3


def sim_fopdt_pid(Kp, Ti, Td, Ts, t_end=8.0, N=10.0, dt=1e-3, umax=None, aw=False):
    n = int(round(t_end / dt)) + 1
    t = np.arange(n) * dt
    nd = int(round(th_ / dt))
    spt = int(round(Ts / dt))
    y = np.zeros(n); uh = np.zeros(n)
    x = I = Df = yp = u = 0.0
    for i in range(n):
        y[i] = x
        if i % spt == 0:
            e = 1 - x
            Tf = Td / N if Td > 0 else 0
            Df = (Tf * Df + Td * (x - yp)) / (Tf + Ts) if Td > 0 else 0
            yp = x
            I += e * Ts
            u = Kp * (e + I / Ti - Df)
        uh[i] = u
        ud = uh[i - nd] if i >= nd else 0
        x += dt / tf_ * (-x + Kf * ud)
    return t, y


Ts = 0.05
Kp0, Ti0, Td0 = 1.2 * tf_ / (Kf * th_), 2 * th_, 0.5 * th_
thc = th_ + Ts / 2
Kp1, Ti1, Td1 = 1.2 * tf_ / (Kf * thc), 2 * thc, 0.5 * thc
t1, y0 = sim_fopdt_pid(Kp0, Ti0, Td0, Ts)
_, y1 = sim_fopdt_pid(Kp1, Ti1, Td1, Ts)
print(f"tanpa koreksi Kp={Kp0:.3f} Ti={Ti0:.3f} Td={Td0:.3f} -> Mp,ts =", np.round(step_info(t1, y0, 1), 2))
print(f"koreksi theta'={thc:.3f}: Kp={Kp1:.3f} Ti={Ti1:.3f} Td={Td1:.4f} -> Mp,ts =", np.round(step_info(t1, y1, 1), 2))
idx = np.arange(0, len(t1), 20)
save("p5_pidcorr.dat", [t1[idx], y0[idx], y1[idx]], "t y0 y1")

hdr("P5 anti-windup, plant kecepatan, PI, |u|<=1.2, r=1")
Kpw, Tiw = 3.0, 0.15
n = 60
ywu = {}
for mode in ["none", "clamp"]:
    x = I = 0.0
    ys, us = [], []
    for i in range(n):
        e = 1 - x
        Itry = I + e * T
        v = Kpw * (e + Itry / Tiw)
        uu = np.clip(v, -1.2, 1.2)
        if mode == "none" or uu == v:
            I = Itry
        ys.append(x); us.append(uu)
        x = a * x + b * uu
    ywu[mode] = (np.array(ys), np.array(us))
    print(mode, "Mp,ts =", np.round(step_info(np.arange(n) * T, np.array(ys), 1), 2))
save("p5_windup.dat", [np.arange(n) * T, ywu["none"][0], ywu["none"][1], ywu["clamp"][0], ywu["clamp"][1]], "t yn un yc uc")
q0 = lambda Kp, Ti, Td, T: Kp * (1 + T / Ti + Td / T)
print("q0,q1,q2 untuk Kp=2, Ti=0.5, Td=0.05, T=0.1:", q0(2, .5, .05, .1), -2 * (1 + 2 * .05 / .1), 2 * .05 / .1)

# ---------------------------------------------------------------- P6
hdr("P6 respons impuls untuk berbagai lokasi kutub")
kk = np.arange(0, 21)
cases = {"r05": [0.5], "r09": [0.9], "rm05": [-0.5], "c08": [0.8, np.pi / 6], "c095": [0.95, np.pi / 3], "r105": [1.05]}
cols = [kk]
for key, p in cases.items():
    if len(p) == 1:
        h = p[0] ** kk
    else:
        h = p[0] ** kk * np.cos(p[1] * kk)
    cols.append(h)
save("p6_poles.dat", cols, "k " + " ".join(cases.keys()))

hdr("P6 kontrol P kecepatan, Kp=2")
Kp = 2.0
pcl = a - Kp * K * (1 - a)
ess = 1 / (1 + Kp * K)
print(f"kutub kalang tertutup z={pcl:.4f}, ess={ess:.4f}, nilai akhir={1-ess:.4f}")
yk = [0.0]
for i in range(1, 21):
    yk.append(pcl * yk[-1] + Kp * b * 1)
save("p6_pspeed.dat", [np.arange(21) * T, yk], "t y")
print("tau_cl ekuivalen = ", -T / np.log(pcl))
# konversi kutub
for zp in [0.6 + 0.3j, 0.8187 * np.exp(1j * 0.3464)]:
    r_, th = abs(zp), np.angle(zp)
    zeta = -np.log(r_) / np.sqrt(np.log(r_)**2 + th**2)
    wn = np.sqrt(np.log(r_)**2 + th**2) / T
    print(f"z={zp:.4f}: r={r_:.4f}, theta={th:.4f} -> zeta={zeta:.4f}, wn={wn:.4f}")

# ---------------------------------------------------------------- P7
hdr("P7 kestabilan")
print(f"orde 1 + P: Kp_max = (1+a)/(K(1-a)) = {(1+a)/(K*(1-a)):.4f}")
print(f"orde 1 + P + tunda 1 cacah: Kp_max = 1/(K(1-a)) = {1/(K*(1-a)):.4f}")
print(f"posisi + P: Kp_max (Jury |a0|<1) = (1-a)/b0 = {(1-a)/b0:.4f}")
for Kt in [(1-a)/b0 * 0.999, (1-a)/b0 * 1.001]:
    print("   cek akar", np.abs(np.roots([1, Kt * b1 - 1 - a, a + Kt * b0])))
Tg = np.linspace(0.01, 1.0, 100)
ag = np.exp(-Tg / tau)
b0g = K * (tau - ag * tau - ag * Tg)
save("p7_kmax.dat", [Tg, (1 + ag) / (1 - ag), 1 / (1 - ag), (1 - ag) / b0g], "T k1 k1d kpos")
zz = sp.symbols("z")
P3 = sp.expand((zz - sp.Rational(1, 2)) * (zz + sp.Rational(4, 5)) * (zz - sp.Rational(3, 10)))
print("contoh Jury orde 3: P(z) =", P3)
coef = [float(c) for c in sp.Poly(P3, zz).all_coeffs()]
print("  P(1)=", float(P3.subs(zz, 1)), " (-1)^3 P(-1)=", float(-P3.subs(zz, -1)))
a_ = coef[::-1]  # a0..a3
row1 = a_
row2 = a_[::-1]
bk = [row1[0] * row1[i] - row1[3] * row1[3 - i] for i in range(3)]
print("  a0..a3=", a_, " b0..b2 (b_k = a0 a_k - a3 a_{3-k})=", np.round(bk, 4))
w_ = sp.symbols("w")
print("bilinear orde-1 P: pole z=a-Kp K(1-a) ok")

# ---------------------------------------------------------------- P9
hdr("P9 root locus dan lead diskrit (posisi, T=0.1)")
zeta_d, ts_d = 0.5, 2.0
sig = 4 / ts_d
wn_d = sig / zeta_d
wd_d = wn_d * np.sqrt(1 - zeta_d**2)
zd = np.exp(T * (-sig + 1j * wd_d))
print(f"spesifikasi zeta={zeta_d}, ts={ts_d}s -> s={-sig:.3f}+j{wd_d:.3f}, zd={zd:.4f} (|zd|={abs(zd):.4f}, sudut={np.degrees(np.angle(zd)):.2f} deg)")
numG, denG = np.array([b1, b0]), np.array([1, -(1 + a), a])
angG = np.degrees(np.angle(np.polyval(numG, zd) / np.polyval(denG, zd)))
print(f"sudut G(zd) = {angG:.2f} deg, defisit = {(-180 - angG) % 360:.2f} deg")
# lead: zero membatalkan kutub z=a
zc = a
ang_z = np.degrees(np.angle(zd - zc))
# butuh sudut total -180: ang(G)+ang(zd-zc)-ang(zd-pc) = -180
need = angG + ang_z + 180
ang_p = need
pc = zd.real - zd.imag / np.tan(np.radians(ang_p))
print(f"zero kompensator z={zc:.4f}, sudut zero={ang_z:.2f}, sudut pole perlu={ang_p % 360:.2f} -> pole p={pc:.4f}")
L0 = np.polyval(numG, zd) / np.polyval(denG, zd) * (zd - zc) / (zd - pc)
Kc = 1 / abs(L0)
print(f"Kc={Kc:.4f}, cek sudut L={np.degrees(np.angle(L0)):.2f}")
Dz = ct.tf([Kc, -Kc * zc], [1, -pc], T)
Lz = Dz * Gpz
CL = ct.feedback(Lz, 1)
print("kutub kalang tertutup:", np.round(ct.poles(CL), 4))
tk = np.arange(0, 41) * T
_, yl = ct.step_response(CL, tk)
Mp, tss = step_info(tk, yl, 1)
print(f"lead: Mp={Mp:.1f}%, ts={tss:.2f}s, ess posisi=0 (tipe 1)")
_, ul = ct.step_response(ct.feedback(Dz, Gpz), tk)
# P saja dengan zeta sama: cari K memberi zeta~0.5
best = None
for Kp in np.linspace(0.5, 20, 2000):
    r = np.roots(np.polyadd(denG, Kp * numG))
    rr = r[np.argmax(np.abs(r))]
    if abs(rr.imag) > 1e-9:
        lnr = np.log(abs(rr)); thh = abs(np.angle(rr))
        zz_ = -lnr / np.hypot(lnr, thh)
        if best is None or abs(zz_ - 0.5) < abs(best[1] - 0.5):
            best = (Kp, zz_, rr)
KpP = best[0]
CLp = ct.feedback(KpP * Gpz, 1)
_, yp = ct.step_response(CLp, tk)
print(f"P dengan zeta~0.5: Kp={KpP:.3f}, kutub={best[2]:.4f}, Mp,ts=", np.round(step_info(tk, yp, 1), 2))
save("p9_step.dat", [tk, yl, ul, yp], "t ylead ulead yp")
# lokus P
Ks = np.concatenate([np.linspace(0, 2, 200), np.linspace(2, 60, 400)])
br = np.array([np.sort_complex(np.roots(np.polyadd(denG, Kq * numG))) for Kq in Ks])
save("p9_rlP.dat", [br[:, 0].real, br[:, 0].imag, br[:, 1].real, br[:, 1].imag], "x1 y1 x2 y2")
# lokus dengan lead (zero batal): L = Kc b1 (z+b0/b1)/((z-1)(z-pc))
numL, denL = numG, np.polymul([1, -1], [1, -pc])
Ks2 = np.concatenate([np.linspace(0, 5, 200), np.linspace(5, 300, 400)])
br2 = np.array([np.sort_complex(np.roots(np.polyadd(denL, Kq * numL))) for Kq in Ks2])
save("p9_rlLead.dat", [br2[:, 0].real, br2[:, 0].imag, br2[:, 1].real, br2[:, 1].imag], "x1 y1 x2 y2")
unst = (np.max(np.abs(br2), axis=1) > 1) & (Ks2 > 0.1)
print("Kmax lead total (Kc*.. di mana |z|=1):", Ks2[np.argmax(unst)], "-> Kc_max =", Ks2[np.argmax(unst)])

# ---------------------------------------------------------------- P10
hdr("P10 respons frekuensi posisi, Kp=5")
Kp = 5.0
gm, pm, wg, wp = ct.margin(Kp * Gpz)
print(f"diskrit: GM={20*np.log10(gm):.2f} dB @ {wg:.3f} rad/s, PM={pm:.2f} deg @ {wp:.3f} rad/s")
gmc, pmc, wgc, wpc = ct.margin(Kp * Gp)
print(f"kontinu: GM={gmc}, PM={pmc:.2f} deg @ {wpc:.3f} rad/s ; selisih fasa ZOH ~ wT/2 = {np.degrees(wpc*T/2):.2f} deg")
w = np.logspace(-1, np.log10(np.pi / T * 0.999), 300)
zz = np.exp(1j * w * T)
Hd = Kp * np.polyval(numG, zz) / np.polyval(denG, zz)
Hc = Kp * K / (1j * w * (tau * 1j * w + 1))
save("p10_bode.dat", [w, 20 * np.log10(abs(Hc)), np.unwrap(np.angle(Hc)) * 180 / np.pi, 20 * np.log10(abs(Hd)), np.unwrap(np.angle(Hd)) * 180 / np.pi], "w mc pc md pd")
print("transformasi w: w=(2/T)tan(omega T/2); omega=10 -> w=", 2 / T * np.tan(10 * T / 2), "; omega=30 ->", 2 / T * np.tan(30 * T / 2))

hdr("P10 deadbeat dan Dahlin pada plant kecepatan")
n = 15
lam = 0.3
q = np.exp(-T / lam)
res = {}
for name, Fpole, Fgain in [("deadbeat", 0.0, 1.0), ("dahlin", q, 1 - q)]:
    # F(z) = Fgain/(z - Fpole); D = F/(G(1-F)), G=b/(z-a)
    # D(z) = Fgain (z-a) / (b (z - Fpole - Fgain)) ; Fpole+Fgain = 1
    x = 0.0; I = 0.0
    ys, us = [], []
    uprev, eprev = 0.0, 0.0
    for i in range(n):
        e = 1 - x
        # u[k] = u[k-1] + Fgain/b (e[k] - a e[k-1])
        uu = uprev + Fgain / b * (e - a * eprev)
        ys.append(x); us.append(uu)
        x = a * x + b * uu
        uprev, eprev = uu, e
    res[name] = (ys, us)
    print(f"{name}: u[0..4]={np.round(us[:5], 3)}, y[0..5]={np.round(ys[:6], 3)}")
print(f"Dahlin lambda={lam}, q={q:.4f}")
save("p10_db.dat", [np.arange(n) * T, res["deadbeat"][0], res["deadbeat"][1], res["dahlin"][0], res["dahlin"][1]], "t yd ud yh uh")
# deadbeat posisi: minimal prototype vs bebas riak
def sim_pos_ctrl(numD, denD, t_end=1.5, dt=1e-3):
    # simulasi kontinu dengan ZOH, kontroler diskrit D(z)=numD/denD dalam z^-1
    nst = int(round(T / dt)); n = int(round(t_end / dt)) + 1
    th = om = 0.0
    eh = [0.0] * 5; uh = [0.0] * 5
    ts_, ys_, uc = [], [], []
    u = 0.0
    for i in range(n):
        if i % nst == 0:
            e = 1 - th
            eh = [e] + eh[:-1]
            u = (sum(numD[j] * eh[j] for j in range(len(numD))) - sum(denD[j] * uh[j - 1] for j in range(1, len(denD)))) / denD[0]
            uh = [u] + uh[:-1]
        ts_.append(i * dt); ys_.append(th); uc.append(u)
        om += dt / tau * (-om + K * u)
        th += dt * om
    return np.array(ts_), np.array(ys_), np.array(uc)
# minimal prototype F=z^-1 : D = (1/G) z^-1/(1-z^-1)
# G(z^-1) = (b1 z^-1 + b0 z^-2)/((1-z^-1)(1-a z^-1)) -> D = (1-a z^-1)/(b1 + b0 z^-1)
t_, ymp, ump = sim_pos_ctrl([1, -a], [b1, b0])
# bebas riak F = (b1 z^-1 + b0 z^-2)/(b1+b0)
# 1-F = (1-z^-1)(1 + c z^-1), c = b0/(b1+b0); D = F/(G(1-F)) = (1-a z^-1)/((b1+b0)(1+c z^-1))
cc = b0 / (b1 + b0)
t_, yrf, urf = sim_pos_ctrl([1, -a], [b1 + b0, (b1 + b0) * cc])
print(f"minimal prototype: u[0..3] ~ {np.round(ump[::100][:4],2)}; bebas riak: u[0..3] ~ {np.round(urf[::100][:4],2)}, c={cc:.4f}")
idx = np.arange(0, len(t_), 5)
save("p10_ripple.dat", [t_[idx], ymp[idx], ump[idx], yrf[idx], urf[idx]], "t ymp ump yrf urf")

# ---------------------------------------------------------------- P11
hdr("P11 ruang keadaan diskrit posisi")
A = np.array([[0, 1], [0, -1 / tau]])
B = np.array([[0], [K / tau]])
C = np.array([[1, 0]])
M = expm(np.block([[A, B], [np.zeros((1, 3))]]) * T)
Phi, Gam = M[:2, :2], M[:2, 2:]
print("Phi =\n", Phi, "\nGamma =\n", Gam)
sysd = ct.ss(Phi, Gam, C, 0, T)
print("G(z) dari SS =", ct.tf(sysd))
Wc = np.hstack([Gam, Phi @ Gam])
Wo = np.vstack([C, C @ Phi])
print("Wc =\n", Wc, " det=", np.linalg.det(Wc))
print("Wo =\n", Wo, " det=", np.linalg.det(Wo))
w0 = 2 * np.pi
Ao = np.array([[0, 1], [-w0**2, 0]]); Bo = np.array([[0], [1]])
for Tq in [0.4, 0.5]:
    Mo = expm(np.block([[Ao, Bo], [np.zeros((1, 3))]]) * Tq)
    Po, Go = Mo[:2, :2], Mo[:2, 2:]
    print(f"osilator w0=2pi, T={Tq}: Phi=\n{Po}\n det Wc = {np.linalg.det(np.hstack([Go, Po@Go])):.4e}")

# ---------------------------------------------------------------- P12
hdr("P12 penempatan kutub posisi")
zeta_p, wn_p = 0.7, 4.0
sp_ = -zeta_p * wn_p + 1j * wn_p * np.sqrt(1 - zeta_p**2)
zp = np.exp(sp_ * T)
poles = [zp, np.conj(zp)]
Kpp = np.atleast_2d(ct.acker(Phi, Gam, poles))
print(f"s={sp_:.4f} -> z={zp:.4f}; K = {Kpp}")
alpha = np.poly(poles)
print("alpha_c(z) =", np.round(alpha, 5))
Acl = Phi - Gam @ Kpp
Nbar = 1 / (C @ np.linalg.inv(np.eye(2) - Acl) @ Gam)[0, 0]
print("Nbar =", Nbar)
# integral: xi[k+1] = xi[k] + (r - y[k])
Pa = np.block([[Phi, np.zeros((2, 1))], [-C, np.ones((1, 1))]])
Ga = np.vstack([Gam, [[0]]])
s3 = -zeta_p * wn_p * 1.5
poles3 = poles + [np.exp(s3 * T)]
Ka = np.atleast_2d(ct.acker(Pa, Ga, poles3))
print("pole integral z=", np.exp(s3 * T), " Ka=[K, -Ki] =", Ka)
n = 81; tk = np.arange(n) * T
dist = np.where(tk >= 4.0, -0.3, 0.0)
xs = np.zeros(2); xa = np.zeros(3)
y1, y2, u1, u2 = [], [], [], []
for i in range(n):
    u = (-Kpp @ xs + Nbar * 1.0).item()
    y1.append(xs[0]); u1.append(u)
    xs = Phi @ xs + Gam[:, 0] * (u + dist[i])
    ua = (-Ka @ xa).item()
    y2.append(xa[0]); u2.append(ua)
    xn = Phi @ xa[:2] + Gam[:, 0] * (ua + dist[i])
    xa = np.array([xn[0], xn[1], xa[2] + (1.0 - xa[0])])
print("tanpa integral: y akhir =", round(y1[-1], 4), "; dengan integral:", round(y2[-1], 4))
print("Mp,ts (hingga t<4):", np.round(step_info(tk[:40], np.array(y1[:40]), 1), 2), np.round(step_info(tk[:40], np.array(y2[:40]), 1), 2))
save("p12_pp.dat", [tk, y1, u1, y2, u2], "t y1 u1 y2 u2")
Kdb = np.atleast_2d(ct.acker(Phi, Gam, [0, 0]))
print("deadbeat K =", Kdb)

# ---------------------------------------------------------------- P13
hdr("P13 pengamat")
obs_poles = [0.4, 0.45]
Lp = np.atleast_2d(ct.acker(Phi.T, C.T, obs_poles)).T
print("L prediktor =", Lp.ravel())
Lc = np.atleast_2d(ct.acker(Phi.T, (C @ Phi).T, obs_poles)).T
print("L current =", Lc.ravel(), " eig(Phi - Lc C Phi)=", np.linalg.eigvals(Phi - Lc @ C @ Phi))
print("eig(Phi - Lp C)=", np.linalg.eigvals(Phi - Lp @ C))
# simulasi: u acak, pengukuran posisi berderau, estimasi kecepatan
n = 60; tk = np.arange(n) * T
uin = np.where(tk < 2, 1.0, np.where(tk < 4, -0.5, 0.8))
x = np.array([0.0, 0.0]); xh = np.array([0.2, -0.5])
tr_w, est_w, fd_w = [], [], []
yprev = 0.0
for i in range(n):
    y = x[0] + rng.normal(0, 0.005)
    tr_w.append(x[1]); est_w.append(xh[1]); fd_w.append((y - yprev) / T if i > 0 else 0.0)
    yprev = y
    xh = Phi @ xh + Gam[:, 0] * uin[i] + Lp[:, 0] * (y - xh[0])
    x = Phi @ x + Gam[:, 0] * uin[i]
save("p13_obs.dat", [tk, tr_w, est_w, fd_w], "t w what wfd")
print("RMS galat estimasi (k>=10):", np.sqrt(np.mean((np.array(tr_w[10:]) - np.array(est_w[10:]))**2)),
      " RMS beda hingga:", np.sqrt(np.mean((np.array(tr_w[10:]) - np.array(fd_w[10:]))**2)))
# kompensator D(z) = K (zI - Phi + Gam K + Lp C)^-1 Lp
Ad = Phi - Gam @ Kpp - Lp @ C
Dcomp = ct.tf(ct.ss(Ad, Lp, Kpp, 0, T))
print("D(z) kompensator =", Dcomp)
CLo = np.concatenate([np.linalg.eigvals(Phi - Gam @ Kpp), np.linalg.eigvals(Phi - Lp @ C)])
print("kutub sistem dengan pengamat:", np.round(CLo, 4))

# ---------------------------------------------------------------- P14
hdr("P14 LQR")
Q = np.diag([1.0, 0.0])
res = []
for R in [0.01, 0.1, 1.0]:
    P = solve_discrete_are(Phi, Gam, Q, np.array([[R]]))
    Kl = np.linalg.solve(R + Gam.T @ P @ Gam, Gam.T @ P @ Phi)
    Acl = Phi - Gam @ Kl
    Nb = 1 / (C @ np.linalg.inv(np.eye(2) - Acl) @ Gam)[0, 0]
    x = np.zeros(2); ys, us = [], []
    for i in range(41):
        u = (-Kl @ x + Nb).item(); ys.append(x[0]); us.append(u)
        x = Phi @ x + Gam[:, 0] * u
    res += [ys, us]
    print(f"R={R}: K={Kl.ravel()}, kutub={np.round(np.linalg.eigvals(Acl),4)}, Mp,ts={np.round(step_info(np.arange(41)*T, np.array(ys),1),2)}, u_max={max(us):.2f}")
save("p14_lqr.dat", [np.arange(41) * T] + res, "t y1 u1 y2 u2 y3 u3")
# Bryson: theta_max=0.1 rad, u_max=1
print("Bryson: Q=diag(1/0.1^2,0)=diag(100,0), R=1/1^2=1 setara Q=diag(1,0), R=0.01")
hdr("P14 Kalman")
qw, rv = 0.5, 0.01**2  # derau proses (pada masukan) dan pengukuran
Qn = Gam @ Gam.T * qw
Pk = solve_discrete_are(Phi.T, C.T, Qn, np.array([[rv]]))
Kk = Pk @ C.T @ np.linalg.inv(C @ Pk @ C.T + rv)
print("Kalman gain (bentuk current) =", Kk.ravel(), " P- =\n", Pk)
print("eig(Phi - Phi Kk C)=", np.linalg.eigvals(Phi - Phi @ Kk @ C))
n = 80; tk = np.arange(n) * T
x = np.zeros(2); xh = np.zeros(2); Pm = np.eye(2)
tw, ew, ey, my = [], [], [], []
for i in range(n):
    uu = 1.0 if tk[i] < 4 else -1.0
    y = x[0] + rng.normal(0, np.sqrt(rv))
    # update
    Kg = Pm @ C.T / (C @ Pm @ C.T + rv)
    xh = xh + Kg[:, 0] * (y - xh[0])
    Pp = (np.eye(2) - Kg @ C) @ Pm
    tw.append(x[1]); ew.append(xh[1]); my.append(y); ey.append(xh[0])
    # predict
    xh = Phi @ xh + Gam[:, 0] * uu
    Pm = Phi @ Pp @ Phi.T + Qn
    x = Phi @ x + Gam[:, 0] * (uu + rng.normal(0, np.sqrt(qw)))
save("p14_kf.dat", [tk, tw, ew, my, ey], "t w what y yhat")
print("RMS galat kecepatan KF (k>=10):", np.sqrt(np.mean((np.array(tw[10:]) - np.array(ew[10:]))**2)))

# ---------------------------------------------------------------- P15
hdr("P15 kuantisasi koefisien")
r0, th0 = 0.98, 0.05
a1, a2 = -2 * r0 * np.cos(th0), r0**2
print(f"kutub ideal r={r0}, theta={th0}: a1={a1:.6f}, a2={a2:.6f}")
for bits in [8, 12, 16]:
    qq = 2.0**-bits
    a1q, a2q = np.round(a1 / qq) * qq, np.round(a2 / qq) * qq
    rr = np.roots([1, a1q, a2q])
    print(f" {bits} bit pecahan: a1={a1q:.6f}, a2={a2q:.6f} -> |p|={np.abs(rr).round(5)}, sudut={np.abs(np.angle(rr)).round(5)}")
for Tq in [0.1, 0.01, 0.001]:
    aq = np.exp(-Tq / tau)
    print(f"T={Tq}: a = {aq:.6f}, 1-a = {1-aq:.6f}; dalam Q8 (1/256): a={np.round(aq*256)/256:.6f}, tau efektif={-Tq/np.log(np.round(aq*256)/256) if np.round(aq*256)<256 else float('inf')}")
# pengaruh tunda komputasi satu cacah pada lead P9
CLd = ct.feedback(Dz * Gpz * ct.tf([1], [1, 0], T), 1)
_, yd = ct.step_response(CLd, np.arange(41) * T)
print("lead P9 + tunda 1 cacah: kutub", np.round(np.abs(ct.poles(CLd)), 3), " Mp,ts=", np.round(step_info(np.arange(41) * T, yd, 1), 2))
save("p15_delay.dat", [np.arange(41) * T, yl, yd], "t y0 y1")
