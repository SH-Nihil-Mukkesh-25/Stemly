import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ---------- APP BAR ----------
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        centerTitle: true,
        backgroundColor: theme.cardColor,
        foregroundColor: cs.onSurface,
        elevation: 0.4,
      ),

      // ---------- BODY ----------
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
                  "Terms & Conditions",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: cs.primary,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Please read these Terms & Conditions carefully before using the STEMLY application.",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: cs.onSurface.withOpacity(0.75),
                  ),
                ),

                const SizedBox(height: 28),

                _section(
                  context,
                  title: "1. Acceptance of Terms",
                  body:
                      "By installing or using STEMLY, you agree to these Terms & Conditions. "
                      "If you disagree, please discontinue usage.",
                ),

                _section(
                  context,
                  title: "2. Educational Purpose",
                  body:
                      "STEMLY is offered strictly for educational learning, visualization, and productivity. "
                      "It must not be used for harmful or illegal activities.",
                ),

                _section(
                  context,
                  title: "3. Generated Content",
                  body:
                      "AI-generated explanations, notes, and visuals may contain minor inaccuracies. "
                      "Always verify important information independently.",
                ),

                _section(
                  context,
                  title: "4. User Responsibilities",
                  body:
                      "You are responsible for using the app ethically and ensuring the images you upload "
                      "are your own and do not violate copyright.",
                ),

                _section(
                  context,
                  title: "5. App Updates",
                  body:
                      "STEMLY may receive updates that add, modify, or remove features. "
                      "Continued use implies acceptance of changes.",
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- SECTION WIDGET ----------
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
