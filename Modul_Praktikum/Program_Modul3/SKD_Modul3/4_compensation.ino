// ===========================================================================
// Tab kompensasi deadzone linier.
// Isi DeadZonePositif dan DeadZoneNegatif dengan masukan minimum putar motor
// hasil Modul 1 (atau nilai yang digunakan pada Modul 3).
// ===========================================================================
byte DeadZonePositif = 10, DeadZoneNegatif = 10;

float compensation(float Uncompensated) {
  if (Uncompensated < 0) {
    return Uncompensated * (100 - DeadZoneNegatif) / 100 - DeadZoneNegatif;
  }
  else if (Uncompensated > 0) {
    return Uncompensated * (100 - DeadZonePositif) / 100 + DeadZonePositif;
  }
  else return 0.0;
}
