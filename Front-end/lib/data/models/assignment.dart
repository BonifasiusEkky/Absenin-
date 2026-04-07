class Assignment {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl; // server-provided URL (e.g. /storage/...)
  final DateTime? createdAt;

  Assignment({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return Assignment(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: parseDate(json['created_at']),
    );
  }
}
