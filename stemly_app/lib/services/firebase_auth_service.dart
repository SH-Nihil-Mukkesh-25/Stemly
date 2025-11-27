import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _cacheAuthState(userCredential.user);
      await warmUpBackend();
      notifyListeners();
      return userCredential;
    } catch (error, stackTrace) {
      debugPrint("Google sign-in failed: $error");
      debugPrintStack(stackTrace: stackTrace);
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

