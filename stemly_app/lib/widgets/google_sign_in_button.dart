import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.primaryContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              final authService = context.read<FirebaseAuthService>();
              try {
                await authService.signInWithGoogle();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Signed in with Google")),
                );
              } catch (error) {
                if (!mounted) return;
                final errorMessage = error.toString();
                String userMessage;
                
                if (errorMessage.contains('ApiException: 10') || 
                    errorMessage.contains('DEVELOPER_ERROR') ||
                    errorMessage.contains('Firebase configuration')) {
                  userMessage = "Firebase not configured. See FIREBASE_SETUP.md";
                } else {
                  userMessage = "Login failed: ${errorMessage.length > 100 
                    ? errorMessage.substring(0, 100) + '...' 
                    : errorMessage}";
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(userMessage),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: "Details",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Login Error"),
                            content: SingleChildScrollView(
                              child: Text(errorMessage),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : const Icon(Icons.login),
      label: Text(
        _loading ? "Signing in..." : "Continue with Google",
        style: textTheme.labelLarge,
      ),
    );
  }
}

