// lib/screens/main_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
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
  final String serverIp = "http://10.0.2.2:8000";

  // ---------------------------------------------------------
  // CAMERA PICK
  // ---------------------------------------------------------
  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;

      _showLoading();
      await _uploadImage(File(photo.path));
    } catch (e) {
      _hideLoading();
      debugPrint("Camera error: $e");
    }
  }

  // ---------------------------------------------------------
  // UPLOAD IMAGE
  // ---------------------------------------------------------
  Future<void> _uploadImage(File imageFile) async {
    try {
      final authService =
          Provider.of<FirebaseAuthService>(context, listen: false);

      final token = await authService.getIdToken();
      if (token == null) {
        _hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to scan.")),
        );
        return;
      }

      final uri = Uri.parse("$serverIp/scan/upload");
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = "Bearer $token";

      final mimeType = imageFile.path.toLowerCase().endsWith(".png")
          ? MediaType("image", "png")
          : MediaType("image", "jpeg");

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          imageFile.path,
          contentType: mimeType,
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        _hideLoading();
        throw Exception("Upload failed: ${streamedResponse.statusCode}");
      }

      final jsonResponse = jsonDecode(responseBody);
      final String topic = jsonResponse["topic"] ?? "Unknown";
      final List<String> variables =
          List<String>.from(jsonResponse["variables"] ?? []);
      final String? serverImagePath = jsonResponse["image_path"];

      // Fetch AI notes
      final notes =
          await _fetchNotes(topic, variables, serverImagePath, token);

      // Save scan history locally
      HistoryStore.add(
        ScanHistory(
          topic: topic,
          variables: variables,
          imagePath: imageFile.path,
          notesJson: notes,
          timestamp: DateTime.now(),
        ),
      );

      _hideLoading();

      // Navigate
      if (!mounted) return;
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
      _hideLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    }
  }

  // ---------------------------------------------------------
  // FETCH NOTES
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> _fetchNotes(
    String topic,
    List<String> variables,
    String? imagePath,
    String token,
  ) async {
    try {
      print("📡 Fetching notes for topic: $topic, variables: $variables");
      final url = Uri.parse("$serverIp/notes/generate");

      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "topic": topic,
          "variables": variables,
          "image_path": imagePath,
        }),
      );

      print("📡 Notes response status: ${res.statusCode}");
      print("📡 Notes response body: ${res.body}");

      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        print("📡 Parsed response keys: ${parsed.keys.toList()}");
        print("📡 Notes field exists: ${parsed.containsKey('notes')}");
        return parsed["notes"] ?? {};
      }

      print("❌ Notes request failed with status ${res.statusCode}");
      return {"error": "Notes request failed: ${res.statusCode}"};
    } catch (e) {
      print("❌ Notes fetch error: $e");
      return {"error": "Connection error: $e"};
    }
  }

  // ---------------------------------------------------------
  // LOADING DIALOG
  // ---------------------------------------------------------
  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(25),
          child: const CircularProgressIndicator(strokeWidth: 4),
        ),
      ),
    );
  }

  void _hideLoading() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.cardColor,
        foregroundColor: cs.onSurface,
        elevation: 0.4,
        title: Text(
          "STEMLY",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: cs.primary,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 24),

              Text(
                "Scan → Visualize → Learn",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: cs.onBackground.withOpacity(0.7),
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 40),
              Hero(tag: "scanBtn", child: _scanBox(theme, cs)),
              const SizedBox(height: 40),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: cs.primary,
                    child: Icon(
                      Icons.camera_alt,
                      color: cs.onPrimary,
                      size: 62,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Scan to Learn",
                    style: TextStyle(
                      fontSize: 20,
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
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
