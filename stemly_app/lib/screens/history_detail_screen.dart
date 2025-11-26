import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_history.dart';

class HistoryDetailScreen extends StatelessWidget {
  final ScanHistory history;

  const HistoryDetailScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Details")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE PREVIEW
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(history.imagePath),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            Text("Topic:",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(history.topic,
                style: const TextStyle(fontSize: 20, color: Colors.blue)),

            const SizedBox(height: 20),

            Text("Variables:",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(history.variables.join(", "),
                style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            Text("Scanned At:",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(
              "${history.timestamp.day}/${history.timestamp.month}/${history.timestamp.year} "
              "${history.timestamp.hour}:${history.timestamp.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
