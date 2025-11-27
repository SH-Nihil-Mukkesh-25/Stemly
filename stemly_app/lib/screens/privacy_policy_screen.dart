import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Privacy Policy"),
        elevation: 0.4,
        backgroundColor: theme.cardColor,
        foregroundColor: cs.onSurface,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  "Privacy Policy",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "This Privacy Policy explains how STEMLY collects, uses, "
                  "protects, and stores your information.",
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface.withOpacity(0.75),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                _section(
                  context,
                  title: "1. Information We Collect",
                  body:
                      "We only process images and text you voluntarily upload for educational analysis. "
                      "We do not collect personal data unless you explicitly provide it.",
                ),

                _section(
                  context,
                  title: "2. How We Use Your Data",
                  body:
                      "Uploaded images and variables are processed to generate visual learning material. "
                      "Your data is never sold or shared with third parties.",
                ),

                _section(
                  context,
                  title: "3. Data Storage",
                  body:
                      "Scanned images are stored locally on your device. "
                      "Nothing is stored on external servers without your consent.",
                ),

                _section(
                  context,
                  title: "4. Third-Party Services",
                  body:
                      "We may use AI APIs for generating notes or visuals. "
                      "These APIs only receive the data needed for processing.",
                ),

                _section(
                  context,
                  title: "5. Your Consent",
                  body:
                      "By using STEMLY, you consent to the processing of your content solely for learning enhancement.",
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: cs.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: cs.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
