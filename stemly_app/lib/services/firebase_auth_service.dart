import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

class FirebaseConfigurationException implements Exception {
  final String message;
  FirebaseConfigurationException(this.message);
  @override
  String toString() => message;
}

const String _tokenStorageKey = "stemly_id_token";
const String _profileStorageKey = "stemly_user_profile";
const String _apiBaseUrl = String.fromEnvironment(
  'STEMLY_API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ["email"]);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  StreamSubscription<User?>? _authSubscription;
  SharedPreferences? _prefs;
  User? _user;
  String? _cachedIdToken;

  User? get currentUser => _user;

  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _user = _auth.currentUser;

    if (_user != null) {
      await _cacheAuthState(_user!);
    } else {
      _cachedIdToken = await _secureStorage.read(key: _tokenStorageKey);
    }

    _authSubscription = _auth.idTokenChanges().listen((user) async {
      _user = user;
      if (user != null) {
        await _cacheAuthState(user);
      } else {
        _cachedIdToken = null;
        await _secureStorage.delete(key: _tokenStorageKey);
        await _prefs?.remove(_profileStorageKey);
      }
      notifyListeners();
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Validate Firebase configuration
      if (!DefaultFirebaseOptions.isValid) {
        throw FirebaseConfigurationException(
          "Firebase is not properly configured. "
          "Please run: flutter pub global activate flutterfire_cli && flutterfire configure"
        );
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception(
          "Google Sign-In failed: Missing ID token. "
          "This usually means your Android app is not properly configured in Firebase Console. "
          "Please check:\n"
          "1. Package name matches: com.example.stemly_app\n"
          "2. SHA-1 and SHA-256 keys are added in Firebase Console\n"
          "3. google-services.json is placed in android/app/\n"
          "4. Run: cd android && ./gradlew signingReport to get SHA keys"
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _cacheAuthState(userCredential.user);
      await warmUpBackend();
      notifyListeners();
      return userCredential;
    } on FirebaseException catch (e) {
      debugPrint("Firebase error: ${e.code} - ${e.message}");
      String userMessage = "Authentication failed. ";
      
      if (e.code == 'auth/network-request-failed') {
        userMessage += "Please check your internet connection.";
      } else if (e.code.contains('developer') || e.code == '10') {
        userMessage += "Firebase configuration error. Please ensure:\n"
            "1. Run 'flutterfire configure' to generate firebase_options.dart\n"
            "2. Download google-services.json from Firebase Console\n"
            "3. Place it in android/app/google-services.json\n"
            "4. Add SHA-1 and SHA-256 keys in Firebase Console\n"
            "5. Rebuild the app: flutter clean && flutter run";
      } else {
        userMessage += "${e.message ?? 'Unknown error'}";
      }
      
      throw Exception(userMessage);
    } catch (error, stackTrace) {
      debugPrint("Google sign-in failed: $error");
      debugPrintStack(stackTrace: stackTrace);
      
      final errorStr = error.toString();
      if (errorStr.contains('ApiException: 10') || errorStr.contains('DEVELOPER_ERROR')) {
        throw Exception(
          "Google Sign-In configuration error (ApiException: 10).\n\n"
          "This means your Android app is not properly registered in Firebase.\n\n"
          "Fix steps:\n"
          "1. Go to Firebase Console → Project Settings → Your Apps → Android\n"
          "2. Ensure package name is: com.example.stemly_app\n"
          "3. Get SHA keys: cd stemly_app/android && ./gradlew signingReport\n"
          "4. Add SHA-1 and SHA-256 to Firebase Console\n"
          "5. Download google-services.json and place in android/app/\n"
          "6. Run: flutterfire configure\n"
          "7. Rebuild: flutter clean && flutter run"
        );
      }
      
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _secureStorage.delete(key: _tokenStorageKey);
    await _prefs?.remove(_profileStorageKey);
    _cachedIdToken = null;
    _user = null;
    notifyListeners();
  }

  Future<void> warmUpBackend() async {
    final token = await getIdToken();
    if (token == null) return;

    try {
      await http.get(
        Uri.parse("$_apiBaseUrl/auth/me"),
        headers: {"Authorization": "Bearer $token"},
      );
    } catch (error) {
      debugPrint("Backend warm-up failed: $error");
    }
  }

  Future<Map<String, String>> authenticatedHeaders({Map<String, String>? base}) async {
    final token = await getIdToken();
    if (token == null) {
      throw StateError("User is not authenticated.");
    }

    final headers = <String, String>{};
    if (base != null) {
      headers.addAll(base);
    }
    headers["Authorization"] = "Bearer $token";
    headers["Content-Type"] = "application/json";
    return headers;
  }

  Future<http.Response> getWithAuth(String path) async {
    final headers = await authenticatedHeaders();
    return http.get(Uri.parse("$_apiBaseUrl$path"), headers: headers);
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (_user != null) {
      final token = await _user!.getIdToken(forceRefresh);
      _cachedIdToken = token;
      await _secureStorage.write(key: _tokenStorageKey, value: token);
      return token;
    }

    _cachedIdToken ??= await _secureStorage.read(key: _tokenStorageKey);
    return _cachedIdToken;
  }

  Map<String, dynamic>? readCachedProfile() {
    final data = _prefs?.getString(_profileStorageKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> _cacheAuthState(User? user) async {
    if (user == null) return;
    final token = await user.getIdToken();
    _cachedIdToken = token;

    await _secureStorage.write(key: _tokenStorageKey, value: token);

    final payload = {
      "uid": user.uid,
      "name": user.displayName,
      "email": user.email,
      "photoUrl": user.photoURL,
    };

    await _prefs?.setString(_profileStorageKey, jsonEncode(payload));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

