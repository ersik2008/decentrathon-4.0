class HistoryItem {
  final String id;
  final DateTime date;
  final String cleanliness;
  final int cleanlinessConfidence;
  final String integrity;
  final int integrityConfidence;
  final String? imagePath;

  HistoryItem({
    required this.id,
    required this.date,
    required this.cleanliness,
    required this.cleanlinessConfidence,
    required this.integrity,
    required this.integrityConfidence,
    this.imagePath,
  });
}