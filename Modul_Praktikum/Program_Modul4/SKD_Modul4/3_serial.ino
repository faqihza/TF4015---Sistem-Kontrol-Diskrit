// ===========================================================================
// Tab serial: membaca bilangan bulat dari Serial Monitor (-100 hingga 100).
// Tidak dipakai oleh program utama Modul 4, disertakan agar sketch lengkap.
// ===========================================================================
int serial(int SerialRead) {
  if (Serial.available() > 0) {
    String StringSerial = Serial.readStringUntil('\n');
    SerialRead = StringSerial.toInt();
    if (SerialRead > 100) return 100;
    else if (SerialRead < -100) return -100;
  }
  return SerialRead;
}
