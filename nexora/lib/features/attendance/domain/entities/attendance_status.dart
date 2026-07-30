enum AttendanceType {
  entrada('entrada'),
  saida('saida');

  final String value;

  const AttendanceType(this.value);

  static AttendanceType fromString(String value) {
    return AttendanceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AttendanceType.entrada,
    );
  }
}
