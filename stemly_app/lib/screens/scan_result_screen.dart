import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';

// NEW: Import Quiz Screen
import '../quiz/quiz_play_screen.dart';

// Existing imports
import '../visualiser/visualiser_models.dart';
import '../visualiser/visualiser_factory.dart';

class ScanResultScreen extends StatefulWidget {
  final String topic;
  final List<String> variables;
  final Map<String, dynamic> notesJson;
  final String imagePath;

  const ScanResultScreen({
    super.key,
    required this.topic,
    required this.variables,
    required this.notesJson,
    required this.imagePath,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final Map<String, bool> expanded = {};

  VisualTemplate? visualiserTemplate;
  Widget? visualiserWidget;
  bool loadingVisualiser = true;

  // AI Chat state
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isSendingChat = false;
  final ScrollController _chatScrollController = ScrollController();

  final String serverIp = "http://10.12.180.151:8080";


  @override
  void initState() {
    super.initState();

    debugPrint("SCAN RESULT START");
    debugPrint("Topic: ${widget.topic}");
    debugPrint("Variables: ${widget.variables}");
    debugPrint("Notes Keys: ${widget.notesJson.keys}");

    for (var key in widget.notesJson.keys) {
      expanded[key] = false;
    }

    _loadVisualiser();
  }

  // ==========================================================
  // VISUALISER LOADER
  // ==========================================================
  Future<void> _loadVisualiser() async {
    setState(() => loadingVisualiser = true);

    try {
      final auth = context.read<FirebaseAuthService>();
      final token = await auth.getIdToken();

      if (token == null) {
        debugPrint("❌ No Firebase token");
        if (mounted) setState(() => loadingVisualiser = false);
        return;
      }

      final response = await http.post(
        Uri.parse("$serverIp/visualiser/generate"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "topic": widget.topic,
          "variables": widget.variables,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Visualiser API Error: ${response.statusCode}");
        if (mounted) setState(() => loadingVisualiser = false);
        return;
      }

      final data = jsonDecode(response.body);
      final template = VisualTemplate.fromJson(data["template"]);

      if (mounted) {
        setState(() {
          visualiserTemplate = template;
          visualiserWidget = _createVisualiser(template);
          loadingVisualiser = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Visualiser error: $e");
      if (mounted) setState(() => loadingVisualiser = false);
    }
  }

  // ==========================================================
  // CREATE VISUALISER WIDGET
  // ==========================================================

  Widget _createVisualiser(VisualTemplate template) {
    return VisualiserFactory.create(template);
  }

  // ==========================================================
  // VISUALISER TAB UI
  // ==========================================================
  // NEW STATE FOR IMAGE GEN
  String? generatedImageUrl;
  bool generatingImage = false;

  Future<void> _generateImage() async {
    setState(() => generatingImage = true);
    try {
      final auth = context.read<FirebaseAuthService>();
      final token = await auth.getIdToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse("$serverIp/visualiser/generate-image"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"prompt": "${widget.topic} ${widget.variables.join(' ')}"}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => generatedImageUrl = data["image_url"]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate image")),
        );
      }
    } catch (e) {
      debugPrint("Image gen error: $e");
    } finally {
      if (mounted) setState(() => generatingImage = false);
    }
  }

  // ==========================================================
  // AI CHAT FUNCTION
  // ==========================================================
  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    setState(() {
      _chatMessages.add({"text": message, "isUser": true});
      _chatController.clear();
      _isSendingChat = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final auth = context.read<FirebaseAuthService>();
      final token = await auth.getIdToken();

      if (token == null) {
        setState(() {
          _chatMessages.add({"text": "Authentication required.", "isUser": false});
          _isSendingChat = false;
        });
        return;
      }

      // Prepare parameters for API
      Map<String, dynamic> params = {};
      if (visualiserTemplate != null) {
        for (var entry in visualiserTemplate!.parameters.entries) {
          params[entry.key] = entry.value.value;
        }
      }

      final response = await http.post(
        Uri.parse("$serverIp/visualiser/chat"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "message": message,
          "topic": widget.topic,
          "parameters": params,
          "history": _chatMessages.map((m) => {"text": m["text"], "isUser": m["isUser"]}).toList(),
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data["type"] == "update" && data["changes"] != null) {
          // AI wants to update visualization
          final changes = data["changes"] as Map<String, dynamic>;
          String updateMsg = "Updated: ";
          bool needsRebuild = false;

          changes.forEach((key, value) {
            // Check for Metadata updates (Equation / Primitives)
            if (key == "equation" || key == "primitives") {
              if (visualiserTemplate != null) {
                visualiserTemplate!.metadata[key] = value;
                updateMsg += "$key updated, ";
                needsRebuild = true;
              }
            }
            // Check for Parameter updates
            else if (visualiserTemplate != null && visualiserTemplate!.parameters.containsKey(key)) {
              final param = visualiserTemplate!.parameters[key]!;
              
              // Safe parse value
              double newValue = 0.0;
              if (value is num) newValue = value.toDouble();
              else if (value is String) newValue = double.tryParse(value) ?? 0.0;

              // Clamp to constraints
              newValue = newValue.clamp(param.min, param.max);
              
              // Apply update
              param.value = newValue;
              updateMsg += "$key = ${newValue.toStringAsFixed(1)}, ";
              needsRebuild = true;
            }
          });

          if (needsRebuild) {
             visualiserWidget = _createVisualiser(visualiserTemplate!);
          }

          setState(() {
            _chatMessages.add({"text": updateMsg.trimRight().replaceAll(RegExp(r', $'), ''), "isUser": false});
          });
        } else {
          // AI explanation
          setState(() {
            _chatMessages.add({"text": data["message"] ?? "No response.", "isUser": false});
          });
        }
      } else {
        setState(() {
          _chatMessages.add({"text": "Error: ${response.statusCode}", "isUser": false});
        });
      }
    } catch (e) {
      setState(() {
        _chatMessages.add({"text": "Connection error. Try again.", "isUser": false});
      });
    } finally {
      if (mounted) setState(() => _isSendingChat = false);
      
      // Scroll to bottom after response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _visualiser(Color deepBlue) {
    if (loadingVisualiser) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: deepBlue),
            const SizedBox(height: 12),
            Text("Loading interactive model...", style: TextStyle(color: deepBlue)),
          ],
        ),
      );
    }

    // IF INTERACTIVE WIDGET EXISTS, SHOW IT
    if (visualiserWidget != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: deepBlue.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: visualiserWidget,
            ),
            const SizedBox(height: 18),
            if (visualiserTemplate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, size: 18, color: deepBlue),
                        const SizedBox(width: 8),
                        Text("Parameters", style: TextStyle(fontWeight: FontWeight.bold, color: deepBlue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...visualiserTemplate!.parameters.entries.map((e) {
                      final v = e.value.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: TextStyle(color: deepBlue)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: deepBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(v.toString(), style: TextStyle(color: deepBlue, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            // AI CHAT SECTION (Collapsible & Solid Blue)
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shadowColor: deepBlue.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                initiallyExpanded: false,
                collapsedBackgroundColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                shape: const Border(), // Remove default borders
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: deepBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.smart_toy, color: deepBlue, size: 20),
                ),
                title: Text(
                  "AI Assistant",
                  style: TextStyle(
                    color: deepBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "Ask questions or control visuals",
                  style: TextStyle(color: deepBlue.withOpacity(0.6), fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Messages
                        Expanded(
                          child: _chatMessages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 32, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Ask me anything!",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: _chatScrollController,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _chatMessages.length,
                                  itemBuilder: (context, index) {
                                    final msg = _chatMessages[index];
                                    final isUser = msg["isUser"] == true;
                                    return Align(
                                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                        decoration: BoxDecoration(
                                          color: isUser ? deepBlue : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: isUser 
                                              ? [] 
                                              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                                          border: isUser ? null : Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Text(
                                          msg["text"] ?? "",
                                          style: TextStyle(
                                            color: isUser ? Colors.white : Colors.black87,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        
                        // Input
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: Colors.grey.shade200)),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _chatController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: "Type a message...",
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onSubmitted: (_) => _sendChatMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _isSendingChat ? null : _sendChatMessage,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: deepBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isSendingChat
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.send, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // IF NO INTERACTIVE WIDGET -> SHOW IMAGE GEN OPTION
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (generatedImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  generatedImageUrl!, 
                  height: 300, 
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: deepBlue)));
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (!generatingImage && generatedImageUrl == null) ...[
               Icon(Icons.image_search_rounded, size: 60, color: deepBlue.withOpacity(0.5)),
               const SizedBox(height: 16),
               Text(
                "No interactive simulation available.",
                style: TextStyle(fontSize: 16, color: deepBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            if (generatingImage)
               Column(children: [
                 CircularProgressIndicator(color: deepBlue),
                 const SizedBox(height: 10),
                 Text("Generating AI Diagram...", style: TextStyle(color: deepBlue))
               ])
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateImage,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(generatedImageUrl == null ? "Generate AI Diagram" : "Regenerate Diagram"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // NOTES TAB
  // ==========================================================
  Widget _notes(Color cardColor, Color deepBlue) {
    if (widget.notesJson.containsKey("error")) {
      return Center(
        child: Text("Error loading notes", style: TextStyle(color: deepBlue)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.notesJson.entries.map((entry) {
          final key = entry.key;
          expanded.putIfAbsent(key, () => false);

          return _expandableCard(
            title: _formatKey(key),
            expanded: expanded[key]!,
            onTap: () => setState(() => expanded[key] = !expanded[key]!),
            child: _buildContent(entry.value, deepBlue),
            cardColor: Theme.of(context).cardColor,
            deepBlue: deepBlue,
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // QUIZ TAB  (REDESIGNED)
  // ==========================================================
  Widget _quizTab(Color deepBlue) {
    double count = 5;

    return StatefulBuilder(
      builder: (context, setStateSB) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: deepBlue,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: deepBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.quiz_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      "AI Quiz Generator",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Test your knowledge on ${widget.topic}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Settings Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: deepBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.tune, color: deepBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          "Quiz Settings",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Question count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Number of Questions",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: deepBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${count.toInt()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: deepBlue,
                        inactiveTrackColor: deepBlue.withOpacity(0.2),
                        thumbColor: deepBlue,
                        overlayColor: deepBlue.withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      ),
                      child: Slider(
                        min: 3,
                        max: 15,
                        divisions: 12,
                        value: count,
                        onChanged: (v) => setStateSB(() => count = v),
                      ),
                    ),
                    
                    // Difficulty indicators
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _difficultyChip("Easy", Colors.green, true),
                        _difficultyChip("Medium", Colors.orange, true),
                        _difficultyChip("Hard", Colors.red, true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _startQuiz(count.toInt()),
                  icon: const Icon(Icons.auto_awesome, size: 22),
                  label: const Text(
                    "Generate AI Quiz",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: deepBlue.withOpacity(0.4),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    "Questions are generated by AI based on your topic",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _difficultyChip(String label, Color color, bool isIncluded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isIncluded ? color.withOpacity(0.15) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isIncluded ? color : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isIncluded) Icon(Icons.check, size: 14, color: color),
          if (isIncluded) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isIncluded ? color : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // START QUIZ (API CALL with retry and error handling)
  // ==========================================================
  Future<void> _startQuiz(int count) async {
    final auth = context.read<FirebaseAuthService>();
    final token = await auth.getIdToken();

    if (token == null) {
      _showQuizError("Authentication required. Please sign in again.");
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text("Generating ${widget.topic} Quiz...", textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text("This may take a moment", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse("$serverIp/quiz/generate?topic=${widget.topic}&count=$count"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 120));

      // Close loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 429) {
        // Rate limited - show friendly message
        _showQuizError("AI is busy. Please wait a moment and try again.");
        return;
      }

      if (response.statusCode != 200) {
        _showQuizError("Failed to generate quiz. Error: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);

      // Check for error in response
      if (data is Map && data.containsKey("error") && (data["questions"] == null || (data["questions"] as List).isEmpty)) {
        _showQuizError(data["error"]?.toString() ?? "Quiz generation failed");
        return;
      }

      // Navigate to quiz screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizPlayScreen(quizData: data)),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showQuizError("Connection error: ${e.toString().split(':').first}");
    }
  }

  void _showQuizError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Quiz Error"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // UI HELPERS
  // ==========================================================

  Widget _expandableCard({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
    required Color cardColor,
    required Color deepBlue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: deepBlue,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 30,
                    color: deepBlue,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(14),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic value, Color deepBlue) {
    if (value is String) {
      return Text(value, style: TextStyle(fontSize: 15, color: deepBlue));
    }

    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value
            .map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "• $v",
                  style: TextStyle(fontSize: 15, color: deepBlue),
                ),
              ),
            )
            .toList(),
      );
    }

    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries
            .map(
              (e) => Text(
                "${e.key}: ${e.value}",
                style: TextStyle(fontSize: 15, color: deepBlue),
              ),
            )
            .toList(),
      );
    }

    return Text(
      value.toString(),
      style: TextStyle(fontSize: 15, color: deepBlue),
    );
  }

  String _formatKey(String raw) {
    if (raw.isEmpty) return "";
    return raw
        .replaceAll("_", " ")
        .trim()
        .replaceFirst(raw[0], raw[0].toUpperCase());
  }

  // ==========================================================
  // ROOT BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final deepBlue = cs.primary;
    final primaryColor = cs.primaryContainer;
    final cardColor = theme.cardColor;
    final background = theme.scaffoldBackgroundColor;

    return DefaultTabController(
      length: 3, // UPDATED (added AI Quiz)
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          iconTheme: IconThemeData(color: deepBlue),
          title: Text(
            "Scan Result",
            style: TextStyle(
              color: deepBlue,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: deepBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: deepBlue.withOpacity(0.7),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [deepBlue, deepBlue.withOpacity(0.85)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: deepBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  tabs: const [
                    Tab(text: "AI Visualiser"),
                    Tab(text: "AI Notes"),
                    Tab(text: "AI Quiz"), // NEW TAB
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _visualiser(deepBlue),
            _notes(cardColor, deepBlue),
            _quizTab(deepBlue), // NEW TAB SCREEN
          ],
        ),
      ),
    );
  }
}
