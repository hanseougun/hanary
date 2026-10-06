import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Pertemanan.
///
/// - Permintaan pertemanan: `friendRequests/{dari}_{ke}`.
/// - Daftar teman: `users/{uid}/teman/{uidTeman}`, ditulis untuk kedua
///   pihak saat permintaan diterima.
class FriendRepository {
  FriendRepository._();
  static final instance = FriendRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('friendRequests');

  /// Mencari pengguna berdasarkan awalan username, awalan sebutan, atau
  /// email lengkap.
  Future<List<AppUser>> search(String query, {required String myUid}) async {
    var q = query.trim().toLowerCase();
    if (q.startsWith('@')) q = q.substring(1);
    if (q.isEmpty) return const [];
    final results = <String, AppUser>{};
    final byUsername = await _users
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThan: '$q\uf8ff')
        .limit(20)
        .get();
    final bySebutan = await _users
        .where('sebutanLower', isGreaterThanOrEqualTo: q)
        .where('sebutanLower', isLessThan: '$q')
        .limit(20)
        .get();
    final byEmail = q.contains('@')
        ? (await _users.where('email', isEqualTo: query.trim()).limit(5).get()).docs
        : const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in [...byUsername.docs, ...bySebutan.docs, ...byEmail]) {
      if (doc.id == myUid) continue;
      results[doc.id] = AppUser.fromMap(doc.id, doc.data());
    }
    return results.values.toList();
  }

  Stream<List<String>> watchFriends(String myUid) {
    return _users
        .doc(myUid)
        .collection('teman')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }

  /// Permintaan yang masuk ke saya (uid pengirim).
  Stream<List<String>> watchIncoming(String myUid) {
    return _requests
        .where('to', isEqualTo: myUid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['from'] as String).toList());
  }

  /// Permintaan yang saya kirim (uid tujuan).
  Stream<List<String>> watchOutgoing(String myUid) {
    return _requests
        .where('from', isEqualTo: myUid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['to'] as String).toList());
  }

  Future<void> sendRequest({required String from, required String to}) {
    return _requests.doc('${from}_$to').set({
      'from': from,
      'to': to,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelRequest({required String from, required String to}) {
    return _requests.doc('${from}_$to').delete();
  }

  /// Menerima permintaan dari [from]: keduanya menjadi teman.
  Future<void> accept({required String from, required String me}) {
    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();
    batch.set(_users.doc(me).collection('teman').doc(from), {'since': now});
    batch.set(_users.doc(from).collection('teman').doc(me), {'since': now});
    batch.delete(_requests.doc('${from}_$me'));
    return batch.commit();
  }

  Future<void> reject({required String from, required String me}) {
    return _requests.doc('${from}_$me').delete();
  }

  Future<void> unfriend({required String me, required String other}) {
    final batch = _db.batch();
    batch.delete(_users.doc(me).collection('teman').doc(other));
    batch.delete(_users.doc(other).collection('teman').doc(me));
    return batch.commit();
  }
}
