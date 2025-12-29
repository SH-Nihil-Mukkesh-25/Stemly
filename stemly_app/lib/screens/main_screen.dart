import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../services/firebase_auth_service.dart';
import '../services/groq_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../storage/history_store.dart';
import '../models/scan_history.dart';
import 'scan_result_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key); 

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ImagePicker _picker = ImagePicker();
  // CONFIGURATION
  // Set to true for production (APK/Web deployment), false for local dev
  static const bool _isProduction = false; 

  // PRODUCTION URL (Update this after Vercel deployment)
  static const String _prodUrl = "https://your-stemly-backend.vercel.app";
  // DEV URL
  static const String _devUrl = "http://10.12.180.151:8080";

  final String serverIp = _isProduction ? _prodUrl : _devUrl; 
  
  // OCR Recognizer
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessing = false;
  bool _isLoadingDialogShown = false;
  
  String _detectedTopic = "Unknown";
  List<String> _detectedVariables = [];

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  // ==========================================================
  // CAMERA PICK -> OCR -> UPLOAD
  // ==========================================================
  Future<void> _openCamera() async {
    if (_isProcessing || !mounted) return;
    
    try {
      setState(() => _isProcessing = true);
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      
      if (photo == null || !mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      if (mounted) {
        _showLoading();
        // 1. Perform OCR extraction
        final extractedText = await _performOCR(photo.path);
        
        // Check if OCR failed or returned very little text
        // Check if OCR failed or returned very little text
        // WE ALLOW THIS NOW (Vision Fallback)
        if (extractedText.trim().length < 5) {
             debugPrint("OCR text empty/short. Proceeding with Vision AI.");
        }
        
        // 2. Upload Image + Text
        await _uploadScan(File(photo.path), extractedText);
      }
    } catch (e) {
      if (mounted) {
        _hideLoading();
        setState(() => _isProcessing = false);
        debugPrint("Camera error: $e");
        _showError("Camera error: $e");
      }
    }
  }

  // Show warning when OCR finds no text
  Future<bool> _showOcrWarning() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("No Text Detected"),
          ],
        ),
        content: const Text(
          "The image doesn't seem to contain readable text. "
          "For best results, scan an image with clear text like equations, diagrams with labels, or textbook pages.\n\n"
          "Do you want to continue anyway?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Try Again"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Continue"),
          ),
        ],
      ),
    ) ?? false;
  }

  // ==========================================================
  // LOCAL OCR (ML KIT)
  // ==========================================================
  Future<String> _performOCR(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint("OCR Failed: $e");
      return ""; // Fallback to empty text
    }
  }

  // ==========================================================
  // UPLOAD (IMAGE + TEXT)
  // ==========================================================
  Future<void> _uploadScan(File image, String ocrText) async {
    if (!mounted) return;

    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    // Note: We keep groqService for now if needed for other things, but architecture is changing.
    // final groqService = Provider.of<GroqService>(context, listen: false);

    final token = await authService.currentUser?.getIdToken();

    if (token == null) {
      _hideLoading();
      _showError("Authentication error. Please login again.");
      setState(() => _isProcessing = false);
      return;
    }

    // Prepare Request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$serverIp/scan/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Add Image
    final mimeType = image.path.toLowerCase().endsWith(".png")
          ? MediaType("image", "png")
          : MediaType("image", "jpeg");

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: mimeType,
      ),
    );

    // Add OCR Text
    request.fields['ocr_text'] = ocrText;

    debugPrint("📤 Uploading scan with text length: ${ocrText.length}");
    
    try {
      var response = await request.send()
          .timeout(const Duration(seconds: 180), onTimeout: () {
        throw TimeoutException("Upload timeout after 180 seconds");
      });
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        var topic = data['topic'] ?? "Unknown";
        List<dynamic> rawVars = data['variables'] ?? [];
        List<String> variables = rawVars.map((e) => e.toString()).toList();
        
        if (mounted) {
          setState(() {
            _detectedTopic = topic;
            _detectedVariables = variables;
          });
        }
        
        // Auto-fetch notes
        // Save Image Permanently
        String savedPath = image.path;
        try {
           final appDir = await getApplicationDocumentsDirectory();
           final scansDir = Directory('${appDir.path}/scans');
           if (!await scansDir.exists()) await scansDir.create(recursive: true);
           final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}${image.path.endsWith('.png') ? '.png' : '.jpg'}';
           final localPath = '${scansDir.path}/$fileName';
           await File(image.path).copy(localPath);
           savedPath = localPath;
        } catch (e) {
           debugPrint("⚠️ Failed to save local image: $e");
        }

        // Auto-fetch notes
        // We pass 'savedPath' (LOCAL PERMANENT) so the UI can display it
        await _fetchNotes(topic, variables, savedPath, token, ocrText);

      } else {
        if (mounted) {
          _hideLoading();
          setState(() => _isProcessing = false);
          _showError("Upload Failed: ${response.statusCode}");
        }
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) {
        _hideLoading();
        setState(() => _isProcessing = false);
        _showError("Connection Error: ${e.toString().split(':')[0]}");
      }
    }
  }

  // ==========================================================
  // FETCH NOTES -> NAVIGATE
  // ==========================================================
  Future<void> _fetchNotes(
    String topic,
    List<String> variables,
    String? imagePath,
    String token,
    String ocrText,
  ) async {
    try {
      final url = Uri.parse("$serverIp/notes/generate");
      
      // We pass OCR text here too if needed, but for now stick to protocol
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
          "ocr_text": ocrText, // Sending this if backend needs it for notes
        }),
      ).timeout(const Duration(seconds: 180));

      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        final notesData = parsed["notes"] ?? {};

        // Save History with LOCAL image path for display
        HistoryStore.add(ScanHistory(
          imagePath: imagePath ?? "", // This should be the local path
          topic: topic,
          variables: variables,
          notesJson: notesData,
          timestamp: DateTime.now(),
        ));

        if (mounted) {
          _hideLoading();
          setState(() => _isProcessing = false);
          
          Navigator.push(
           context,
           MaterialPageRoute(
             builder: (_) => ScanResultScreen(
               topic: topic,
               variables: variables,
               notesJson: notesData,
               imagePath: imagePath ?? "",
             ),
           ),
         );
        }
      } else {
        if (mounted) { 
           _hideLoading();
           setState(() => _isProcessing = false);
           _showError("Failed to fetch notes: ${res.statusCode}");
        }
      }
    } catch (e) {
      if (mounted) {
        _hideLoading();
        setState(() => _isProcessing = false);
        _showError("Connection error fetching notes");
      }
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ==========================================================
  // UI
  // ==========================================================
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
