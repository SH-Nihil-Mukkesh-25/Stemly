import 'package:flutter/material.dart';
import '../storage/history_store.dart';
import '../screens/history_detail_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = HistoryStore.history;

    return Scaffold(
      appBar: AppBar(title: const Text("Scan History")),
      body: history.isEmpty
          ? const Center(child: Text("No scan history yet"))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final h = history[index];
                return ListTile(
                  title: Text(h.topic),
                  subtitle: Text("Variables: ${h.variables.join(', ')}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryDetailScreen(history: h),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
