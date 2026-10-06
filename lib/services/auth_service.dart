import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Login dan logout dengan akun Google melalui Firebase Auth.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  bool _googleReady = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  /// Mengembalikan `null` jika pengguna membatalkan pemilihan akun.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }
    await _ensureGoogleReady();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Header izin untuk memanggil API Google lain (mis. Google Drive) dengan
  /// akun yang sedang login. Bisa memunculkan layar persetujuan sekali.
  Future<Map<String, String>> googleHeaders(List<String> scopes) async {
    await _ensureGoogleReady();
    final headers = await GoogleSignIn.instance.authorizationClient
        .authorizationHeaders(scopes, promptIfNecessary: true);
    if (headers == null) throw StateError('Izin Google tidak diberikan');
    return headers;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _ensureGoogleReady();
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }
}
