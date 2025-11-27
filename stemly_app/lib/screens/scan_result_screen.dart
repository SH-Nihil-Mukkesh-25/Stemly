import 'dart:io';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    for (var key in widget.notesJson.keys) {
      expanded[key] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Dynamic theme values
    final deepBlue = cs.primary;
    final primaryColor = cs.primaryContainer;
    final cardColor = theme.cardColor;
    final background = theme.scaffoldBackgroundColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,

        // ---------------- APP BAR ----------------
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: deepBlue),

          title: Text(
            "Scan Result",
            style: TextStyle(
              color: deepBlue,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(55),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: deepBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,

                  indicator: BoxDecoration(
                    color: deepBlue,
                    borderRadius: BorderRadius.circular(30),
                  ),

                  labelColor: cs.onPrimaryContainer,
                  unselectedLabelColor: deepBlue,

                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),

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
          children: [
            _visualiser(deepBlue),
            _notes(cardColor, deepBlue),
          ],
        ),
      ),
    );
  }

  // ---------------- VISUALISER TAB ----------------
  Widget _visualiser(Color deepBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE CARD
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 28),

          _title("Topic", deepBlue),
          _value(widget.topic, deepBlue),
          const SizedBox(height: 24),

          _title("Variables", deepBlue),
          _value(widget.variables.join(", "), deepBlue),
        ],
      ),
    );
  }

  // ---------------- NOTES TAB ----------------
  Widget _notes(Color cardColor, Color deepBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.notesJson.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          return _expandableCard(
            title: _formatKey(key),
            expanded: expanded[key]!,
            onTap: () {
              setState(() {
                expanded[key] = !expanded[key]!;
              });
            },
            child: _buildContent(value, deepBlue),
            cardColor: cardColor,
            deepBlue: deepBlue,
          );
        }).toList(),
      ),
    );
  }

  // ---------------- EXPANDABLE CARD ----------------
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
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
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: deepBlue,
                      fontWeight: FontWeight.w700,
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
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CONTENT BUILDER ----------------
  Widget _buildContent(dynamic value, Color deepBlue) {
    if (value is String) {
      return Text(
        value,
        style: TextStyle(fontSize: 15, color: deepBlue),
      );
    }

    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var e in value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text("• $e",
                  style: TextStyle(fontSize: 15, color: deepBlue)),
            ),
        ],
      );
    }

    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var e in value.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text("${e.key}: ${e.value}",
                  style: TextStyle(fontSize: 15, color: deepBlue)),
            ),
        ],
      );
    }

    return const Text("Unsupported format");
  }

  // ---------------- TITLE / VALUE ----------------
  Widget _title(String text, Color deepBlue) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: deepBlue,
      ),
    );
  }

  Widget _value(String text, Color deepBlue) {
    return Text(
      text,
      style: TextStyle(fontSize: 17, color: deepBlue),
    );
  }

  // ---------------- FORMAT CLEAN KEY ----------------
  String _formatKey(String raw) {
    return raw
        .replaceAll("_", " ")
        .trim()
        .replaceFirst(raw[0], raw[0].toUpperCase());
  }
}
