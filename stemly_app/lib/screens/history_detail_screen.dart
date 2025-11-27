import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_history.dart';
import '../storage/history_store.dart';
import '../widgets/bottom_nav_bar.dart'; // ← ADD THIS

class HistoryDetailScreen extends StatefulWidget {
  final ScanHistory history;

  const HistoryDetailScreen({super.key, required this.history});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final Map<String, bool> expanded = {};

  @override
  void initState() {
    super.initState();
    for (var key in widget.history.notesJson.keys) {
      expanded[key] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.history;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final deepBlue = cs.primary;
    final lightBlue = cs.secondary.withOpacity(0.2);
    final background = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,

        // ------------------------------
        // CURVED BOTTOM NAV BAR ADDED
        // ------------------------------
        bottomNavigationBar: BottomNavBar(currentIndex: 1),

        appBar: AppBar(
          backgroundColor: lightBlue,
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
                setState(() {
                  h.isStarred = !h.isStarred;
                });
              },
            ),
          ],

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
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: cs.onPrimary,
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
            _visualiser(h, deepBlue),
            _notes(h, cardColor, deepBlue),
          ],
        ),
      ),
    );
  }

  // ---------------- VISUAL TAB ----------------
  Widget _visualiser(ScanHistory h, Color deepBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(h.imagePath),
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 30),

          _title("Topic", deepBlue),
          _value(h.topic, deepBlue),
          const SizedBox(height: 20),

          _title("Variables", deepBlue),
          _value(h.variables.join(", "), deepBlue),
          const SizedBox(height: 20),

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

  // ---------------- NOTES TAB ----------------
  Widget _notes(ScanHistory h, Color cardColor, Color deepBlue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: h.notesJson.entries.map((entry) {
          final key = entry.key;

          return _expandableCard(
            title: _formatKey(key),
            expanded: expanded[key]!,
            onTap: () {
              setState(() {
                expanded[key] = !expanded[key]!;
              });
            },
            child: _buildContent(entry.value, deepBlue),
            cardColor: cardColor,
            deepBlue: deepBlue,
          );
        }).toList(),
      ),
    );
  }

  // ---------------- OTHER HELPERS (unchanged) ----------------
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
            color: Colors.black.withOpacity(0.10),
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 28,
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

  Widget _buildContent(dynamic value, Color deepBlue) {
    if (value is String) {
      return Text(value, style: TextStyle(fontSize: 15, color: deepBlue));
    }
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text("• $e",
                      style: TextStyle(fontSize: 15, color: deepBlue)),
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
                      style: TextStyle(fontSize: 15, color: deepBlue)),
                ))
            .toList(),
      );
    }

    return const Text("Unsupported format");
  }

  Widget _title(String text, Color deepBlue) =>
      Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: deepBlue));

  Widget _value(String text, Color deepBlue) =>
      Text(text, style: TextStyle(fontSize: 17, color: deepBlue));

  String _formatKey(String raw) =>
      raw.replaceAll("_", " ").trim().replaceFirst(raw[0], raw[0].toUpperCase());
}
