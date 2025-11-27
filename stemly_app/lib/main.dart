import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/account_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: "STEMLY",
      debugShowCheckedModeBanner: false,

      themeMode: themeProvider.themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      // START APP WITH SPLASH SCREEN
      initialRoute: '/splash',

      onGenerateRoute: (settings) {
        late Widget page;

        switch (settings.name) {
          case '/splash':
            page = const SplashScreen();
            break;

          case '/':
            page = const MainScreen();
            break;

          case '/history':
            page = const HistoryScreen();
            break;

          case '/settings':
            page = const SettingsScreen();
            break;

          case '/privacy':
            page = const PrivacyPolicyScreen();
            break;

          case '/terms':
            page = const TermsScreen();
            break;

          case '/account':
            page = const AccountScreen();
            break;

          default:
            page = const MainScreen();
        }

        return PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: page,
            ),
          ),
        );
      },
    );
  }
}
