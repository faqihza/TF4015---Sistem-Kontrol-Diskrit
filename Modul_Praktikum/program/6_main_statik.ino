// ===========================================================================
// Program utama Modul 1: karakteristik statik (masukan bertingkat)
// Ganti isi tab 9_main.ino dengan program ini.
//
// Masukan motor dinaikkan bertahap dari 0 hingga 100% (atau 0 hingga -100%
// bila Sign = -1). Setiap tingkat ditahan selama HoldTime. Kecepatan tunak
// dihitung sebagai rata-rata bacaan kecepatan pada AverageTime terakhir.
// Untuk arah negatif, ubah Sign menjadi -1 lalu unggah ulang program
// (jangan membalik arah motor secara langsung).
// ===========================================================================

unsigned long Time, StartTime, LastTime, LevelStart;
unsigned int TimeSampling = 20, DeltaTime;   // waktu cacah (ms)
unsigned int HoldTime = 2000;                // lama tiap tingkat masukan (ms)
unsigned int AverageTime = 1000;             // rentang akhir tiap tingkat untuk rata-rata (ms)
int StepInput = 1;                           // kenaikan masukan tiap tingkat (%)
int Sign = 1;                                // 1: arah positif, -1: arah negatif
bool UseCompensation = false;                // true: masukan dikompensasi (Percobaan 4)
bool PrintAll = false;                       // true: cetak semua sampel, false: ringkasan tiap tingkat

int Level = 0;
float InputLevel = 0.0, MotorInput = 0.0, Motor = 0.0;
float Speed = 0.0, Position = 0.0, PositionStart = 0.0;
float SumSpeed = 0.0;
unsigned int CountSpeed = 0;
bool Finished = false;

void setup() {
  general_setup();
  sensor_setup();
  actuator_setup();
  print_header();
  StartTime = millis();
  LastTime = StartTime;
  LevelStart = StartTime;
  PositionStart = smooth_position_percentage();
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

    InputLevel = (float) (Sign * Level * StepInput);
    if (UseCompensation) MotorInput = compensation(InputLevel);
    else MotorInput = InputLevel;
    Motor = run_motor(MotorInput);

    Speed = smooth_velocity_percentage();
    Position = smooth_position_percentage();

    if (Time - LevelStart >= (unsigned long) (HoldTime - AverageTime)) {
      SumSpeed += Speed;
      CountSpeed++;
    }

    if (PrintAll) print_sample();

    if (Time - LevelStart >= HoldTime) {
      if (!PrintAll) print_summary();
      SumSpeed = 0.0;
      CountSpeed = 0;
      LevelStart = Time;
      PositionStart = Position;
      Level++;
      if (Level * StepInput > 100) {
        Finished = true;
        Serial.println("# selesai");
      }
    }
  }
}

void print_header() {
  if (PrintAll) Serial.println("Time\tDelta\tInput\tMotor\tKec\tPos");
  else Serial.println("Input\tMotor\tKecTunak\tPerubahanPos");
}

void print_sample() {
  Serial.print(Time - StartTime);
  Serial.print("\t");
  Serial.print(DeltaTime);
  Serial.print("\t");
  Serial.print(InputLevel);
  Serial.print("\t");
  Serial.print(Motor);
  Serial.print("\t");
  Serial.print(Speed);
  Serial.print("\t");
  Serial.println(Position);
}

void print_summary() {
  float PositionChange = Position - PositionStart;
  if (PositionChange < 0) PositionChange = -PositionChange;
  Serial.print(InputLevel);
  Serial.print("\t");
  Serial.print(Motor);
  Serial.print("\t");
  if (CountSpeed > 0) Serial.print(SumSpeed / CountSpeed);
  else Serial.print(Speed);
  Serial.print("\t");
  Serial.println(PositionChange);
}
