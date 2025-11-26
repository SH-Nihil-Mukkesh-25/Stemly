class ScanHistory {
  final String topic;
  final List<String> variables;
  final String imagePath;
  final Map<String, dynamic> notesJson;
  bool isStarred;
  final DateTime timestamp;

  ScanHistory({
    required this.topic,
    required this.variables,
    required this.imagePath,
    required this.notesJson,
    this.isStarred = false,
    required this.timestamp,
  });
}
