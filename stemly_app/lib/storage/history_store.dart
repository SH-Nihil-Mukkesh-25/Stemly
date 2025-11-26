import '../models/scan_history.dart';

class HistoryStore {
  static List<ScanHistory> _history = [];

  static void add(ScanHistory scan) {
    _history.insert(0, scan);
  }

  static void remove(ScanHistory scan) {
    _history.remove(scan);
  }

  static void setHistory(List<ScanHistory> list) {
    _history = list;
  }

  static List<ScanHistory> get history => _history;
}
