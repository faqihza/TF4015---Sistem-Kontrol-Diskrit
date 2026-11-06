// ===========================================================================
// Tab ruang keadaan (Modul 4): model diskrit, umpan balik keadaan, observer
//
// Keadaan x = [posisi (%); kecepatan bertanda (%)], masukan u (%).
// Model diskrit (ZOH, waktu tunda diabaikan):
//   x[k+1] = A x[k] + B u[k]
//   A = [1  A12; 0  A22],  B = [B1; B2]
// Parameter model berasal dari Modul 1 (ModelK, ModelTau) dan Modul 3
// (ModelC). Gain dihitung dengan skrip desain_state_space.m.
// ===========================================================================

// Parameter model (Tau dalam ms, C dalam %/ms per % kecepatan)
float ModelK = 0.85, ModelTau = 60.0, ModelC = 0.02;
float A12 = 0.0, A22 = 0.0, B1 = 0.0, B2 = 0.0;

// Pole placement kecepatan (satu keadaan): u = Nspeed*r - Kspeed*v
float Kspeed = 0.0, Nspeed = 1.0;

// Pole placement posisi (dua keadaan): u = -(Kpos*(p - r) + Kvel*v)
float Kpos = 0.5, Kvel = 0.25;

// Observer A: keluaran terukur posisi (potensiometer) -> estimasi kecepatan
float Lp1 = 0.5, Lp2 = 0.4;
float PosHat = 0.0, VelHat = 0.0;

// Observer B: keluaran terukur kecepatan (tachometer) -> estimasi posisi
float Lv1 = 0.0, Lv2 = 0.0;
float PosHatT = 0.0, VelHatT = 0.0;

void state_space_setup(unsigned int Ts) {
  float a = exp(-(float) Ts / ModelTau);
  A12 = ModelC * ModelTau * (1.0 - a);
  A22 = a;
  B1 = ModelC * ModelK * ((float) Ts - ModelTau * (1.0 - a));
  B2 = ModelK * (1.0 - a);
}

float wrap_error(float e) {
  while (e > 50.0) e -= 100.0;
  while (e < -50.0) e += 100.0;
  return e;
}

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
  float NextPos = PosHat + A12 * VelHat + B1 * U + Lp1 * Innovation;
  float NextVel = A22 * VelHat + B2 * U + Lp2 * Innovation;
  PosHat = wrap_position(NextPos);
  VelHat = NextVel;

  // Observer B: koreksi berdasarkan error kecepatan
  float InnovationT = VelocityMeasured - VelHatT;
  float NextPosT = PosHatT + A12 * VelHatT + B1 * U + Lv1 * InnovationT;
  float NextVelT = A22 * VelHatT + B2 * U + Lv2 * InnovationT;
  PosHatT = wrap_position(NextPosT);
  VelHatT = NextVelT;
}
