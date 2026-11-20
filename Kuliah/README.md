# TF4015 Sistem Kontrol Diskrit: materi kuliah

## Isi

| Folder | Isi |
|---|---|
| `rps/` | Rencana Pembelajaran Semester (`rps_tf4015.tex`, PDF) |
| `slides/` | Slide Beamer P01–P15 (P08 dan P16 adalah ujian), tema `beamerthemeskd.sty` |
| `slides/data/` | Data grafik (`*.dat`) dan ringkasan angka contoh (`hasil_contoh.txt`) |
| `slides/scripts/` | `gen_data.py` (semua contoh P2–P15), `sim_p01.py` (contoh P1) |
| `slides/assets/` | Foto kit praktikum |
| `diktat/` | Catatan kuliah: `diktat_tf4015.tex` + `bab01.tex`–`bab14.tex` + `glosarium.tex` |

## Kompilasi

```bash
# slide (dari folder slides/)
latexmk -pdf p05_emulasi_pid.tex

# diktat (dari folder diktat/, membaca data dari ../slides/data/)
latexmk -pdf diktat_tf4015.tex

# membuat ulang semua data dan angka contoh
cd slides/scripts
pip install numpy scipy sympy control
python3 sim_p01.py
python3 gen_data.py > ../data/hasil_contoh.txt
```

Paket LaTeX yang dipakai: beamer, pgfplots (groupplots), tikz, tcolorbox, booktabs, listings (semuanya ada di TeX Live standar).

## Plant acuan

Semua contoh memakai motor DC yang dinormalisasi:
kecepatan `K/(tau s + 1)` dan posisi `K/(s(tau s + 1))`, dengan `K = 1`, `tau = 0,5 s`, `T = 0,1 s`.
Bila parameter kit hasil identifikasi Modul 1 ingin dipakai, ubah `K`, `tau`, `T` di awal `gen_data.py`, jalankan ulang skripnya, lalu perbarui angka di slide atau diktat sesuai `hasil_contoh.txt`.
