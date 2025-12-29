import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/bottom_nav_bar.dart';
import '../theme/theme_provider.dart';
import 'package:stemly_app/services/groq_service.dart'; // UPDATED

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // GROK: SAVE API KEY
  Future<void> _saveApiKey(BuildContext context) async {
    final groqService = Provider.of<GroqService>(context, listen: false); // UPDATED
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final key = _apiKeyController.text.trim();

    if (key.isEmpty) {
       scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Please enter a valid API Key.")),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final error = await groqService.setApiKey(key); // UPDATED
    
    if (mounted) {
      if (error == null) {
        _apiKeyController.clear();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("${groqService.provider} API Key saved successfully."), // UPDATED
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              error.contains("401") 
                ? "Invalid API Key (Unauthorized)" 
                : "Error: $error"
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // GROK: RESET
  Future<void> _removeApiKey(BuildContext context) async {
    final groqService = Provider.of<GroqService>(context, listen: false); // UPDATED
    await groqService.removeApiKey();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed xAI API Key.")), // UPDATED
      );
    }
  }

  // FEEDBACK
  Future<void> _sendFeedback() async {
    final Uri email = Uri(
      scheme: 'mailto',
      path: 'teamstemly@gmail.com',
      query: 'subject=STEMLY Feedback&body=Your feedback:',
    );
    await launchUrl(email, mode: LaunchMode.externalApplication);
  }

  // RATE APP
  Future<void> _rateApp() async {
    const url = "https://play.google.com/store/apps/details?id=com.stemly.app";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // GENERIC INFO SHEET
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
              Text(title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  )),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.8)),
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
            ],
          ),
        );
      },
    );
  }

  // ABOUT SHEET
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.primary,
                        child: Icon(Icons.school, color: cs.onPrimary, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Text("Team STEMLY",
                          style: TextStyle(
                            fontSize: 22,
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          )),
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
                  Text("Team Members",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      )),
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
                    role: "Machine Learning",
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

  // TEAM TILE
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
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, size: 32, color: cs.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: cs.primary)),
                Text(role,
                    style:
                        TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.7))),
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
    final themeProvider = context.watch<ThemeProvider>();
    final groqService = context.watch<GroqService>(); // UPDATED
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        automaticallyImplyLeading: false,
      ),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // GROQ API SECTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Configuration (${groqService.provider})", // UPDATED
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Indicator
                        Row(
                          children: [
                            Icon(
                              groqService.isConfigured ? Icons.check_circle : Icons.error_outline,
                              color: groqService.isConfigured ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              groqService.isConfigured ? "${groqService.provider} Active" : "Missing API Key", // UPDATED
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: groqService.isConfigured ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (groqService.apiKey != null) ...[
                          Text(
                            "Key: •••••••••${groqService.apiKey!.length > 4 ? groqService.apiKey!.substring(groqService.apiKey!.length - 4) : ''}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        const Text(
                          "Enter API Key (xAI, OpenAI, or Groq) to enable AI.", // UPDATED
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),

                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _isObscured,
                          decoration: InputDecoration(
                            labelText: "API Key", // UPDATED
                            hintText: "xai-...",
                            border: const OutlineInputBorder(),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.content_paste),
                                  onPressed: () async {
                                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                                    if (data?.text != null) {
                                      setState(() {
                                        _apiKeyController.text = data!.text!;
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _isObscured = !_isObscured),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: groqService.isValidating 
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: () => _saveApiKey(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      foregroundColor: cs.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text("Save & Test"),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => _removeApiKey(context),
                              child: const Text("Reset"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),


          // DARK MODE
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.toggleTheme,
          ),

          // NOTIFICATION TOGGLE
          SwitchListTile(
            title: const Text("Notifications"),
            subtitle: const Text("Receive updates from STEMLY"),
            value: themeProvider.notifications,
            onChanged: themeProvider.toggleNotifications,
          ),

          // WIFI ONLY
          SwitchListTile(
            title: const Text("Wi-Fi Only Mode"),
            subtitle: const Text("Process scans only on Wi-Fi"),
            value: themeProvider.wifiOnly,
            onChanged: themeProvider.toggleWifiOnly,
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
            onTap: () => _openInfoSheet(
              context,
              title: "Send Feedback",
              message:
                  "We value your feedback. Help us improve STEMLY by sharing your thoughts.",
              buttonText: "Compose Email",
              onPressed: _sendFeedback,
            ),
          ),

          ListTile(
            leading: Icon(Icons.star_rate_rounded, color: Colors.amber),
            title: const Text("Rate the App"),
            onTap: () => _openInfoSheet(
              context,
              title: "Rate STEMLY",
              message:
                  "If you enjoy STEMLY, support us by leaving a rating on the Play Store.",
              buttonText: "Open Play Store",
              onPressed: _rateApp,
            ),
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
