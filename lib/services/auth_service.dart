import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central AuthService that encapsulates FirebaseAuth, GoogleSignIn and
/// secure storage for tokens and admin session flags.
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FlutterSecureStorage _secureStorage;

  static const String _adminSessionKey = 'labomba_admin_session';
  static const String _idTokenKey = 'labomba_id_token';

  AuthService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Optional init; main.dart already calls GoogleSignIn.instance.initialize()
  /// but this method is safe to call if necessary (it will surface errors).
  Future<void> initialize() async {
    try {
      await _googleSignIn.initialize();
    } catch (_) {
      // swallow - initialization may already have been done at bootstrap
    }
  }

  /// Performs Google Sign-In flow, signs in to Firebase and stores an ID token
  /// in secure storage when available. Returns a map with user info or null on
  /// cancellation.
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    // Ensure clean start
    await _googleSignIn.signOut();

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } catch (_) {
      // Fallback to lightweight attempt if interactive flow not available
      try {
        final Future<GoogleSignInAccount?>? lightweight =
            _googleSignIn.attemptLightweightAuthentication();
        googleUser = await lightweight;
      } catch (e) {
        rethrow;
      }
    }

    if (googleUser == null) return null;

    final googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    String? accessToken;
    try {
      final clientAuth = await googleUser.authorizationClient
          .authorizationForScopes(['email', 'profile', 'openid']);
      accessToken = clientAuth?.accessToken;
    } catch (_) {
      accessToken = null;
    }

    final firebase_auth.OAuthCredential credential =
        firebase_auth.GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    final firebase_auth.UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    final firebase_auth.User? user = userCredential.user;

    if (user == null) return null;

    // Persist id token for ApiService or other uses
    try {
      final token = await user.getIdToken();
      await _secureStorage.write(key: _idTokenKey, value: token);
    } catch (_) {}

    return {
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
    };
  }

  /// Signs out from Firebase and Google and clears stored tokens/sessions.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (_) {}
    try {
      await _secureStorage.delete(key: _idTokenKey);
    } catch (_) {}
    try {
      await _secureStorage.delete(key: _adminSessionKey);
    } catch (_) {}
  }

  /// Admin session persistence (uses secure storage instead of SharedPreferences)
  Future<void> setAdminSession(bool value) async {
    try {
      if (value) {
        await _secureStorage.write(key: _adminSessionKey, value: '1');
      } else {
        await _secureStorage.delete(key: _adminSessionKey);
      }
    } catch (_) {}
  }

  Future<bool> isAdminAuthenticated() async {
    try {
      final v = await _secureStorage.read(key: _adminSessionKey);
      return v == '1';
    } catch (_) {
      return false;
    }
  }

  /// Expose current Firebase user (if any)
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Read stored id token (if any)
  Future<String?> readStoredIdToken() => _secureStorage.read(key: _idTokenKey);
}
