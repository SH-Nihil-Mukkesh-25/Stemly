import 'package:flutter/material.dart';

class ScanResultScreen extends StatelessWidget {
  final String topic;
  final List<String> variables;

  const ScanResultScreen({
    super.key,
    required this.topic,
    required this.variables,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Scan Result"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "AI Visualiser"),
              Tab(text: "AI Notes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- AI VISUALISER ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Topic",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    topic,
                    style: const TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "Variables",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    variables.join(", "),
                    style: const TextStyle(fontSize: 18),
                  )
                ],
              ),
            ),

            // --- AI NOTES (COMING SOON) ---
            const Center(
              child: Text(
                "AI Notes coming soon…",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
