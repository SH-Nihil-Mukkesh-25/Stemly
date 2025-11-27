import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scanController;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slideUp;
  late Animation<double> _scanPulse;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Scanning pulse animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scanPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _mainController.forward();

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      final auth = context.read<FirebaseAuthService>();
      final nextRoute = auth.isAuthenticated ? '/' : '/login';
      Navigator.pushReplacementNamed(context, nextRoute);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF1A237E), const Color(0xFF0D47A1), _fade.value)!,
                        Color.lerp(const Color(0xFF0D47A1), const Color(0xFF1565C0), _fade.value)!,
                        Color.lerp(const Color(0xFF1976D2), const Color(0xFF42A5F5), _fade.value)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating particles (STEM elements)
          ...List.generate(15, (index) {
            return _FloatingIcon(
              icon: _getSTEMIcon(index),
              delay: index * 0.2,
              controller: _mainController,
            );
          }),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scanning icon with pulse
                    ScaleTransition(
                      scale: _scale,
                      child: AnimatedBuilder(
                        animation: _scanPulse,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scanPulse.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.5),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Icon(
                                        Icons.document_scanner_rounded,
                                        size: 70,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App title
                    Text(
                      "STEM QUEST",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline with animated typing effect
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fade.value,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AnimatedText("Scan", _mainController, 0.3),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward, color: Colors.cyanAccent, size: 16),
                              ),
                              _AnimatedText("Learn", _mainController, 0.45),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward, color: Colors.cyanAccent, size: 16),
                              ),
                              _AnimatedText("Play", _mainController, 0.6),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        "Your Smart Visual Learning Companion",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSTEMIcon(int index) {
    final icons = [
      Icons.functions,
      Icons.science_rounded,
      Icons.calculate_rounded,
      Icons.biotech_rounded,
      Icons.bolt_rounded,
      Icons.lightbulb_outline,
      Icons.rocket_launch_rounded,
      Icons.memory_rounded,
      Icons.sensors_rounded,
      Icons.psychology_rounded,
      Icons.settings_input_component,
      Icons.tune_rounded,
      Icons.whatshot_rounded,
      Icons.auto_awesome_rounded,
      Icons.category_rounded,
    ];
    return icons[index % icons.length];
  }
}

// Floating STEM icon widget
class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double delay;
  final AnimationController controller;

  const _FloatingIcon({
    required this.icon,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = (icon.hashCode % 100) / 100;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = (controller.value - delay).clamp(0.0, 1.0);
        return Positioned(
          left: size.width * (0.1 + random * 0.8),
          top: size.height * (0.1 + random * 0.8),
          child: Opacity(
            opacity: (progress * 0.3).clamp(0.0, 0.3),
            child: Transform.scale(
              scale: 0.5 + progress * 0.5,
              child: Icon(
                icon,
                size: 24 + random * 20,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated text widget
class _AnimatedText extends StatelessWidget {
  final String text;
  final AnimationController controller;
  final double startDelay;

  const _AnimatedText(this.text, this.controller, this.startDelay);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = ((controller.value - startDelay) / 0.2).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progress)),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.cyanAccent,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }
}