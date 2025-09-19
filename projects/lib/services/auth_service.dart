// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Sign in with email & password, persist UID, and return true on success.
  Future<bool> signIn(String email, String password) async {
    try {
      // Firebase sign-in
      UserCredential cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) return false;

      // Persist UID locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', uid);
      return true;
    } catch (e) {
      print("AuthService.signIn error: $e");
      return false;
    }
  }

  /// Create new user in Firebase, persist UID, and return true on success.
  Future<bool> signUp(String email, String username,String password) async {
  try {
    String url= dotenv.env['BACKEND']!;
    UserCredential cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user?.uid;
    if (uid == null) return false;
  final user = cred.user;
  if (user != null) {
    await user.updateDisplayName(username);
    // Optional: reload the user so the change takes effect locally
    await user.reload();
  }
    // Persist new UID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', uid);

    // Call your API
    final response = await http.post(
      Uri.parse('$url/register'), // Replace with your actual API URL
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uid': uid,
        'username': username,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('API call failed with status: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print("AuthService.signUp error: $e");
    return false;
  }
}


  /// Retrieve the persisted UID from local storage
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  /// Sign out from Firebase and clear stored UID
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
    } catch (e) {
      print("AuthService.signOut error: $e");
    }
  }
}
