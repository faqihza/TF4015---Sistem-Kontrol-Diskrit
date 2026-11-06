// ===========================================================================
// Program utama Modul 1: respons step untuk identifikasi dinamika
// Ganti isi tab 9_main.ino dengan program ini.
//
// Masukan motor mengikuti urutan Sequence[]; setiap nilai ditahan selama
// HoldTime. Data waktu, masukan, dan kecepatan dicetak setiap waktu cacah
// sehingga dapat disalin ke spreadsheet dan diolah dengan MATLAB.
//
// Contoh urutan:
//   step dari nol      : {0, 20, 0, 40, 0, 60, 0, 80, 0, 100, 0}
//   step berkelanjutan : {0, 20, 40, 60, 80, 100, 0}
// Gunakan masukan positif saja agar arah motor tidak berbalik.
// ===========================================================================

unsigned long Time, StartTime, LastTime, StepStart;
unsigned int TimeSampling = 10, DeltaTime;   // waktu cacah (ms)
unsigned int HoldTime = 2000;                // lama tiap nilai masukan (ms)
bool UseCompensation = true;                 // gunakan kompensasi deadzone dari Percobaan 4

int Sequence[] = {0, 20, 0, 40, 0, 60, 0, 80, 0, 100, 0};
const byte SequenceLength = sizeof(Sequence) / sizeof(Sequence[0]);

byte Index = 0;
float InputStep = 0.0, MotorInput = 0.0, Motor = 0.0, Speed = 0.0;
bool Finished = false;

void setup() {
  general_setup();
  sensor_setup();
  actuator_setup();
  Serial.println("Time\tDelta\tInput\tMotor\tKec");
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

    InputStep = (float) Sequence[Index];
    if (UseCompensation) MotorInput = compensation(InputStep);
    else MotorInput = InputStep;
    Motor = run_motor(MotorInput);
    Speed = smooth_velocity_percentage();

    Serial.print(Time - StartTime);
    Serial.print("\t");
    Serial.print(DeltaTime);
    Serial.print("\t");
    Serial.print(InputStep);
    Serial.print("\t");
    Serial.print(Motor);
    Serial.print("\t");
    Serial.println(Speed);

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
