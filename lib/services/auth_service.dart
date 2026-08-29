import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';
import 'storage_platform.dart';
import 'admin_profile_service.dart';

/// Central AuthService that encapsulates FirebaseAuth, GoogleSignIn and
/// secure storage for tokens and admin session flags.

/// Unified auth status enum exposed by AuthService.authStatus
enum AuthStatus { unknown, unauthenticated, authenticated, admin }

class AuthService {
  // Load master credentials from environment to avoid hardcoding secrets.
  // In CI or development you can pass --dart-define=MASTER_EMAIL=... --dart-define=MASTER_PASSWORD=...
  static const String masterEmail = String.fromEnvironment('MASTER_EMAIL', defaultValue: '');
  static const String masterPassword = String.fromEnvironment('MASTER_PASSWORD', defaultValue: '');

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final StorageService _storage;

  static const String _adminSessionKey = 'labomba_admin_session';
  static const String _masterIdentityKey = 'labomba_master_identity';
  static const String _idTokenKey = 'labomba_id_token';

  bool _masterSessionActive = false;

  /// Centralized auth status for the app. Consumers should observe this
  /// ValueNotifier instead of checking FirebaseAuth.instance.currentUser directly.
  /// Values: unknown -> initial, unauthenticated, authenticated (normal user), admin (master)
  static const AuthStatus initialAuthStatus = AuthStatus.unknown;
  final ValueNotifier<AuthStatus> authStatus = ValueNotifier<AuthStatus>(initialAuthStatus);

  bool get isMasterUser => (_masterSessionActive) ||
      (_auth.currentUser?.email?.toLowerCase() == masterEmail.toLowerCase());

  AuthService({StorageService? storageService}) : _storage = storageService ?? PlatformStorageService() {
    // Listen to Firebase Auth state changes and update centralized auth status.
    _auth.authStateChanges().listen((firebaseUser) async {
      try {
        if (firebaseUser == null) {
          // If we have an in-memory master session active, prefer ADMIN
          if (_masterSessionActive) {
            authStatus.value = AuthStatus.admin;
          } else {
            authStatus.value = AuthStatus.unauthenticated;
          }
        } else {
          // If the Firebase user matches master email (env), treat as admin
          final email = firebaseUser.email?.toLowerCase() ?? '';
          if (masterEmail.isNotEmpty && email == masterEmail.toLowerCase()) {
            authStatus.value = AuthStatus.admin;
            _masterSessionActive = true;
          } else {
            authStatus.value = AuthStatus.authenticated;
            _masterSessionActive = false;
          }
        }
      } catch (_) {
        // ignore listener errors to avoid crashing app
      }
    });
  }

  bool isMasterCredentials({required String email, required String password}) {
    // Disallow master bypass in release builds for safety.
    if (kReleaseMode) return false;
    if (masterEmail.isEmpty || masterPassword.isEmpty) return false;
    return email.trim().toLowerCase() == masterEmail.toLowerCase() && password == masterPassword;
  }

  Map<String, dynamic> _buildFallbackUserPayload({required String uid, required String email}) {
    return {
      'uid': uid,
      'displayName': 'Comandante',
      'email': email,
      'photoURL': null,
      'masterFallback': true,
    };
  }

  /// Optional init; main.dart already calls GoogleSignIn.instance.initialize()
  /// but this method is safe to call if necessary (it will surface errors).
  Future<void> initialize() async {
    try {
      await _googleSignIn.initialize();
    } catch (_) {
      // swallow - initialization may already have been done at bootstrap
    }
  }

  Future<Map<String, dynamic>?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final isMasterLogin = isMasterCredentials(
      email: normalizedEmail,
      password: password,
    );

    if (isMasterLogin) {
      // Master login must authenticate against Firebase as a real user (Email/Password).
      // Do not create anonymous sessions or rely solely on local flags.
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        final user = userCredential.user;
        if (user == null) return null;
        await setAdminSession(true);
        _masterSessionActive = true;
        return {
          'uid': user.uid,
          'displayName': user.displayName ?? 'Comandante',
          'email': user.email,
          'photoURL': user.photoURL,
        };
      } on firebase_auth.FirebaseAuthException catch (e) {
        print('Master signIn failed: ${e.code} ${e.message}');
        return null;
      } catch (e) {
        print('Unexpected error during master signIn: $e');
        return null;
      }
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) return null;
      await setAdminSession(user.email?.toLowerCase() == masterEmail.toLowerCase());
      return {
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Provide diagnostics for common auth failures
      print('FirebaseAuth signIn failed: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error during signInWithEmailAndPassword: $e');
      return null;
    }
  }

  /// Performs Google Sign-In flow, signs in to Firebase and stores an ID token
  /// in secure storage when available. Returns a map with user info or null on
  /// cancellation.
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on PlatformException catch (_) {
      googleUser = null;
    } on Exception catch (_) {
      googleUser = null;
    } catch (_) {
      googleUser = null;
    }

    if (googleUser == null) {
      try {
        googleUser = await _googleSignIn.attemptLightweightAuthentication();
      } catch (_) {
        googleUser = null;
      }
    }

    if (googleUser == null) return null;

    try {
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
    } on firebase_auth.FirebaseAuthException catch (_) {
      return null;
    } on PlatformException catch (_) {
      return null;
    } catch (_) {
      throw Exception('Google Sign-In indisponível no momento. Tente novamente.');
    }
  }

  /// Signs out from Firebase and Google and clears stored tokens/sessions.
  Future<void> signOut() async {
    _masterSessionActive = false;
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
    try {
      await _storage.delete(key: _masterIdentityKey);
    } catch (_) {}
  }

  /// Admin session persistence (uses secure storage instead of SharedPreferences)
  Future<void> setAdminSession(bool value) async {
    try {
      if (value) {
        await _storage.write(key: _adminSessionKey, value: '1');
      } else {
        _masterSessionActive = false;
        await _storage.delete(key: _adminSessionKey);
        await _storage.delete(key: _masterIdentityKey);
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

