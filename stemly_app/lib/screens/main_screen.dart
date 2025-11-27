import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../widgets/bottom_nav_bar.dart';
import '../storage/history_store.dart';
import '../models/scan_history.dart';
import 'scan_result_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ImagePicker _picker = ImagePicker();
  bool loading = false;

  final String serverIp = "http://10.0.2.2:8000";

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;
      setState(() => loading = true);
      await _uploadImage(File(photo.path));
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse("$serverIp/scan/upload");

      final request = http.MultipartRequest("POST", uri)
        ..fields['user_id'] = "user123"
        ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      String topic = jsonResponse["topic"] ?? "Unknown";
      List<String> variables = List<String>.from(jsonResponse["variables"] ?? []);

      final notes = await _fetchNotes(topic, variables);

      HistoryStore.add(
        ScanHistory(
          topic: topic,
          variables: variables,
          imagePath: imageFile.path,
          notesJson: notes,
          timestamp: DateTime.now(),
        ),
      );

      setState(() => loading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            topic: topic,
            variables: variables,
            notesJson: notes,
            imagePath: imageFile.path,
          ),
        ),
      );
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchNotes(
      String topic, List<String> variables) async {
    final uri = Uri.parse("$serverIp/scan/notes");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "topic": topic,
        "variables": variables,
      }),
    );

    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        _buildMainUI(theme, cs),
        if (loading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "Analyzing Image...",
                    style: TextStyle(fontSize: 18),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainUI(ThemeData theme, ColorScheme cs) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0.5,
        foregroundColor: theme.colorScheme.onSurface,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Text(
                "STEMLY",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),

              const SizedBox(height: 26),

              Text(
                "Scan → Get Mission →\nLearn Visually",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onBackground.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 40),

              _scanBox(theme, cs),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _scanBox(ThemeData theme, ColorScheme cs) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        child: AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
            onTap: _openCamera,
            child: Container(
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: cs.primary,
                    child: Icon(Icons.camera_alt,
                        color: cs.onPrimary, size: 60),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Scan to Learn",
                    style: TextStyle(
                      fontSize: 20,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
