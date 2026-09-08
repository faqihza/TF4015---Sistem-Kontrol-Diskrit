/*
   Program menggerakkan motor dengan cara memberikan input serial dalam rentang
   nilai -100 sampai 100
*/

//Library yang diperlukan
#include <Adafruit_MCP4725.h>

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
float Speed;

//time
unsigned long Time, LastTime, StartTime;
unsigned int TimeSampling = 0; // dalam milidetik

//motor
int InputSerial;
float InputVoltage;
int Direction, LastDirection = 0; // [(1:CW),(-1:CCW),(0:Neutral)]
uint32_t InputMCP;
Adafruit_MCP4725 DAC;

void setup() {
  // put your setup code here, to run once:
  digitalWrite(En, HIGH);
  Serial.begin(9600);
  DAC.begin(0x60);
  pinMode(PinTacho, INPUT);
  pinMode(PinPoten, INPUT);
//  Serial.print("Time");
//  Serial.print("\t");
  Serial.print("Input");
  Serial.print("\t");
  Serial.println("Output");
  StartTime = millis();
  LastTime = StartTime;
}

void loop() {
  // put your main code here, to run repeatedly:
  Time = millis();
  serial();
  if (Time - LastTime >= TimeSampling) {
    LastTime = Time;
    InputVoltage = (float) InputSerial;
    motor(InputVoltage);
    Speed = smooth(PinTacho);
//    Serial.print(LastTime - StartTime - TimeSampling);
//    Serial.print("\t");
    Serial.print(InputVoltage);
    Serial.print("\t");
    Serial.println(Speed);
  }
}

void motor(float InputPercentage) {
  // fungsi menggerakkan motor berdasarkan input
  if (InputPercentage > 0) { // CW
    InputMCP = 4095 * InputPercentage / 100;
    digitalWrite(In1, HIGH);
    digitalWrite(In2, LOW);
    Direction = 1;
  }
  else if (InputPercentage < 0) { // CCW
    InputMCP = -4095 * InputPercentage / 100;
    digitalWrite(In1, LOW);
    digitalWrite(In2, HIGH);
    Direction = -1;
  }
  else { // Neutral
    InputMCP = 0;
    Direction = 0;
  }
  if (Direction * LastDirection < 0) { // fastbreak if change direction
    DAC.setVoltage(0, false);
    digitalWrite(In1, LOW);
    digitalWrite(In2, LOW);
  }
  else { // give input to motor
    DAC.setVoltage(InputMCP, false);
  }
  LastDirection = Direction;
}

void serial() {
  // fungsi menerima input serial
  if (Serial.available() > 0) {
    InputSerial = Serial.parseInt();
    if (InputSerial > 100) InputSerial = 100;
    else if (InputSerial < -100) InputSerial = -100;
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
