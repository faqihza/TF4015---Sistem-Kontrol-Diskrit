// ===========================================================================
// Program utama Modul 4: pole placement dan observer
// Ganti isi tab 9_main.ino dengan program ini. Tab 6_state_space.ino harus
// sudah ditambahkan.
//
// Mode = 0 : kalang terbuka. Sequence[] berisi masukan motor (%). Digunakan
//            untuk menguji kedua observer.
// Mode = 1 : pole placement kecepatan. Sequence[] berisi set point kecepatan
//            (%, positif saja).
// Mode = 2 : pole placement posisi. Sequence[] berisi set point posisi (%).
//            Kecepatan umpan balik dari observer (UseObserver = true) atau
//            dari tachometer bertanda (UseObserver = false). Setelah urutan
//            selesai, set point terakhir dipertahankan.
// ===========================================================================

unsigned long Time, StartTime, LastTime, StepStart;
unsigned int TimeSampling = 10, DeltaTime;   // waktu cacah (ms)
unsigned int HoldTime = 3000;                // lama tiap nilai Sequence (ms)
byte Mode = 0;
bool UseObserver = true;
float UMax = 40.0;                           // batas masukan pada Mode 2 (%)

float Sequence[] = {0, 30, 0, -30, 0, 60, 0, -60, 0};
const byte SequenceLength = sizeof(Sequence) / sizeof(Sequence[0]);

byte Index = 0;
float Reference = 0.0, PositionMeasured = 0.0, Tacho = 0.0;
float SpeedSign = 1.0, VelocitySigned = 0.0, U = 0.0, Motor = 0.0;
bool Finished = false;

void setup() {
  general_setup();
  sensor_setup();
  actuator_setup();

  // Parameter model dan gain hasil desain_state_space.m
  ModelK = 0.85;  ModelTau = 60.0;  ModelC = 0.02;
  Kspeed = 0.0;   Nspeed = 1.0;
  Kpos = 0.5;     Kvel = 0.25;
  Lp1 = 0.5;      Lp2 = 0.4;
  Lv1 = 0.0;      Lv2 = 0.0;

  state_space_setup(TimeSampling);
  observer_reset(smooth_position_percentage(), 0.0);

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

    Reference = Sequence[Index];
    PositionMeasured = smooth_position_percentage();
    Tacho = smooth_velocity_percentage();

    // Tachometer tidak membedakan arah: tanda diambil dari arah putar
    // terakhir yang diperintahkan ke driver (variabel Direction).
    if (Direction != 0) SpeedSign = (float) Direction;
    VelocitySigned = SpeedSign * Tacho;

    if (Finished && Mode != 2) {
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
      float Velocity = UseObserver ? VelHat : VelocitySigned;
      U = -(Kpos * wrap_error(PositionMeasured - Reference) + Kvel * Velocity);
      if (U > UMax) U = UMax;
      if (U < -UMax) U = -UMax;
    }

    Motor = run_motor(compensation(U));
    if (Motor == 0.0 && U != 0.0) U = 0.0;   // satu cacah pengereman saat arah berbalik
    observer_update(PositionMeasured, VelocitySigned, U);

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

    if (!Finished && Time - StepStart >= HoldTime) {
      StepStart = Time;
      if (Index < SequenceLength - 1) Index++;
      else Finished = true;
    }
  }
}
