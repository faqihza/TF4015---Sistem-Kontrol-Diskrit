/**************************************************************************/
/*
  Menggunakan jumper male-female hubungkan modul MCP4725 ke Arduino :
  OUT : A0
  GND : GND
  SCL : SCL atau A5
  SCA : SCA atau A4
  VCC : 5V
  GND : GND
  MCP berfungsi dengan baik apabila
*/
/**************************************************************************/
#include <Wire.h>
#include <Adafruit_MCP4725.h>

#define PinOUTMCP A0

//Inisialisasi
byte SizeRead = 30; // maksimal 64
unsigned int TotalRead = 0;
float Average;
float OUT1, OUT2;

Adafruit_MCP4725 dac;

void setup(void) {
  Serial.begin(9600);
  Serial.println("Hello!");
  pinMode(PinOUTMCP, INPUT);

  // For Adafruit MCP4725A1 the address is 0x62 (default) or 0x63 (ADDR pin tied to VCC)
  // For MCP4725A0 the address is 0x60 or 0x61
  // For MCP4725A2 the address is 0x64 or 0x65
  dac.begin(0x60);

  Serial.println("Generating a triangle wave");
  Serial.println("MCP\tOUT1\tOUT2");
}

void loop(void) {
  uint32_t counter;
  // Run through the full 12-bit scale for a triangle wave
  for (counter = 0; counter < 4095; counter += 5)
  {
    dac.setVoltage(counter, false);
    OUT1 = sampling(PinOUTMCP);
    OUT2 = smooth(PinOUTMCP);
    Serial.print(counter);
    Serial.print("\t");
    Serial.print(OUT1);
    Serial.print("\t");
    Serial.println(OUT2);
  }
  for (counter = 4095; counter > 0; counter--)
  {
    dac.setVoltage(counter, false);
    OUT1 = sampling(PinOUTMCP);
    OUT2 = smooth(PinOUTMCP);
    Serial.print(counter);
    Serial.print("\t");
    Serial.print(OUT1);
    Serial.print("\t");
    Serial.println(OUT2);
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
