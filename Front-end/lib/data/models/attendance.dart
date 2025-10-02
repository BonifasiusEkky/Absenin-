class AttendanceRecord {
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final bool isLeave; // izin / cuti
  final bool isSick;
  final bool isAbsent;

  AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    this.isLeave = false,
    this.isSick = false,
    this.isAbsent = false,
  });
}
