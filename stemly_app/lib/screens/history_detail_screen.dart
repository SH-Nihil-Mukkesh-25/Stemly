import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/scan_history.dart';
import '../storage/history_store.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../quiz/quiz_play_screen.dart';
import '../quiz/quiz_result_screen.dart';
import '../visualiser/visualiser_factory.dart';
import '../visualiser/visualiser_models.dart';

class HistoryDetailScreen extends StatefulWidget {
  final ScanHistory history;

  const HistoryDetailScreen({super.key, required this.history});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final Map<String, bool> expanded = {};

  VisualTemplate? visualiserTemplate;
  Widget? visualiserWidget;
  bool loading = true;

  final serverIp = "http://10.12.180.151:8080";

  @override
  void initState() {
    super.initState();

    for (var key in widget.history.notesJson.keys) {
      expanded[key] = false;
    }

    _loadVisualiser();
  }

  Future<void> _loadVisualiser() async {
    setState(() => loading = true);

    try {
      final auth = context.read<FirebaseAuthService>();
      final token = await auth.getIdToken();

      final url = Uri.parse("$serverIp/visualiser/generate");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "topic": widget.history.topic,
          "variables": widget.history.variables,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final templateJson = data["template"];

        final template = VisualTemplate.fromJson(templateJson);
        visualiserTemplate = template;

        visualiserWidget = VisualiserFactory.create(template);
      }
    } catch (e) {
      print("History visualiser error: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.history;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final deepBlue = cs.primary;
    final primaryColor = cs.primaryContainer;
    final background = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: background,
        bottomNavigationBar: BottomNavBar(currentIndex: 1),

        // ---------------- APP BAR (same as ScanResultScreen) ----------------
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: deepBlue),

          title: Text(
            "Scan Details",
            style: TextStyle(
              color: deepBlue,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),

          actions: [
            IconButton(
              icon: Icon(
                h.isStarred ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 28,
              ),
              onPressed: () {
                setState(() => h.isStarred = !h.isStarred);
              },
            )
          ],

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(55),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: deepBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: deepBlue,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: cs.onPrimary,
                  unselectedLabelColor: deepBlue,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  tabs: const [
                    Tab(text: "AI Visualiser"),
                    Tab(text: "AI Quiz"),
                    Tab(text: "AI Notes"),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ---------------- BODY ----------------
        body: TabBarView(
          children: [
            _visualiserTab(h, deepBlue),
            _quizTab(deepBlue),
            _notesTab(h, cardColor, deepBlue),
          ],
        ),
      ),
    );
  }

