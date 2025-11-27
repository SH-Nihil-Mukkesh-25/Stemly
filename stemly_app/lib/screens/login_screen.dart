import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeNavigateToHome(FirebaseAuthService auth) {
    if (!mounted || _navigated || !auth.isAuthenticated) return;
    _navigated = true;
    Future.microtask(() {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<FirebaseAuthService>();
    _maybeNavigateToHome(auth);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                            const Color(0xFF0D47A1),
                            const Color(0xFF1565C0),
                            _controller.value)!,
                        Color.lerp(
                            const Color(0xFF1A237E),
                            const Color(0xFF0D47A1),
                            _controller.value)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
          ),
          _AnimatedGlow(controller: _controller),
          _BlurOrb(
            top: 120,
            left: -40,
            size: 220,
            color: Colors.cyanAccent.withOpacity(0.25),
            controller: _controller,
            reverse: false,
          ),
          _BlurOrb(
            bottom: 80,
            right: -30,
            size: 180,
            color: Colors.deepPurpleAccent.withOpacity(0.25),
            controller: _controller,
            reverse: true,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    "Welcome to",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "STEMLY",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scan diagrams, explore simulations, and generate AI study notes—all synced to your profile.",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const Spacer(),
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt, color: colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text(
                                "Why Sign In?",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _LoginBenefit(
                            icon: Icons.cloud_sync,
                            text: "Sync scan history and AI notes across devices.",
                          ),
                          _LoginBenefit(
                            icon: Icons.security,
                            text: "Secure, password-free sign-in with Google.",
                          ),
                          _LoginBenefit(
                            icon: Icons.auto_awesome,
                            text:
                                "Get personalised visualisations and study sessions.",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const GoogleSignInButton(),
                  TextButton(
                    onPressed: () => auth.warmUpBackend(),
                    child: const Text(
                      "Need help connecting? Tap to retry backend sync.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBenefit extends StatelessWidget {
  const _LoginBenefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.cyanAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.controller,
    this.reverse = false,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final AnimationController controller;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = reverse ? 1 - controller.value : controller.value;
        return Positioned(
          top: top != null ? top! + 10 * value : null,
          left: left != null ? left! + 10 * value : null,
          right: right != null ? right! - 10 * value : null,
          bottom: bottom != null ? bottom! - 10 * value : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox(),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedGlow extends StatelessWidget {
  const _AnimatedGlow({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.06 * controller.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

