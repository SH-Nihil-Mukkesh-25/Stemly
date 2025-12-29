class ScanHistory {
  final String topic;
  final List<String> variables;
  final String imagePath;
  final Map<String, dynamic> notesJson;
  bool isStarred;
  final DateTime timestamp;
  List<Map<String, dynamic>> quizResults;

  ScanHistory({
    required this.topic,
    required this.variables,
    required this.imagePath,
    required this.notesJson,
    this.isStarred = false,
    required this.timestamp,
    this.quizResults = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      "topic": topic,
      "variables": variables,
      "imagePath": imagePath,
      "notesJson": notesJson,
      "isStarred": isStarred,
      "timestamp": timestamp.toIso8601String(),
      "quizResults": quizResults,
    };
  }

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      topic: json["topic"] ?? "Unknown",
      variables: List<String>.from(json["variables"] ?? []),
      imagePath: json["imagePath"] ?? "",
      notesJson: Map<String, dynamic>.from(json["notesJson"] ?? {}),
      isStarred: json["isStarred"] ?? false,
      timestamp: DateTime.tryParse(json["timestamp"] ?? "") ?? DateTime.now(),
      quizResults: List<Map<String, dynamic>>.from(
        (json["quizResults"] ?? []).map((x) => Map<String, dynamic>.from(x)),
      ),
    );
  }
}
