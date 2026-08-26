import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthData {
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String uid;

  GoogleAuthData({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}

class GoogleAuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  // Use the singleton instance of GoogleSignIn (app bootstrap will initialize it)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<GoogleAuthData?> signInWithGoogle() async {
    _setLoading(true);
    try {
      // Sign out any previous session to ensure a fresh flow.
      await _googleSignIn.signOut();

      // Perform an interactive authentication flow (new API).
      // authenticate() is the interactive sign-in that returns a GoogleSignInAccount.
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } catch (e) {
        // Some platforms may not support a combined flow; try a lightweight attempt
        // which may restore a previous sign-in. If it returns null, we bail out.
        try {
          final Future<GoogleSignInAccount?>? lightweight =
              _googleSignIn.attemptLightweightAuthentication();
          googleUser = await lightweight;
        } catch (_) {
          rethrow;
        }
      }

      if (googleUser == null) {
        return null;
      }

      // Get the ID token (authentication). Note: google_sign_in v7 exposes idToken only.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      // Try to obtain an access token (authorization) if available for the scopes.
      String? accessToken;
      try {
        final clientAuth = await googleUser.authorizationClient
            .authorizationForScopes(['email', 'profile', 'openid']);
        accessToken = clientAuth?.accessToken;
      } catch (_) {
        // If we can't obtain an access token, proceed with idToken only.
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

      if (user != null) {
        return GoogleAuthData(
          uid: user.uid,
          displayName: user.displayName ?? googleUser.displayName,
          email: user.email ?? googleUser.email,
          photoUrl: user.photoURL ?? googleUser.photoUrl,
        );
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('Erro de Plataforma no Google Sign-In: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erro desconhecido no Google Sign-In: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Erro ao sair: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}