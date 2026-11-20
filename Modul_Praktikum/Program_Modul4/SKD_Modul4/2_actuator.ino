// ===========================================================================
// Tab aktuator: DAC MCP4725 (I2C 0x60) dan driver L293D (EN D11, IN1 D10,
// IN2 D9). Masukan motor -100% hingga 100%; tanda menentukan arah putar.
// Saat arah berbalik, motor direm selama satu pemanggilan (fast brake).
// ===========================================================================
#include <Adafruit_MCP4725.h>

#define PinEn 11
#define PinIn1 10
#define PinIn2 9

int Direction, LastDirection = 0;
Adafruit_MCP4725 DAC;

void actuator_setup() {
  DAC.begin(0x60);
  pinMode(PinEn, OUTPUT);
  pinMode(PinIn1, OUTPUT);
  pinMode(PinIn2, OUTPUT);
  digitalWrite(PinEn, HIGH);
  digitalWrite(PinIn1, LOW);
  digitalWrite(PinIn2, LOW);
}

int clock_wise() {
  digitalWrite(PinIn1, HIGH);
  digitalWrite(PinIn2, LOW);
  return 1;
}

int counter_clock_wise() {
  digitalWrite(PinIn2, HIGH);
  digitalWrite(PinIn1, LOW);
  return -1;
}

int fast_break() {
  digitalWrite(PinIn1, LOW);
  digitalWrite(PinIn2, LOW);
  return 0;
}

float percentage_limit(float Percent) {
  if (Percent > 100.0) return 100.0;
  else if (Percent < -100.0) return -100.0;
  else return Percent;
}

void set_voltage(int Sign, float Percent) {
  uint32_t InputMCP = Sign * 4095 * Percent / 100;
  DAC.setVoltage(InputMCP, false);
}

float run_motor(float InputPercentage) {
  InputPercentage = percentage_limit(InputPercentage);
  if (InputPercentage > 0.0) Direction = clock_wise();
  else if (InputPercentage < 0.0) Direction = counter_clock_wise();
  else Direction = fast_break();
  if (Direction * LastDirection < 0) Direction = fast_break();
  set_voltage(Direction, InputPercentage);
  LastDirection = Direction;
  return (float) Direction * Direction * InputPercentage;
}
