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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<GoogleAuthData?> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _googleSignIn.signOut();
      
      // Correção 1: Adicionado '?' para aceitar o retorno anulável (GoogleSignInAccount?)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final firebase_auth.User? user = userCredential.user;

      if (user != null) {
        return GoogleAuthData(
          uid: user.uid,
          displayName: user.displayName ?? googleUser.displayName,
          email: user.email ?? googleUser.email,
          // Correção 2: Mudança de photoUrl para photoURL (padrão correto do model User do Firebase)
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