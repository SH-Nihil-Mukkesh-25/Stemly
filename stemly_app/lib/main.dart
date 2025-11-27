import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'theme/theme_provider.dart';

// Screens
import 'screens/account_screen.dart';
import 'screens/history_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/terms_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase ONE TIME ONLY
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create Auth Service (but DO NOT initialize Firebase again inside it)
  final authService = FirebaseAuthService();
  await authService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<FirebaseAuthService>.value(value: authService),
      ],
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

      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

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

          case '/login':
            page = const LoginScreen();
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

        // Smooth transition effect
        return PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, animation, secondaryAnimation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: page,
              ),
            );
          },
        );
      },
    );
  }
}
