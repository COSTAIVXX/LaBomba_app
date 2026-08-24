import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthProvider extends ChangeNotifier {
  static const String _sessionKey = 'labomba_admin_session';

  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'LaBomba@2027';

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  AdminAuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool(_sessionKey) ?? false;
      notifyListeners();
    } catch (_) {
      _isAuthenticated = false;
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.trim() == defaultUsername && password == defaultPassword) {
      _isAuthenticated = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_sessionKey, true);
      } catch (_) {}
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
    notifyListeners();
  }
}
