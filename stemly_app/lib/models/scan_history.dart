class ScanHistory {
  final String topic;
  final List<String> variables;
  final String imagePath;
  final DateTime timestamp;

  ScanHistory({
    required this.topic,
    required this.variables,
    required this.imagePath,
    required this.timestamp,
  });
}
