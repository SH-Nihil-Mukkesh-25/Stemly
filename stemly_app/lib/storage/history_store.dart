import '../models/scan_history.dart';

class HistoryStore {
  static final List<ScanHistory> _history = [];

  static void add(ScanHistory scan) {
    _history.add(scan);
  }

  static List<ScanHistory> get history => _history;
}
