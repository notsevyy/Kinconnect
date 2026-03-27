import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Cached profile data loaded after login/signup
  String? _userName;
  String? _seniorName;

  String? get userName => _userName;
  String? get seniorName => _seniorName;

  User? get currentUser => _auth.currentUser;
  bool hasSession() => _auth.currentUser != null;

  // --------------- Load profile from Firestore ---------------
  Future<void> loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        _userName = data['name'] as String?;
        _seniorName = data['seniorName'] as String?;
      }
    } catch (_) {}
  }

  // --------------- Sign Up ---------------
  Future<({bool success, String? error})> signUp({
    required String fullName,
    required String email,
    required String password,
    required String seniorName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      _userName = fullName;
      _seniorName = seniorName;

      // Seed initial Firestore + RTDB data (non-fatal if it fails)
      try {
        await FirebaseService().seedInitialData(uid, fullName, seniorName);
      } catch (_) {
        // Seeding failed — user is still authenticated, data can be created later
      }

      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _friendlyError(e.code));
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // --------------- Login ---------------
  Future<({bool success, String? error})> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await loadProfile();
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _friendlyError(e.code));
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // --------------- Sign Out ---------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _userName = null;
    _seniorName = null;
  }

  // --------------- Update profile ---------------
  Future<void> updateName(String name) async {
    _userName = name;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).update({'name': name});
    } catch (_) {}
  }

  Future<void> updateSeniorName(String name) async {
    _seniorName = name;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'seniorName': name});
    } catch (_) {}
  }

  // --------------- Password reset ---------------
  Future<({bool success, String? error})> sendPasswordReset(
      String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _friendlyError(e.code));
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // --------------- UI Mode (SharedPreferences only — never in Firebase) -----
  static const _uiModeKey = 'ui_mode';

  Future<String?> getUiMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_uiModeKey);
  }

  Future<void> setUiMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uiModeKey, mode);
  }

  // --------------- Onboarding (local flag — not in Firebase) ---------------
  bool _hasOnboarded = false;
  bool hasOnboarded() => _hasOnboarded;
  void markOnboarded() => _hasOnboarded = true;

  // --------------- Helpers ---------------
  static String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
