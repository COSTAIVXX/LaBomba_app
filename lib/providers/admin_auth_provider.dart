import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'LaBomba@2027';

  final AuthService _authService;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  AdminAuthProvider({required AuthService authService})
      : _authService = authService {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      _isAuthenticated = await _authService.isAdminAuthenticated();
      notifyListeners();
    } catch (_) {
      _isAuthenticated = false;
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.trim() == defaultUsername && password == defaultPassword) {
      _isAuthenticated = true;
      try {
        await _authService.setAdminSession(true);
      } catch (_) {}
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    try {
      await _authService.setAdminSession(false);
    } catch (_) {}
    notifyListeners();
  }
}
