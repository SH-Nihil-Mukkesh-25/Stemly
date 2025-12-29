import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history.dart';

class HistoryStore {
  static List<ScanHistory> _history = [];
  static const String _key = 'stemly_history_v1';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _history = decoded
            .map((e) => ScanHistory.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Handle corrupt data by clearing or ignoring
        print("Error loading history: $e");
      }
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> add(ScanHistory scan) async {
    _history.insert(0, scan);
    await _save();
  }

  static Future<void> remove(ScanHistory scan) async {
    _history.remove(scan);
    await _save();
  }
  
  // For updates like adding quiz results or starring
  static Future<void> update() async {
    await _save();
  }

  static void setHistory(List<ScanHistory> list) {
    _history = list;
    _save();
  }

  static List<ScanHistory> get history => _history;
}
