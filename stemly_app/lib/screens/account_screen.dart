import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/google_sign_in_button.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final authService = context.watch<FirebaseAuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Account"),
        backgroundColor: theme.cardColor,
        foregroundColor: cs.onSurface,
        elevation: 0.4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: user == null
            ? const _LoggedOutView()
            : _ProfileView(authService: authService),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Sign in to unlock synced history, notes, and personalised settings.",
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const GoogleSignInButton(),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.authService});

  final FirebaseAuthService authService;

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final cardColor = Theme.of(context).cardColor;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null ? const Icon(Icons.person, size: 48) : null,
        ),
        const SizedBox(height: 16),
        Text(user.displayName ?? "Unnamed Stemly Learner", style: textTheme.titleLarge),
        Text(user.email ?? "", style: textTheme.bodyMedium),
        const SizedBox(height: 32),
        Card(
          color: cardColor,
          elevation: 0.8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text("Firebase UID"),
                  subtitle: Text(user.uid),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text("Last login"),
                  subtitle: Text(
                    user.metadata.lastSignInTime?.toLocal().toString() ?? "Unknown",
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () async => authService.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text("Logout"),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
