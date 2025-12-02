import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
import '../visualiser/kinematics_component.dart';
import '../visualiser/optics_component.dart';
import '../visualiser/projectile_motion.dart';
import '../visualiser/free_fall_component.dart';
import '../visualiser/shm_component.dart';
import '../visualiser/visualiser_models.dart';

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

  final String serverIp = "http://10.0.2.2:8000";

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
  Widget? _createVisualiser(VisualTemplate template) {
    double getVal(String key) {
      final raw = template.parameters[key]?.value;

      if (raw == null) return 0.0;

      if (raw is num) return raw.toDouble();

    }

    final id = (template.templateId ?? '')
        .toLowerCase()
        .replaceAll("_", "")
        .replaceAll("-", "");

    if (id.contains("projectile")) {
      return ProjectileMotionWidget(
        U: getVal("U"),
        theta: getVal("theta"),
        g: getVal("g"),
      );
    }

    if (id.contains("freefall") || id.contains("fall")) {
      return FreeFallWidget(h: getVal("h"), g: getVal("g"));
    }

    if (id.contains("shm") || id.contains("harmonic")) {
      return SHMWidget(A: getVal("A"), m: getVal("m"), k: getVal("k"));
    }

    if (id.contains("kinematics")) {
      return KinematicsWidget(
        u: getVal("u"),
        a: getVal("a"),
        tMax: getVal("t_max"),
      );
    }

    if (id.contains("optics") || id.contains("lens")) {
      return OpticsWidget(f: getVal("f"), u: getVal("u"), h_o: getVal("h_o"));
    }

    return const Center(
      child: Text(
        "No visualisation available for this topic",
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  // ==========================================================
  // VISUALISER TAB UI
  // ==========================================================
  Widget _visualiser(Color deepBlue) {
    if (loadingVisualiser) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: deepBlue),
            const SizedBox(height: 12),
            Text("Loading visualiser...", style: TextStyle(color: deepBlue)),
          ],
        ),
      );
    }

    if (visualiserWidget == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: deepBlue),
            const SizedBox(height: 12),
            Text("No visualiser available", style: TextStyle(color: deepBlue)),
          ],
        ),
      );
    }

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
                children: visualiserTemplate!.parameters.entries.map((e) {
                  final v = e.value.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: TextStyle(color: deepBlue)),
                        Text(v.toString(), style: TextStyle(color: deepBlue)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // NOTES TAB
  // ==========================================================
  Widget _notes(Color cardColor, Color deepBlue) {
    debugPrint("📝 Building notes UI");
    debugPrint("📝 Notes JSON keys: ${widget.notesJson.keys.toList()}");
    debugPrint("📝 Notes JSON: ${widget.notesJson}");

    if (widget.notesJson.containsKey("error")) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: deepBlue.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "Failed to load notes",
                style: TextStyle(
                  color: deepBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.notesJson["error"].toString(),
                style: TextStyle(
                  color: deepBlue.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.notesJson.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_outlined,
                size: 64,
                color: deepBlue.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "No notes available",
                style: TextStyle(
                  color: deepBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Notes generation may have failed",
                style: TextStyle(
                  color: deepBlue.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
  // UI Helpers
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
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "${e.key}: ${e.value}",
                  style: TextStyle(fontSize: 15, color: deepBlue),
                ),
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
      length: 2,
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
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: "AI Visualiser"),
                    Tab(text: "AI Notes"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [_visualiser(deepBlue), _notes(cardColor, deepBlue)],
        ),
      ),
    );
  }
}
