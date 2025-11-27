import 'dart:ui';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  static const Color blue = Color(0xFF1A73E8); // Google blue

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 🌫️ GLASS COLORS THAT MATCH BOTH THEMES
    final Color glassColor = isDark
        ? Colors.blue.withOpacity(0.15)  // dark mode → dark blue glass
        : Colors.white.withOpacity(0.15); // light mode → white clean glass

    // 🌟 SHADOW BASED ON THEME
    final Color shadowColor = isDark
        ? Colors.black.withOpacity(0.45)
        : blue.withOpacity(0.30);

    // TEXT + ICON COLORS ADAPT CLEANLY
    final Color inactiveColor = isDark ? Colors.white70 : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 16, right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: glassColor, // 💎 theme-aware clean glass
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(context, Icons.home_rounded, 0, "Home", inactiveColor),
                _item(context, Icons.history_rounded, 1, "History", inactiveColor),
                _item(context, Icons.settings_rounded, 2, "Settings", inactiveColor),
                _item(context, Icons.person_rounded, 3, "Account", inactiveColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    int index,
    String label,
    Color inactiveColor,
  ) {
    final bool selected = currentIndex == index;

    return GestureDetector(
      onTap: () => _go(context, index),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? blue.withOpacity(0.25) : Colors.transparent,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.20 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: 28,
                color: selected ? blue : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? blue : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