  // ---------------- VISUAL TAB ----------------
  Widget _visualiserTab(ScanHistory h, Color deepBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animation container
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : visualiserWidget ?? _noVisualiser(deepBlue),
            ),
          ),

          const SizedBox(height: 30),

          // The scanned image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              File(h.imagePath),
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 25),

          _title("Topic", deepBlue),
          _value(h.topic, deepBlue),
          const SizedBox(height: 18),

          _title("Variables", deepBlue),
          _value(h.variables.join(", "), deepBlue),
          const SizedBox(height: 18),

          _title("Scanned At", deepBlue),
          _value(
            "${h.timestamp.day}/${h.timestamp.month}/${h.timestamp.year}  "
            "${h.timestamp.hour}:${h.timestamp.minute.toString().padLeft(2, '0')}",
            deepBlue,
          ),
        ],
      ),
    );
  }

  Widget _noVisualiser(Color deepBlue) {
    return Center(
      child: Text(
        "No visualisation available",
        style: TextStyle(color: deepBlue, fontSize: 16),
      ),
    );
  }

  // ---------------- NOTES TAB ----------------
  Widget _notesTab(ScanHistory h, Color cardColor, Color deepBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: h.notesJson.entries.map((entry) {
          final key = entry.key;
          return _expandableCard(
            title: _formatKey(key),
            expanded: expanded[key]!,
            onTap: () => setState(() => expanded[key] = !expanded[key]!),
            child: _contentBuilder(entry.value, deepBlue),
            deepBlue: deepBlue,
            cardColor: cardColor,
          );
        }).toList(),
      ),
    );
  }

  Widget _expandableCard({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
    required Color cardColor,
    required Color deepBlue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          color: deepBlue,
                          fontWeight: FontWeight.w700)),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 28,
                    color: deepBlue,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild:
                Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _contentBuilder(dynamic value, Color deepBlue) {
    if (value is String) {
      return Text(value, style: TextStyle(color: deepBlue, fontSize: 15));
    }
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text("• $e",
                      style: TextStyle(color: deepBlue, fontSize: 15)),
                ))
            .toList(),
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text("${e.key}: ${e.value}",
                      style: TextStyle(color: deepBlue, fontSize: 15)),
                ))
            .toList(),
      );
    }
    return const Text("Unsupported format");
  }

  Widget _title(String t, Color c) => Text(
        t,
        style: TextStyle(
          fontSize: 22,
          color: c,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _value(String t, Color c) =>
      Text(t, style: TextStyle(fontSize: 17, color: c));

  String _formatKey(String raw) {
    if (raw.isEmpty) return "";
    return raw
        .replaceAll("_", " ")
        .replaceFirst(raw[0], raw[0].toUpperCase());
  }

  // ==========================================================
  // QUIZ TAB
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
                      "Test your knowledge on ${widget.history.topic}",
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

              
              // ---------------- HISTORY LIST ----------------
              if (widget.history.quizResults.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(Icons.history, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      "Previous Quizzes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...widget.history.quizResults.map((r) {
                   final score = r["score"];
                   final total = r["total"];
                   final pct = r["percentage"];
                   final date = DateTime.tryParse(r["timestamp"] ?? "") ?? DateTime.now();
                   
                   final Color color = pct >= 80 ? Colors.green : (pct >= 50 ? Colors.orange : Colors.red);
                   
                  final Map<String, dynamic> quizData = r["quizData"] != null 
                      ? Map<String, dynamic>.from(r["quizData"]) 
                      : {};
                  final Map<String, dynamic> rawAnswers = r["answers"] != null 
                      ? Map<String, dynamic>.from(r["answers"]) 
                      : {};

                   return GestureDetector(
                     onTap: () {
                        if (quizData.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Details not available for this quiz.")),
                          );
                          return;
                        }

                        // Parse answers: JSON keys are strings, Map<int,int> needs ints
                        final Map<int, int> answerMap = {};
                        rawAnswers.forEach((k, v) {
                          final key = int.tryParse(k);
                          if (key != null && v is int) {
                            answerMap[key] = v;
                          }
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizResultScreen(
                              quizData: quizData,
                              answers: answerMap,
                            ),
                          ),
                        );
                     },
                     child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                         color: Theme.of(context).cardColor,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.grey.shade200),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.04),
                             blurRadius: 8,
                             offset: const Offset(0, 2),
                           ),
                         ],
                      ),
                      child: Row(
                        children: [
                           // Score Circle
                           Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "$pct%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text("Score: $score / $total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: deepBlue)),
                                 const SizedBox(height: 4),
                                 Text(
                                   "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                 ),
                               ],
                             ),
                           ),
                           Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                   );
                }).toList(),
              ],
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
  // START QUIZ
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
            Text("Generating ${widget.history.topic} Quiz...", textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text("This may take a moment", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse("$serverIp/quiz/generate?topic=${widget.history.topic}&count=$count"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 120));

      // Close loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 429) {
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
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizPlayScreen(quizData: data)),
        );

        // If returned with results, save them
        if (result != null && result is Map && mounted) {
           setState(() {
             // Cast to Map<String, dynamic> manually to match the type
             widget.history.quizResults.insert(0, Map<String, dynamic>.from(result));
             // Save to disk
             HistoryStore.update();
           });
           
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Quiz result saved to history!")),
           );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) Navigator.of(context, rootNavigator: true).pop();
      // Only show error if we haven't navigated away or if it's a real error
      if (e.toString().contains("Timeout")) {
         _showQuizError("Connection timed out. Please try again.");
      } else {
         debugPrint("Quiz error: $e");
      }
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
}
