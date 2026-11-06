// ===========================================================================
// Program utama Modul 2: kontrol kecepatan motor DC
// Ganti isi tab 9_main.ino dengan program ini.
//
// Set point mengikuti urutan SetPointSequence[]; setiap nilai ditahan selama
// HoldTime. Bila ClosedLoop = false, set point langsung diberikan sebagai
// masukan motor (kalang terbuka) sebagai pembanding.
// Kecepatan hanya dikontrol untuk satu arah putar karena bacaan tachometer
// selalu positif.
// ===========================================================================

unsigned long Time, StartTime, LastTime, StepStart;
unsigned int TimeSampling = 10, DeltaTime;   // waktu cacah (ms)
unsigned int HoldTime = 3000;                // lama tiap set point (ms)
bool ClosedLoop = true;                      // false: kalang terbuka

float SetPointSequence[] = {0, 60, 0};       // contoh lain: {0, 50, 80, 20, 0}
const byte SequenceLength = sizeof(SetPointSequence) / sizeof(SetPointSequence[0]);

byte Index = 0;
float SetPoint = 0.0, Speed = 0.0, ManipulatedVariable = 0.0, Motor = 0.0;
bool Finished = false;

void setup() {
  general_setup();
  sensor_setup();
  actuator_setup();

  // Parameter pengontrol (Ki dalam 1/ms, Kd dalam ms)
  Kp = 1.0;
  Ki = 0.0;
  Kd = 0.0;
  OutputMin = 0.0;
  OutputMax = 100.0;
  control_reset();

  Serial.println("Time\tDelta\tSP\tKec\tMV\tMotor");
  StartTime = millis();
  LastTime = StartTime;
  StepStart = StartTime;
}

void loop() {
  Time = millis();
  if (Time - LastTime >= TimeSampling) {
    DeltaTime = Time - LastTime;
    LastTime = Time;

    if (Finished) {
      run_motor(0.0);
      return;
    }

    SetPoint = SetPointSequence[Index];
    Speed = smooth_velocity_percentage();

    if (SetPoint <= 0.0) {
      ManipulatedVariable = 0.0;
      control_reset();
    }
    else if (ClosedLoop) {
      ManipulatedVariable = control(SetPoint - Speed, TimeSampling);
    }
    else {
      ManipulatedVariable = SetPoint;
    }

    Motor = run_motor(compensation(ManipulatedVariable));

    Serial.print(Time - StartTime);
    Serial.print("\t");
    Serial.print(DeltaTime);
    Serial.print("\t");
    Serial.print(SetPoint);
    Serial.print("\t");
    Serial.print(Speed);
    Serial.print("\t");
    Serial.print(ManipulatedVariable);
    Serial.print("\t");
    Serial.println(Motor);

    if (Time - StepStart >= HoldTime) {
      StepStart = Time;
      Index++;
      if (Index >= SequenceLength) {
        Finished = true;
        Serial.println("# selesai");
      }
    }
  }
}
