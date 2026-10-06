import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Cache profil orang lain (nama, foto) untuk ditampilkan di chat.
class UserDirectory {
  UserDirectory._();
  static final instance = UserDirectory._();

  final _cache = <String, Future<AppUser?>>{};

  Future<AppUser?> get(String uid) {
    return _cache.putIfAbsent(uid, () async {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = snap.data();
        return data == null ? null : AppUser.fromMap(uid, data);
      } catch (_) {
        _cache.remove(uid);
        return null;
      }
    });
  }
}
