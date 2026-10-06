import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Baca/tulis profil pengguna di koleksi `users`.
class UserRepository {
  UserRepository._();
  static final instance = UserRepository._();

  final _users = FirebaseFirestore.instance.collection('users');

  Stream<AppUser?> watch(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : AppUser.fromMap(uid, data);
    });
  }

  /// Membuat dokumen profil awal saat pertama kali login,
  /// diisi dari data akun Google. Tidak menimpa profil yang sudah ada.
  Future<void> ensureExists(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      ...AppUser(
        uid: user.uid,
        email: user.email ?? '',
        namaLengkap: user.displayName ?? '',
        fotoUrl: user.photoURL,
      ).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> save(AppUser user) {
    return _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }
}
