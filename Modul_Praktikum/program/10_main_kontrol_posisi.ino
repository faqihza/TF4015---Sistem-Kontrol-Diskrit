// ===========================================================================
// Program utama Modul 3: kontrol posisi motor DC (10_main_kontrol_posisi)
// Isi tab 9_main.ino pada sketch SKD_Modul3.
//
// ClosedLoop = false : kalang terbuka (Percobaan 2 dan 3). Masukan motor
//                      dikirim melalui Serial Monitor (-100 hingga 100).
//                      Kembali ke 0 sebelum mengubah arah putar.
// ClosedLoop = true  : kontrol posisi (Percobaan 4). Set point mengikuti
//                      SetPointSequence[]. Setelah urutan selesai, set point
//                      terakhir dipertahankan (uji gangguan).
// Error posisi dibatasi pada rentang -50 hingga 50 karena bacaan posisi
// berpindah dari 100 ke 0 (dan sebaliknya).
//
// Kolom data: Time | Delta | SP | Pos | Kec | MV | Motor
//   SP    : set point posisi (%), 0 pada kalang terbuka
//   Pos   : posisi terukur potensiometer (%)
//   Kec   : kecepatan terukur tachometer (%, tanpa tanda arah)
//   MV    : masukan kontrol sebelum kompensasi deadzone (%)
//   Motor : masukan ke motor setelah kompensasi deadzone (%)
// Baris yang diawali '#' berisi konfigurasi percobaan dan bukan data.
// ===========================================================================

// ============================ KONFIGURASI ==================================
bool ClosedLoop = true;            // false = kalang terbuka, true = kontrol posisi
unsigned int TimeSampling = 10;    // waktu cacah (ms), waktu cacah pertama Modul 1
unsigned int HoldTime = 3000;      // lama tiap set point (ms)
float UMax = 40.0;                 // batas aksi kontrol (%), hasil Percobaan 3
float ErrorBand = 0.0;             // pita error (%): aksi kontrol nol bila |e| <= ErrorBand

float SetPointSequence[] = {50, 20, 50, 90, 20, 50};   // set point posisi (%)

// Parameter pengontrol (Tabel Ziegler-Nichols atau hasil penalaan halus).
// Ki = Kp/Ti dalam 1/ms, Kd = Kp*Td dalam ms.
void gain_setup() {
  Kp = 1.0;
  Ki = 0.0;
  Kd = 0.0;
}
// ===========================================================================

unsigned long Time, StartTime, LastTime, StepStart;
unsigned int DeltaTime;

const byte SequenceLength = sizeof(SetPointSequence) / sizeof(SetPointSequence[0]);
byte Index = 0;
int InputSerial = 0;
float SetPoint = 0.0, Position = 0.0, Speed = 0.0, Error = 0.0;
float ManipulatedVariable = 0.0, Motor = 0.0;

// Membatasi error posisi pada rentang -50 hingga 50 (jalur terpendek)
float wrap_error(float e) {
  while (e > 50.0) e -= 100.0;
  while (e < -50.0) e += 100.0;
  return e;
}

void print_configuration() {
  Serial.print("# Modul 3  ClosedLoop="); Serial.print(ClosedLoop ? 1 : 0);
  Serial.print("  Ts="); Serial.print(TimeSampling);
  Serial.print("  HoldTime="); Serial.print(HoldTime);
  Serial.print("  UMax="); Serial.print(UMax);
  Serial.print("  ErrorBand="); Serial.println(ErrorBand);
  Serial.print("# Kp="); Serial.print(Kp, 4);
  Serial.print("  Ki="); Serial.print(Ki, 6);
  Serial.print("  Kd="); Serial.print(Kd, 4);
  Serial.print("  DeadZone="); Serial.print(DeadZonePositif);
  Serial.print("/"); Serial.println(DeadZoneNegatif);
}

void setup() {
  general_setup();
  Serial.setTimeout(50);   // agar pembacaan Serial Monitor tidak menahan loop
  sensor_setup();
  actuator_setup();

  gain_setup();
  OutputMin = -UMax;
  OutputMax = UMax;
  control_reset();

  print_configuration();
  Serial.println("Time\tDelta\tSP\tPos\tKec\tMV\tMotor");
  StartTime = millis();
  LastTime = StartTime;
  StepStart = StartTime;
}

void loop() {
  if (!ClosedLoop) InputSerial = serial(InputSerial);
  Time = millis();
  if (Time - LastTime >= TimeSampling) {
    DeltaTime = Time - LastTime;
    LastTime = Time;

    // 1. Pengukuran
    Position = smooth_position_percentage();
    Speed = smooth_velocity_percentage();

    // 2. Aksi kontrol
    if (ClosedLoop) {
      SetPoint = SetPointSequence[Index];
      Error = wrap_error(SetPoint - Position);
      ManipulatedVariable = control(Error, TimeSampling);
      if (Error <= ErrorBand && Error >= -ErrorBand) ManipulatedVariable = 0.0;
    }
    else {
      SetPoint = 0.0;
      ManipulatedVariable = (float) InputSerial;
    }

    // 3. Masukan ke motor melalui kompensasi deadzone
    Motor = run_motor(compensation(ManipulatedVariable));

    // 4. Pengiriman data
    Serial.print(Time - StartTime);
    Serial.print("\t");
    Serial.print(DeltaTime);
    Serial.print("\t");
    Serial.print(SetPoint);
    Serial.print("\t");
    Serial.print(Position);
    Serial.print("\t");
    Serial.print(Speed);
    Serial.print("\t");
    Serial.print(ManipulatedVariable);
    Serial.print("\t");
    Serial.println(Motor);

    // 5. Perpindahan ke set point berikutnya
    if (ClosedLoop && Index < SequenceLength - 1 && Time - StepStart >= HoldTime) {
      StepStart = Time;
      Index++;
    }
  }
}
