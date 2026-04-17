import 'dart:convert';
import 'dart:io';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _keySession = 'session_token';
  static const _keyOnboarded = 'has_onboarded';
  static const _keyUserName = 'user_name';
  static const _keySeniorName = 'senior_name';

  Map<String, dynamic>? _cache;

  File get _file {
    final exe = Platform.resolvedExecutable;
    final dir = File(exe).parent.path;
    return File('$dir/kinconnect_prefs.json');
  }

  Map<String, dynamic> _read() {
    if (_cache != null) return _cache!;
    try {
      if (_file.existsSync()) {
        _cache = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
      }
    } catch (_) {
      // ignore corrupt file
    }
    _cache ??= {};
    return _cache!;
  }

  void _write() {
    try {
      _file.writeAsStringSync(jsonEncode(_cache));
    } catch (_) {
      // best-effort persistence
    }
  }

  // ---------- session ----------
  bool hasSession() => _read()[_keySession] != null;

  void saveSession() {
    _read()[_keySession] = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    _write();
  }

  void clearSession() {
    _read().remove(_keySession);
    _write();
  }

  // ---------- onboarding ----------
  bool hasOnboarded() => _read()[_keyOnboarded] == true;

  void markOnboarded() {
    _read()[_keyOnboarded] = true;
    _write();
  }

  // ---------- user info ----------
  void saveUserInfo({required String name, required String seniorName}) {
    final data = _read();
    data[_keyUserName] = name;
    data[_keySeniorName] = seniorName;
    _write();
  }

  String? get userName => _read()[_keyUserName] as String?;
  String? get seniorName => _read()[_keySeniorName] as String?;

  // ---------- mock auth ----------
  bool signUp({
    required String fullName,
    required String email,
    required String password,
    required String seniorName,
  }) {
    saveUserInfo(name: fullName, seniorName: seniorName);
    saveSession();
    return true;
  }

  bool login({
    required String email,
    required String password,
  }) {
    saveSession();
    return true;
  }

  void signOut() => clearSession();
}
