// ===========================================================================
// Program utama Modul 4: pole placement dan observer (11_main_state_space)
// Isi tab 9_main.ino pada sketch SKD_Modul4.
//
// Mode 0 : kalang terbuka. Urutan berisi masukan motor (%). Untuk menguji
//          kedua observer (Percobaan 3).
// Mode 1 : pole placement kecepatan. Urutan berisi set point kecepatan
//          (%, positif saja) (Percobaan 2).
// Mode 2 : pole placement posisi. Urutan berisi set point posisi (%).
//          Kecepatan umpan balik dari observer A (UseObserver = true) atau
//          dari tachometer bertanda (UseObserver = false) (Percobaan 4).
// Mode 3 : PID posisi dengan parameter terbaik Modul 3, sebagai pembanding
//          (Percobaan 4). Kedua observer tetap berjalan.
// Pada Mode 2 dan 3, setelah urutan selesai set point terakhir dipertahankan
// (uji gangguan). Pada Mode 0 dan 1, motor dihentikan.
//
// Kolom data: Time | Delta | Ref | Pos | PosHat | PosHatT | VelT | VelHat | U
//   Ref     : masukan (Mode 0) atau set point (Mode 1-3)
//   Pos     : posisi terukur potensiometer (%)
//   PosHat  : estimasi posisi observer A (dari potensiometer)
//   PosHatT : estimasi posisi observer B (dari tachometer)
//   VelT    : kecepatan bertanda dari tachometer (%)
//   VelHat  : estimasi kecepatan observer A (%)
//   U       : masukan kontrol sebelum kompensasi deadzone (%)
// Baris yang diawali '#' berisi konfigurasi percobaan dan bukan data.
// ===========================================================================

// ============================ KONFIGURASI ==================================
byte Mode = 2;                     // 0, 1, 2, atau 3 (lihat keterangan di atas)
bool UseObserver = true;           // Mode 2: true = observer A, false = tachometer
unsigned int TimeSampling = 10;    // waktu cacah (ms), sama dengan desain
unsigned int HoldTime = 3000;      // lama tiap nilai urutan (ms)
byte Repeat = 1;                   // jumlah pengulangan urutan (uji simpangan observer B)
float UMax = 40.0;                 // batas masukan kontrol posisi (%), Mode 2 dan 3
float ErrorBand = 0.0;             // pita error posisi (%), Mode 2 dan 3

// Urutan tiap mode. Mode 0: ganti 12 dengan u_kecil kelompok. Urutan Mode 0
// harus melewati 0 sebelum berganti arah.
float Sequence0[] = {0, 12, 0, 30, 0, -30, 0, 60, 0, -60, 0};   // Mode 0: masukan (%)
float Sequence1[] = {0, 40, 70, 30, 0};                         // Mode 1: kecepatan (%)
float Sequence2[] = {50, 20, 50, 90, 20, 50};                   // Mode 2 dan 3: posisi (%)

// Salin baris hasil desain_state_space.m ke fungsi ini.
void gain_setup() {
  ModelK = 0.8500;  ModelTau = 60.00;  ModelC = 0.02000;
  Kspeed = 0.9959;  Nspeed = 2.1723;
  Kpos = 0.5419;    Kvel = 0.2654;
  Lp1 = 0.5657;     Lp2 = 0.4436;
  Lv1 = 0.1842;     Lv2 = 0.2400;

  // PID posisi terbaik Modul 3 (Mode 3). Ki dalam 1/ms, Kd dalam ms.
  // Nilai bawaan berasal dari contoh simulasi Modul 3; ganti dengan hasil kelompok.
  Kp = 0.6;
  Ki = 0.0;
  Kd = 20.0;
}
// ===========================================================================

unsigned long Time, StartTime, LastTime, StepStart;
unsigned int DeltaTime;

float *Sequence;
byte SequenceLength, Index = 0, Pass = 0;
bool Finished = false;

float Reference = 0.0, PositionMeasured = 0.0, Tacho = 0.0;
float SpeedSign = 1.0, VelocitySigned = 0.0, U = 0.0, Motor = 0.0;

void select_sequence() {
  if (Mode == 0) {
    Sequence = Sequence0;
    SequenceLength = sizeof(Sequence0) / sizeof(Sequence0[0]);
  }
  else if (Mode == 1) {
    Sequence = Sequence1;
    SequenceLength = sizeof(Sequence1) / sizeof(Sequence1[0]);
  }
  else {
    Sequence = Sequence2;
    SequenceLength = sizeof(Sequence2) / sizeof(Sequence2[0]);
  }
}

