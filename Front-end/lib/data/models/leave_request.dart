class LeaveRequest {
  final String id;
  final int userId;
  final String type; // annual|sick|other
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status; // pending|approved|rejected
  final String? attachmentPath;
  final int? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;
  final DateTime? createdAt;

  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.attachmentPath,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
    this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return LeaveRequest(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String?) ?? 'annual',
      startDate: DateTime.parse((json['start_date'] as String?) ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse((json['end_date'] as String?) ?? DateTime.now().toIso8601String()),
      reason: json['reason'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      attachmentPath: json['attachment_path'] as String?,
      decidedBy: (json['decided_by'] as num?)?.toInt(),
      decidedAt: parseDate(json['decided_at']),
      decisionNote: json['decision_note'] as String?,
      createdAt: parseDate(json['created_at']),
    );
  }

  int get days => endDate.difference(startDate).inDays + 1;
}
