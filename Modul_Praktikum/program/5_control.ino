// ===========================================================================
// Tab kontrol: PID diskrit dengan pembatas keluaran dan anti-windup
//
// Satuan yang digunakan:
//   Error         : persen (%)
//   Ts            : milidetik (ms)
//   Kp            : -        (persen masukan per persen error)
//   Ki = Kp / Ti  : 1/ms
//   Kd = Kp * Td  : ms
// Nilai Kp, Ki, Kd, OutputMin, dan OutputMax diatur pada setup() program utama.
// ===========================================================================

float Kp = 1.0, Ki = 0.0, Kd = 0.0;
float OutputMin = 0.0, OutputMax = 100.0;
float LastError = 0.0, AccumulationError = 0.0;
bool FirstSample = true;

void control_reset() {
  LastError = 0.0;
  AccumulationError = 0.0;
  FirstSample = true;
}

float control(float Error, unsigned int Ts) {
  float DeltaError = 0.0;
  if (!FirstSample) DeltaError = (Error - LastError) / Ts;
  FirstSample = false;

  float Output = Kp * Error + Ki * (AccumulationError + Error * Ts) + Kd * DeltaError;

  // Anti-windup (integrasi bersyarat): error hanya diakumulasi bila keluaran
  // tidak saturasi, atau bila error membantu keluaran keluar dari saturasi.
  if (Output > OutputMax) {
    Output = OutputMax;
    if (Error < 0) AccumulationError += Error * Ts;
  }
  else if (Output < OutputMin) {
    Output = OutputMin;
    if (Error > 0) AccumulationError += Error * Ts;
  }
  else {
    AccumulationError += Error * Ts;
  }

  LastError = Error;
  return Output;
}
