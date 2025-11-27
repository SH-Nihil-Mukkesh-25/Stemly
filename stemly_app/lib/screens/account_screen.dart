import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Account"),
        backgroundColor: theme.cardColor,
        foregroundColor: cs.onSurface,
        elevation: 0.4,
      ),

      body: Center(
        child: Text(
          "Account Screen Coming Soon",
          style: TextStyle(
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
