import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_history.dart';
import '../storage/history_store.dart';

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

    const primaryColor = Color(0xFF0A3D62);
    const cardColor = Colors.white;
    const background = Color(0xFFF3F7FA);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 2,
          title: const Text(
            "Scan Details",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(
                h.isStarred ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() {
                  h.isStarred = !h.isStarred;
                });
              },
            )
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "AI Visualiser"),
              Tab(text: "AI Notes"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _visualiser(h, primaryColor),
            _notes(h, primaryColor, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _visualiser(ScanHistory h, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(h.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text("Topic",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
          Text(h.topic, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 20),

          Text("Variables",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
          Text(h.variables.join(", "), style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 20),

          Text("Scanned At",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
          Text(
            "${h.timestamp.day}/${h.timestamp.month}/${h.timestamp.year}  "
            "${h.timestamp.hour}:${h.timestamp.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 17),
          ),
        ],
      ),
    );
  }

  Widget _notes(ScanHistory h, Color primaryColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: h.notesJson.entries.map((entry) {
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
            primaryColor: primaryColor,
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
    required Color primaryColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 18,
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      )),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 28,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic value) {
    if (value is String) {
      return Text(value, style: const TextStyle(fontSize: 15));
    }
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("• $e", style: const TextStyle(fontSize: 15)),
                ))
            .toList(),
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("${e.key}: ${e.value}",
                      style: const TextStyle(fontSize: 15)),
                ))
            .toList(),
      );
    }
    return const Text("Unsupported format");
  }

  String _formatKey(String raw) {
    return raw
        .replaceAll("_", " ")
        .trim()
        .replaceFirst(raw[0], raw[0].toUpperCase());
  }
}
