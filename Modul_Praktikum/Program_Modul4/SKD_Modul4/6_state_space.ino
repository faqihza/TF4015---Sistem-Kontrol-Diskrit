// ===========================================================================
// Tab ruang keadaan (Modul 4): model diskrit, umpan balik keadaan, observer
//
// Keadaan x = [posisi (%); kecepatan bertanda (%)], masukan u (%).
// Model diskrit (ZOH, waktu tunda diabaikan):
//   x[k+1] = A x[k] + B u[k]
//   A = [1  Ad12; 0  Ad22],  B = [Bd1; Bd2]
// Parameter model berasal dari Modul 1 (ModelK, ModelTau) dan Modul 3
// (ModelC). Gain dihitung dengan skrip desain_state_space.m dan diisikan pada
// fungsi gain_setup() di tab 9_main.ino.
// ===========================================================================

// Parameter model (Tau dalam ms, C dalam %/ms per % kecepatan)
float ModelK = 0.85, ModelTau = 60.0, ModelC = 0.02;
float Ad12 = 0.0, Ad22 = 0.0, Bd1 = 0.0, Bd2 = 0.0;

// Pole placement kecepatan (satu keadaan): u = Nspeed*r - Kspeed*v
float Kspeed = 0.0, Nspeed = 1.0;

// Pole placement posisi (dua keadaan): u = -(Kpos*wrap(p - r) + Kvel*v)
float Kpos = 0.5, Kvel = 0.25;

// Observer A: keluaran terukur posisi (potensiometer) -> estimasi kecepatan
float Lp1 = 0.5, Lp2 = 0.4;
float PosHat = 0.0, VelHat = 0.0;

// Observer B: keluaran terukur kecepatan (tachometer) -> estimasi posisi
float Lv1 = 0.0, Lv2 = 0.0;
float PosHatT = 0.0, VelHatT = 0.0;

// Menghitung matriks A dan B diskrit dari parameter model dan waktu cacah Ts (ms)
void state_space_setup(unsigned int Ts) {
  float a = exp(-(float) Ts / ModelTau);
  Ad12 = ModelC * ModelTau * (1.0 - a);
  Ad22 = a;
  Bd1 = ModelC * ModelK * ((float) Ts - ModelTau * (1.0 - a));
  Bd2 = ModelK * (1.0 - a);
}

// Membatasi error posisi pada rentang -50 hingga 50 (jalur terpendek)
float wrap_error(float e) {
  while (e > 50.0) e -= 100.0;
  while (e < -50.0) e += 100.0;
  return e;
}

// Menjaga posisi pada rentang 0 hingga 100
float wrap_position(float p) {
  while (p >= 100.0) p -= 100.0;
  while (p < 0.0) p += 100.0;
  return p;
}

void observer_reset(float Position, float Velocity) {
  PosHat = Position;
  VelHat = Velocity;
  PosHatT = Position;
  VelHatT = Velocity;
}

// Dipanggil sekali setiap waktu cacah, setelah masukan u[k] diberikan.
// Menghasilkan estimasi keadaan untuk cacah berikutnya, x_hat[k+1].
void observer_update(float PositionMeasured, float VelocityMeasured, float U) {
  // Observer A: koreksi berdasarkan error posisi (dibatasi -50 hingga 50)
  float Innovation = wrap_error(PositionMeasured - PosHat);
  float NextPos = PosHat + Ad12 * VelHat + Bd1 * U + Lp1 * Innovation;
  float NextVel = Ad22 * VelHat + Bd2 * U + Lp2 * Innovation;
  PosHat = wrap_position(NextPos);
  VelHat = NextVel;

  // Observer B: koreksi berdasarkan error kecepatan
  float InnovationT = VelocityMeasured - VelHatT;
  float NextPosT = PosHatT + Ad12 * VelHatT + Bd1 * U + Lv1 * InnovationT;
  float NextVelT = Ad22 * VelHatT + Bd2 * U + Lv2 * InnovationT;
  PosHatT = wrap_position(NextPosT);
  VelHatT = NextVelT;
}
