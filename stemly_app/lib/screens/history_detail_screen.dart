import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/scan_history.dart';
import '../widgets/bottom_nav_bar.dart';

import '../visualiser/projectile_motion.dart';
import '../visualiser/free_fall_component.dart';
import '../visualiser/shm_component.dart';
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

  final serverIp = "http://10.0.2.2:8000";

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
      final url = Uri.parse("$serverIp/visualiser/generate");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
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

        final id = template.templateId.toLowerCase();
        final p = template.parameters;

        if (id.contains("projectile")) {
          visualiserWidget = ProjectileMotionWidget(
            U: p["U"]!.value,
            theta: p["theta"]!.value,
            g: p["g"]!.value,
          );
        } else if (id.contains("fall") || id.contains("free")) {
          visualiserWidget = FreeFallWidget(
            h: p["h"]!.value,
            g: p["g"]!.value,
          );
        } else if (id.contains("shm")) {
          visualiserWidget = SHMWidget(
            A: p["A"]!.value,
            m: p["m"]!.value,
            k: p["k"]!.value,
          );
        }
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
      length: 2,
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
}
