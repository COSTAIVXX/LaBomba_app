import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';
import 'storage_platform.dart';
import 'admin_profile_service.dart';

/// Central AuthService that encapsulates FirebaseAuth, GoogleSignIn and
/// secure storage for tokens and admin session flags.
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final StorageService _storage;

  static const String _adminSessionKey = 'labomba_admin_session';
  static const String _idTokenKey = 'labomba_id_token';

  AuthService({StorageService? storageService}) : _storage = storageService ?? PlatformStorageService();

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
      try {
        final Future<GoogleSignInAccount?>? lightweight =
            _googleSignIn.attemptLightweightAuthentication();
        googleUser = await lightweight;
      } catch (e) {
        // Surface a friendlier message to the UI instead of crashing the app.
        throw Exception('Google Sign-In indisponível no momento. Tente novamente.');
      }
    }

    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    const String? accessToken = null;

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
      if (token != null) {
        await _storage.write(key: _idTokenKey, value: token);
      }
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
      await _storage.delete(key: _idTokenKey);
    } catch (_) {}
    try {
      await _storage.delete(key: _adminSessionKey);
    } catch (_) {}
  }

  /// Admin session persistence (uses secure storage instead of SharedPreferences)
  Future<void> setAdminSession(bool value) async {
    try {
      if (value) {
        await _storage.write(key: _adminSessionKey, value: '1');
      } else {
        await _storage.delete(key: _adminSessionKey);
      }
    } catch (_) {}
  }

  Future<bool> isAdminAuthenticated() async {
    try {
      // Prefer authoritative check against Firestore admin_profiles if a Firebase user is present
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final adminSvc = AdminProfileService();
          final isAdmin = await adminSvc.isCurrentUserAdmin();
          if (isAdmin) {
            // persist local admin session for faster restores
            try {
              await _storage.write(key: _adminSessionKey, value: '1');
            } catch (_) {}
            return true;
          }
        } catch (_) {
          // ignore and fall back to stored flag
        }
      }

      final v = await _storage.read(key: _adminSessionKey);
      return v == '1';
    } catch (_) {
      return false;
    }
  }

  /// Expose current Firebase user (if any)
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Reload the current Firebase user from the backend and refresh local state
  Future<void> reloadCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {}
  }

  /// Read stored id token (if any)
  Future<String?> readStoredIdToken() => _storage.read(key: _idTokenKey);

  /// Returns a valid ID token when possible. If [forceRefresh] is true
  /// it forces a refresh from Firebase; otherwise it will try to read from
  /// secure storage or current user.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      // Prefer the Firebase User token (fresh)
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken(forceRefresh);
        if (token != null) {
          try {
            await _storage.write(key: _idTokenKey, value: token);
          } catch (_) {}
          return token;
        }
      }

      // Fallback to stored token
      final stored = await _storage.read(key: _idTokenKey);
      return stored;
    } catch (_) {
      // On any error, attempt stored token
      try {
        return await _storage.read(key: _idTokenKey);
      } catch (_) {
        return null;
      }
    }
  }
}

