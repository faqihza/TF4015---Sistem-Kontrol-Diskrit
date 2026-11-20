// ===========================================================================
// Tab serial: membaca bilangan bulat dari Serial Monitor (-100 hingga 100).
// Dipakai pada mode kalang terbuka (ClosedLoop = false).
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
