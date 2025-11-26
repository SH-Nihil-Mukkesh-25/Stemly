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
    const selectedColor = Color(0xFF003A70); // deep STEM blue
    const unselectedColor = Colors.grey;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0), // transparent
            elevation: 0,
            currentIndex: currentIndex,
            onTap: (index) => _onTap(context, index),
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              _animatedItem(Icons.home, "Main", 0),
              _animatedItem(Icons.history, "History", 1),
              _animatedItem(Icons.settings, "Settings", 2),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _animatedItem(
      IconData icon, String label, int index) {
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
            child: Icon(icon),
          );
        },
      ),
      label: label,
    );
  }
}
