import 'dart:ui';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedColor = cs.primary;                         // adaptive blue
    final unselectedColor = cs.onSurface.withOpacity(0.6);    // dimmed text
    final bgColor = cs.surface.withOpacity(0.7);              // blurred adaptive
    final shadowColor = cs.shadow.withOpacity(0.15);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: currentIndex,
            onTap: (index) => _onTap(context, index),

            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,

            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,

            items: [
              _animatedItem(Icons.home, "Main", 0, selectedColor),
              _animatedItem(Icons.history, "History", 1, selectedColor),
              _animatedItem(Icons.settings, "Settings", 2, selectedColor),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _animatedItem(
    IconData icon,
    String label,
    int index,
    Color selectedColor,
  ) {
    return BottomNavigationBarItem(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 1.0,
          end: currentIndex == index ? 1.28 : 1.0,
        ),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        builder: (context, scale, _) {
          return Transform.scale(
            scale: scale,
            child: Icon(
              icon,
            ),
          );
        },
      ),
      label: label,
    );
  }
}
