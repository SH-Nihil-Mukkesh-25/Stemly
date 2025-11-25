import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: const Center(child: Text("History Screen")),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
