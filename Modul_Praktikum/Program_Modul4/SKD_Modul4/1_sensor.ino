// ===========================================================================
// Tab sensor: tachometer (A0) dan potensiometer (A1)
// Bacaan dinyatakan dalam persen skala ADC (0-100%).
// ===========================================================================
#define PinTachometer A0
#define PinPotensiometer A1

int MaxTachometer = 1023;

void sensor_setup() {
  pinMode(PinTachometer, INPUT);
  pinMode(PinPotensiometer, INPUT);
}

float sample_velocity_percentage() {
  return (float) analogRead(PinTachometer) * 100 / MaxTachometer;
}

float sample_position_percentage() {
  return (float) analogRead(PinPotensiometer) * 100 / 1023;
}

float smooth_pin(int Pin, byte SizeRead) {
  unsigned int TotalRead = 0;
  for (byte i = 0; i < SizeRead; i++) {
    TotalRead += analogRead(Pin);
  }
  return (float) TotalRead / SizeRead;
}

float smooth_velocity_percentage() {
  return smooth_pin(PinTachometer, 10) * 100 / MaxTachometer;
}

float smooth_position_percentage() {
  return smooth_pin(PinPotensiometer, 10) * 100 / 1023;
}
