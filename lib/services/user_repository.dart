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

  /// Menyimpan profil. Jika username berubah, username baru "dipesan" di
  /// `usernames/{username}` agar tidak bisa dipakai orang lain, dan yang
  /// lama dilepas.
  Future<void> save(AppUser user) async {
    final db = FirebaseFirestore.instance;
    final ref = _users.doc(user.uid);
    final baru = user.username;
    await db.runTransaction((tx) async {
      final lama = (await tx.get(ref)).data()?['username'] as String? ?? '';
      if (baru.isNotEmpty && baru != lama) {
        final klaim = await tx.get(db.collection('usernames').doc(baru));
        if (klaim.exists && klaim.data()?['uid'] != user.uid) throw const UsernameDipakai();
        if (!klaim.exists) tx.set(klaim.reference, {'uid': user.uid});
        if (lama.isNotEmpty) tx.delete(db.collection('usernames').doc(lama));
      }
      tx.set(ref, user.toMap(), SetOptions(merge: true));
    });
  }
}

/// Username sudah dipakai orang lain.
class UsernameDipakai implements Exception {
  const UsernameDipakai();

  @override
  String toString() => 'Username ini sudah dipakai orang lain. Coba yang lain.';
}
