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
  static const deepBlue = Color(0xFF003A70); // DARK BLUE TEXT

  @override
  void initState() {
    super.initState();
    for (var key in widget.notesJson.keys) {
      expanded[key] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD8ECFF); // light blue
    const cardColor = Colors.white;
    const background = Color(0xFFF3F7FA);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,

        // ---------------- APP BAR ----------------
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,

          // DARK BLUE BACK BUTTON + TITLE
          iconTheme: const IconThemeData(color: deepBlue),
          title: const Text(
            "Scan Result",
            style: TextStyle(
              color: deepBlue,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),

          // ---------------- TAB BAR ----------------
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(55),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  // White → changed to dark-blue translucent
                  color: deepBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,

                  // INDICATOR → changed from white to deep blue
                  indicator: BoxDecoration(
                    color: deepBlue,
                    borderRadius: BorderRadius.circular(30),
                  ),

                  indicatorSize: TabBarIndicatorSize.tab,

                  // Selected = light blue text for contrast
                  labelColor: primaryColor,

                  // Unselected = deep blue text
                  unselectedLabelColor: deepBlue,

                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
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
          children: [
            _visualiser(),
            _notes(cardColor),
          ],
        ),
      ),
    );
  }

  // ---------------- VISUALISER TAB ----------------
  Widget _visualiser() {
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
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
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

          _title("Topic"),
          _value(widget.topic),
          const SizedBox(height: 24),

          _title("Variables"),
          _value(widget.variables.join(", ")),
        ],
      ),
    );
  }

  // ---------------- NOTES TAB ----------------
  Widget _notes(Color cardColor) {
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
            child: _buildContent(value),
            cardColor: cardColor,
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
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
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
                    style: const TextStyle(
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
  Widget _buildContent(dynamic value) {
    if (value is String) {
      return Text(
        value,
        style: const TextStyle(fontSize: 15, color: deepBlue),
      );
    }

    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "• $e",
                  style: const TextStyle(fontSize: 15, color: deepBlue),
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
                  style: const TextStyle(fontSize: 15, color: deepBlue),
                ),
              ),
            )
            .toList(),
      );
    }

    return const Text("Unsupported format");
  }

  // ---------------- TITLE & VALUE ----------------
  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: deepBlue,
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, color: deepBlue),
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
