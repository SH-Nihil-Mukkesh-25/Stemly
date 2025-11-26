import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../widgets/bottom_nav_bar.dart';
import '../storage/history_store.dart';
import '../models/scan_history.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ImagePicker _picker = ImagePicker();
  bool loading = false;

  String? topic;
  List<String>? variables;
  String? errorMessage;

  final String serverIp = "http://10.0.2.2:8000";

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;
      await _uploadImage(File(photo.path));
    } catch (e) {
      print("Camera error: $e");
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      loading = true;
      topic = null;
      variables = null;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse("$serverIp/scan/upload");

      final request = http.MultipartRequest("POST", uri)
        ..fields['user_id'] = "user123"
        ..files.add(await http.MultipartFile.fromPath(
          "file",
          imageFile.path,
          filename: imageFile.path.split("/").last,
        ));

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      setState(() {
        loading = false;
        topic = jsonResponse["topic"]?.toString() ?? "Unknown";
        variables = List<String>.from(jsonResponse["variables"] ?? []);
      });

      HistoryStore.add(
        ScanHistory(
          topic: topic!,
          variables: variables!,
          imagePath: imageFile.path,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Result")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : errorMessage != null
                ? Text(errorMessage!, style: const TextStyle(color: Colors.red))
                : topic != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Topic:",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(topic!,
                              style:
                                  const TextStyle(fontSize: 20, color: Colors.blue)),
                          const SizedBox(height: 20),
                          const Text("Variables:",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            variables!.join(", "),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      )
                    : const Text("Tap the camera button to scan"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        child: const Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
