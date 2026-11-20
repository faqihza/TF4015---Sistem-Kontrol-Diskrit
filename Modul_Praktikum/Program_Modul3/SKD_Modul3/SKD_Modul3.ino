// ===========================================================================
// TF4015 Sistem Kontrol Diskrit - Program Praktikum Modul 3
// Kontrol Posisi Motor DC
//
// Susunan tab:
//   SKD_Modul3.ino     : tab utama sketch (inisialisasi serial)
//   1_sensor.ino       : pembacaan tachometer (A0) dan potensiometer (A1)
//   2_actuator.ino     : DAC MCP4725 dan driver motor L293D
//   3_serial.ino       : pembacaan masukan dari Serial Monitor (kalang terbuka)
//   4_compensation.ino : kompensasi deadzone
//   5_control.ino      : PID diskrit dengan anti-windup
//   9_main.ino         : program utama Modul 3 (konfigurasi percobaan,
//                        setup, dan loop)
//
// Kebutuhan: Arduino UNO dan library "Adafruit MCP4725" (beserta dependensinya,
// "Adafruit BusIO") dari Library Manager. Baud rate Serial Monitor 115200,
// akhir baris "Newline".
// Seluruh pengaturan percobaan ada pada bagian KONFIGURASI di tab 9_main.ino.
// ===========================================================================

void general_setup() {
  Serial.begin(115200);
}