void print_configuration() {
  Serial.print("# Modul 4  Mode="); Serial.print(Mode);
  Serial.print("  UseObserver="); Serial.print(UseObserver ? 1 : 0);
  Serial.print("  Ts="); Serial.print(TimeSampling);
  Serial.print("  UMax="); Serial.print(UMax);
  Serial.print("  ErrorBand="); Serial.println(ErrorBand);
  Serial.print("# Ad12="); Serial.print(Ad12, 5);
  Serial.print("  Ad22="); Serial.print(Ad22, 5);
  Serial.print("  Bd1="); Serial.print(Bd1, 5);
  Serial.print("  Bd2="); Serial.println(Bd2, 5);
  Serial.print("# Kspeed="); Serial.print(Kspeed, 4);
  Serial.print("  Nspeed="); Serial.print(Nspeed, 4);
  Serial.print("  Kpos="); Serial.print(Kpos, 4);
  Serial.print("  Kvel="); Serial.println(Kvel, 4);
  Serial.print("# Lp1="); Serial.print(Lp1, 4);
  Serial.print("  Lp2="); Serial.print(Lp2, 4);
  Serial.print("  Lv1="); Serial.print(Lv1, 4);
  Serial.print("  Lv2="); Serial.println(Lv2, 4);
  Serial.print("# Kp="); Serial.print(Kp, 4);
  Serial.print("  Ki="); Serial.print(Ki, 6);
  Serial.print("  Kd="); Serial.print(Kd, 4);
  Serial.print("  DeadZone="); Serial.print(DeadZonePositif);
  Serial.print("/"); Serial.println(DeadZoneNegatif);
}

void setup() {
  general_setup();
  sensor_setup();
  actuator_setup();

  gain_setup();
  state_space_setup(TimeSampling);
  OutputMin = -UMax;   // batas PID Mode 3
  OutputMax = UMax;
  control_reset();
  select_sequence();
  observer_reset(smooth_position_percentage(), 0.0);

  print_configuration();
  Serial.println("Time\tDelta\tRef\tPos\tPosHat\tPosHatT\tVelT\tVelHat\tU");
  StartTime = millis();
  LastTime = StartTime;
  StepStart = StartTime;
}

void loop() {
  Time = millis();
  if (Time - LastTime >= TimeSampling) {
    DeltaTime = Time - LastTime;
    LastTime = Time;

    // 1. Pengukuran
    Reference = Sequence[Index];
    PositionMeasured = smooth_position_percentage();
    Tacho = smooth_velocity_percentage();

    // Tachometer tidak membedakan arah: tanda diambil dari arah putar
    // terakhir yang diperintahkan ke driver (variabel Direction).
    if (Direction != 0) SpeedSign = (float) Direction;
    VelocitySigned = SpeedSign * Tacho;

    // 2. Aksi kontrol
    if (Finished && Mode < 2) {
      U = 0.0;
    }
    else if (Mode == 0) {
      U = Reference;
    }
    else if (Mode == 1) {
      if (Reference <= 0.0) U = 0.0;
      else U = Nspeed * Reference - Kspeed * Tacho;
      if (U > 100.0) U = 100.0;
      if (U < 0.0) U = 0.0;
    }
    else {
      float Error = wrap_error(Reference - PositionMeasured);
      if (Mode == 2) {
        float Velocity = UseObserver ? VelHat : VelocitySigned;
        U = Kpos * Error - Kvel * Velocity;   // = -(Kpos*wrap(p - r) + Kvel*v)
        if (U > UMax) U = UMax;
        if (U < -UMax) U = -UMax;
      }
      else {
        U = control(Error, TimeSampling);     // dibatasi OutputMin dan OutputMax
      }
      if (Error <= ErrorBand && Error >= -ErrorBand) U = 0.0;
    }

    // 3. Masukan ke motor melalui kompensasi deadzone
    Motor = run_motor(compensation(U));
    if (Motor == 0.0 && U != 0.0) U = 0.0;   // satu cacah pengereman saat arah berbalik

    // 4. Pembaruan observer dengan masukan yang benar-benar diberikan
    observer_update(PositionMeasured, VelocitySigned, U);

    // 5. Pengiriman data
    Serial.print(Time - StartTime);
    Serial.print("\t");
    Serial.print(DeltaTime);
    Serial.print("\t");
    Serial.print(Reference);
    Serial.print("\t");
    Serial.print(PositionMeasured);
    Serial.print("\t");
    Serial.print(PosHat);
    Serial.print("\t");
    Serial.print(PosHatT);
    Serial.print("\t");
    Serial.print(VelocitySigned);
    Serial.print("\t");
    Serial.print(VelHat);
    Serial.print("\t");
    Serial.println(U);

    // 6. Perpindahan ke nilai urutan berikutnya
    if (!Finished && Time - StepStart >= HoldTime) {
      StepStart = Time;
      if (Index < SequenceLength - 1) {
        Index++;
      }
      else if (Pass < Repeat - 1) {
        Pass++;
        Index = 0;
      }
      else {
        Finished = true;
      }
    }
  }
}
