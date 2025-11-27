import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/bottom_nav_bar.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _sendFeedback() async {
    final Uri email = Uri(
      scheme: 'mailto',
      path: 'teamstemly@gmail.com',
      query: 'subject=STEMLY Feedback&body=Your feedback:',
    );
    await launchUrl(email, mode: LaunchMode.externalApplication);
  }

  Future<void> _rateApp() async {
    const url = "https://play.google.com/store/apps/details?id=com.stemly.app";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openInfoSheet(
    BuildContext context, {
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onPressed,
                  child: Text(buttonText, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showAboutSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: ListView(
                controller: controller,
                children: [
                  // ❌ REMOVED ONLY THE ANIMATION — NOTHING ELSE
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.primary,
                        child: Icon(
                          Icons.school,
                          color: cs.onPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Team STEMLY",
                        style: TextStyle(
                          fontSize: 22,
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "We are the creators of STEMLY — a tool that transforms STEM learning into an interactive visual experience.",
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Team Members",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _teamTile(
                    cs,
                    name: "P Dakshin Raj",
                    role: "Full Stack & Flutter",
                    avatar: "assets/team/dakshin.png",
                    github: "https://github.com/",
                    linkedin: "https://linkedin.com/",
                  ),

                  _teamTile(
                    cs,
                    name: "S H Nihi Mukkesh",
                    role: "AI / Backend",
                    avatar: "assets/team/nihi.png",
                    github: "https://github.com/",
                    linkedin: "https://linkedin.com/",
                  ),

                  _teamTile(
                    cs,
                    name: "Shre Ram P J",
                    role: "Machine Learning / Algorithms",
                    avatar: "assets/team/shreram.png",
                    github: "https://github.com/",
                    linkedin: "https://linkedin.com/",
                  ),

                  _teamTile(
                    cs,
                    name: "Vibin Ragav",
                    role: "UI/UX & Frontend",
                    avatar: "assets/team/vibin.png",
                    github: "https://github.com/",
                    linkedin: "https://linkedin.com/",
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _teamTile(
    ColorScheme cs, {
    required String name,
    required String role,
    required String avatar,
    required String github,
    required String linkedin,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primary.withOpacity(0.15),
            child: ClipOval(
              child: Image.asset(
                avatar,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: 32, color: cs.primary);
                },
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: Icon(Icons.link, color: cs.primary),
            onPressed: () => launchUrl(Uri.parse(linkedin)),
          ),
          IconButton(
            icon: Icon(Icons.code, color: cs.primary),
            onPressed: () => launchUrl(Uri.parse(github)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),

          const Divider(),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primary,
              child: Icon(Icons.info_outline, color: cs.onPrimary),
            ),
            title: const Text("About Us"),
            subtitle: const Text("Meet the team behind STEMLY"),
            onTap: () => _showAboutSheet(context),
          ),

          ListTile(
            leading: Icon(Icons.feedback_outlined, color: cs.primary),
            title: const Text("Send Feedback"),
            onTap: () {
              _openInfoSheet(
                context,
                title: "Send Feedback",
                message:
                    "We value your feedback. Help us improve STEMLY by sharing your thoughts.",
                buttonText: "Compose Email",
                onPressed: _sendFeedback,
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.star_rate_rounded, color: Colors.amber),
            title: const Text("Rate the App"),
            onTap: () {
              _openInfoSheet(
                context,
                title: "Rate STEMLY",
                message:
                    "If you enjoy STEMLY, support us by leaving a rating on the Play Store.",
                buttonText: "Open Play Store",
                onPressed: _rateApp,
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
            title: const Text("Privacy Policy"),
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),

          ListTile(
            leading: Icon(Icons.article_outlined, color: cs.primary),
            title: const Text("Terms & Conditions"),
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),
        ],
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
