// lib/visualiser/services/visualiser_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'visualiser_models.dart';

class VisualiserApi {
  final String baseUrl;
  final String? idToken; // Firebase ID token (optional)

  VisualiserApi({required this.baseUrl, this.idToken});

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (idToken != null && idToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }
    return headers;
  }

  Future<VisualTemplate> generateTemplate({
    required String topic,
    List<String>? variables,
    String? userId,
  }) async {
    final url = Uri.parse('$baseUrl/visualiser/generate');
    final body = jsonEncode({
      'topic': topic,
      'variables': variables ?? [],
      'user_id': userId,
    });

    final res = await http.post(url, headers: _headers(), body: body);
    if (res.statusCode >= 400) {
      throw Exception('Failed generate template: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    final templateJson = data['template'] as Map<String, dynamic>;
    return VisualTemplate.fromJson(templateJson);
  }

  Future<Map<String, dynamic>> updateParameters({
    required String templateId,
    required Map<String, dynamic> parameters,
    String? userPrompt,
    String? userId,
  }) async {
    final url = Uri.parse('$baseUrl/visualiser/update');
    final body = jsonEncode({
      'template_id': templateId,
      'parameters': parameters,
      'user_prompt': userPrompt,
      'user_id': userId,
    });
    final res = await http.post(url, headers: _headers(), body: body);
    if (res.statusCode >= 400) {
      throw Exception('Failed update params: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
