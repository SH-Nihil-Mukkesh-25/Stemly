import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class GroqService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  // Configuration
  String? _apiKey;
  bool _isValidating = false;
  String _provider = "xAI";
  String _baseUrl = "https://api.x.ai/v1/chat/completions";
  String _modelName = "grok-beta";

  String? get apiKey => _apiKey;
  String get provider => _provider; 
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
  bool get isValidating => _isValidating;

  /// Load API Key from secure storage on startup
  Future<void> loadApiKey() async {
    _apiKey = await _storage.read(key: 'xai_api_key');
    if (_apiKey != null) _configureProvider(_apiKey!);
    notifyListeners();
  }

  /// Save and Validate API Key
  Future<String?> setApiKey(String key) async {
    _isValidating = true;
    notifyListeners();
    
    // Clean key (remove quotes and spaces)
    key = key.trim().replaceAll('"', '').replaceAll("'", "");

    _configureProvider(key); 

    String? error = await _testApiKey(key);

    if (error == null) {
      _apiKey = key;
      await _storage.write(key: 'xai_api_key', value: key);
    } 

    _isValidating = false;
    notifyListeners();
    return error;
  }

  /// Remove API Key
  Future<void> removeApiKey() async {
    _apiKey = null;
    await _storage.delete(key: 'xai_api_key');
    notifyListeners();
  }
  
  /// Auto-detect Provider
  void _configureProvider(String key) {
    if (key.startsWith("AIza")) {
       _provider = "Gemini";
       // Validation URL for Gemini (Google AI Free Tier)
       _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key";
       _modelName = "gemini-2.5-flash";
    } else if (key.startsWith("sk-or-")) {
       _provider = "OpenRouter";
       _baseUrl = "https://openrouter.ai/api/v1/chat/completions";
       _modelName = "google/gemini-2.0-flash-exp:free"; // High quality free model
    } else if (key.startsWith("sk-")) {
      _provider = "OpenAI";
      _baseUrl = "https://api.openai.com/v1/chat/completions";
      _modelName = "gpt-4o-mini"; 
    } else if (key.startsWith("gsk_")) {
      _provider = "Groq";
      _baseUrl = "https://api.groq.com/openai/v1/chat/completions";
      _modelName = "llama-3.3-70b-versatile";
    } else {
      _provider = "xAI";
      _baseUrl = "https://api.x.ai/v1/chat/completions";
      _modelName = "grok-beta";
    }
  }

  /// Test connection to AI Provider
  Future<String?> _testApiKey(String key) async {
    try {
      dynamic body;
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      if (_provider == "Gemini") {
        // Gemini REST API Body
        body = {
          "contents": [{
            "parts": [{"text": "Ping"}]
          }]
        };
        // API Key is already in URL for Gemini
      } else {
        // OpenAI Compatible Body
        headers['Authorization'] = 'Bearer $key';
        body = {
          "model": _modelName,
          "messages": [
            {"role": "user", "content": "Ping"}
          ],
          "max_tokens": 1
        };
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print("$_provider Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        // Try to parse detailed error from JSON
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson['error'] != null && errorJson['error']['message'] != null) {
            return "${response.statusCode} - ${errorJson['error']['message']}";
          }
        } catch (_) {}
        
        return "$_provider Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Connection Error: $e";
    }
  }
}
