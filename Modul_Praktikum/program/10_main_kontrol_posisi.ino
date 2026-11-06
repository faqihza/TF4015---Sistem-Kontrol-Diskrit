// ===========================================================================
// Program utama Modul 3: kontrol posisi motor DC
// Ganti isi tab 9_main.ino dengan program ini.
//
// ClosedLoop = false : kalang terbuka, masukan motor dikirim melalui
//                      Serial Monitor (-100 hingga 100).
// ClosedLoop = true  : kontrol posisi dengan set point mengikuti
//                      SetPointSequence[]. Setelah urutan selesai, set point
//                      terakhir dipertahankan (untuk uji gangguan).
// Error posisi dibatasi pada rentang -50 hingga 50 karena bacaan posisi
// berpindah dari 100 ke 0 (dan sebaliknya).
// ===========================================================================

unsigned long Time, StartTime, LastTime, StepStart;
unsigned int TimeSampling = 10, DeltaTime;   // waktu cacah (ms)
unsigned int HoldTime = 3000;                // lama tiap set point (ms)
bool ClosedLoop = true;
float ErrorBand = 0.0;                       // pita error (%) tempat keluaran dibuat nol

float SetPointSequence[] = {50, 20, 50, 90, 20, 50};
const byte SequenceLength = sizeof(SetPointSequence) / sizeof(SetPointSequence[0]);

byte Index = 0;
int InputSerial = 0;
float SetPoint = 0.0, Position = 0.0, Speed = 0.0, Error = 0.0;
float ManipulatedVariable = 0.0, Motor = 0.0;

float wrap_error(float e) {
  while (e > 50.0) e -= 100.0;
  while (e < -50.0) e += 100.0;
  return e;
}

void setup() {
  general_setup();
  sensor_setup();
  actuator_setup();

  // Parameter pengontrol (Ki dalam 1/ms, Kd dalam ms)
  Kp = 1.0;
  Ki = 0.0;
  Kd = 0.0;
  OutputMin = -40.0;   // batas aksi kontrol sesuai klasifikasi kalang terbuka
  OutputMax = 40.0;
  control_reset();

  Serial.println("Time\tDelta\tSP\tPos\tKec\tMV\tMotor");
  StartTime = millis();
  LastTime = StartTime;
  StepStart = StartTime;
}

void loop() {
  InputSerial = serial(InputSerial);
  Time = millis();
  if (Time - LastTime >= TimeSampling) {
    DeltaTime = Time - LastTime;
    LastTime = Time;

    Position = smooth_position_percentage();
    Speed = smooth_velocity_percentage();

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

    Motor = run_motor(compensation(ManipulatedVariable));

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

    if (ClosedLoop && Index < SequenceLength - 1 && Time - StepStart >= HoldTime) {
      StepStart = Time;
      Index++;
    }
  }
}
