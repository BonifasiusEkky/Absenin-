class Assignment {
  final String id;
  final String title;
  final String? description;
  final String? imagePath; // local file path
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.title,
    this.description,
    this.imagePath,
    required this.createdAt,
  });
}
