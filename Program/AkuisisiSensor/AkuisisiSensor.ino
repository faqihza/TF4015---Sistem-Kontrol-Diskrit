/*
   Program akuisisi sensor
*/

//Definisi pin
#define PinTacho A0
#define PinPoten A1
#define En 11
#define In1 10
#define In2 9

//Inisialisasi
//sensor
byte SizeRead = 30; // maksimal 64
unsigned int TotalRead = 0;
float Average;
float Position1, Position2;

//time
unsigned long Time, LastTime, StartTime;
unsigned int TimeSampling = 0; // dalam milidetik

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  pinMode(PinTacho, INPUT);
  pinMode(PinPoten, INPUT);
//  Serial.print("Time");
//  Serial.print("\t");
  Serial.print("Sample");
  Serial.print("\t");
  Serial.println("Smooth");
  StartTime - millis();
  LastTime = StartTime;
}

void loop() {
  // put your main code here, to run repeatedly:
  Time = millis();
  if (Time - LastTime >= TimeSampling) {
    LastTime = Time;
    Position1 = sampling(PinPoten);
    Position2 = smooth(PinPoten);
//    Serial.print(LastTime - StartTime - TimeSampling);
//    Serial.print("\t");
    Serial.print(Position1);
    Serial.print("\t");
    Serial.println(Position2);
  }
}

float sampling(int Pin) {
  // fungsi akuisisi sensor langsung dari pin analog,
  // kemudian hasil akuisisi dikonversi menjadi persen
  return (float) analogRead(Pin) * 100 / 1023;
}

float smooth(int Pin) {
  // fungsi akuisisi sensor beberapa kali, hasil akuisisi dirata-rata,
  // kemudian dikonversi menjadi persen
  for (byte i = 0; i < SizeRead; i++) {
    TotalRead += analogRead(Pin);
  }
  Average = (float) TotalRead / SizeRead;
  TotalRead = 0;
  return Average * 100 / 1023;
}
