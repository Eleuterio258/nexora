enum AttendanceMethod {
  manual('manual'),
  qrCode('qr_code'),
  facial('facial'),
  selfieGps('selfie_gps'),
  pin('pin'),
  nfc('nfc'),
  fingerprint('fingerprint');

  final String value;

  const AttendanceMethod(this.value);

  static AttendanceMethod fromString(String value) {
    return AttendanceMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AttendanceMethod.manual,
    );
  }
}
