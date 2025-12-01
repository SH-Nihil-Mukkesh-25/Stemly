// lib/screens/main_screen.dart

import 'dart:async';
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
  bool _isProcessing = false;
  bool _isLoadingDialogShown = false;

  // ---------------------------------------------------------
  // CAMERA PICK
  // ---------------------------------------------------------
  Future<void> _openCamera() async {
    if (_isProcessing || !mounted) return; // Prevent multiple taps
    
    try {
      setState(() => _isProcessing = true);
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo == null || !mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      if (mounted) {
        _showLoading();
        await _uploadImage(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        _hideLoading();
        setState(() => _isProcessing = false);
        debugPrint("Camera error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera error: $e")),
        );
      }
    }
  }

  // ---------------------------------------------------------
  // UPLOAD IMAGE
  // ---------------------------------------------------------
  Future<void> _uploadImage(File imageFile) async {
    if (!mounted) return;
    
    try {
      final authService =
          Provider.of<FirebaseAuthService>(context, listen: false);

      final token = await authService.getIdToken();
      if (token == null) {
        if (mounted) {
          _hideLoading();
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please log in to scan.")),
          );
        }
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

      // Add timeout to prevent infinite loading
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 60), onTimeout: () {
        throw TimeoutException("Upload timeout after 60 seconds");
      });
      
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        if (mounted) {
          _hideLoading();
          setState(() => _isProcessing = false);
        }
        throw Exception("Upload failed: ${streamedResponse.statusCode} - $responseBody");
      }

      final jsonResponse = jsonDecode(responseBody);
      final String topic = jsonResponse["topic"] ?? "Unknown";
      final List<String> variables =
          List<String>.from(jsonResponse["variables"] ?? []);
      final String? serverImagePath = jsonResponse["image_path"];

      // Fetch AI notes with timeout (non-blocking)
      Map<String, dynamic> notes = {};
      try {
        notes = await _fetchNotes(topic, variables, serverImagePath, token)
            .timeout(const Duration(seconds: 30));
      } catch (e) {
        debugPrint("Notes fetch timeout/error: $e");
        notes = {"error": "Notes generation timed out or failed"};
      }

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

      if (mounted) {
        _hideLoading();
        setState(() => _isProcessing = false);

        // Navigate even if notes failed
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
      }
    } catch (e) {
      if (mounted) {
        _hideLoading();
        setState(() => _isProcessing = false);
        debugPrint("Upload error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString().replaceAll('TimeoutException: ', '')}"),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
    if (_isLoadingDialogShown || !mounted) return;
    _isLoadingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 120,
            height: 120,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Padding(
                padding: EdgeInsets.all(25),
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoading() {
    if (!_isLoadingDialogShown || !mounted) return;
    _isLoadingDialogShown = false;
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
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
          child: AbsorbPointer(
            absorbing: _isProcessing,
            child: InkWell(
              onTap: _isProcessing ? null : _openCamera,
              borderRadius: BorderRadius.circular(22),
              child: Container(
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
                      child: _isProcessing
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              color: cs.onPrimary,
                              size: 62,
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isProcessing ? "Processing..." : "Scan to Learn",
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
      ),
    );
  }
}
