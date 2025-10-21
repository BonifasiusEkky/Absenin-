class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkIn; // time-only from backend, stored as today date+time for UI formatting
  final DateTime? checkOut;
  final double? latitude;
  final double? longitude;
  final double? distanceM;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? activityNote;
  // Flags used by UI filters (not from backend directly)
  final bool isLeave; // izin / cuti
  final bool isSick;
  final bool isAbsent;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.latitude,
    this.longitude,
    this.distanceM,
    this.createdAt,
    this.updatedAt,
    this.activityNote,
    this.isLeave = false,
    this.isSick = false,
    this.isAbsent = false,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final checkInStr = json['check_in'] as String?;
    final checkOutStr = json['check_out'] as String?;
    final now = DateTime.now();
    DateTime? _parseTime(String? t) {
      if (t == null) return null;
      // Backend returns time like HH:MM:SS; embed into today for UI time formatting
      final parts = t.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return DateTime(now.year, now.month, now.day, h, m);
    }
    return AttendanceRecord(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      date: dateStr != null ? DateTime.parse(dateStr) : now,
      checkIn: _parseTime(checkInStr),
      checkOut: _parseTime(checkOutStr),
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : null,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : null,
      distanceM: (json['distance_m'] is num) ? (json['distance_m'] as num).toDouble() : null,
      createdAt: (json['created_at'] != null) ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: (json['updated_at'] != null) ? DateTime.tryParse(json['updated_at']) : null,
      activityNote: (json['activity_note'] as String?)
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'check_in': checkIn != null ? '${checkIn!.hour.toString().padLeft(2, '0')}:${checkIn!.minute.toString().padLeft(2, '0')}:00' : null,
        'check_out': checkOut != null ? '${checkOut!.hour.toString().padLeft(2, '0')}:${checkOut!.minute.toString().padLeft(2, '0')}:00' : null,
        'latitude': latitude,
        'longitude': longitude,
        'distance_m': distanceM,
        'activity_note': activityNote,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
