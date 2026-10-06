import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tugas.dart';

/// Baca/tulis tugas milik satu pengguna di `users/{uid}/tugas`.
class TugasRepository {
  TugasRepository._();
  static final instance = TugasRepository._();

  CollectionReference<Map<String, dynamic>> _koleksi(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('tugas');

  /// Semua tugas, urut dari deadline paling dekat.
  Stream<List<Tugas>> watch(String uid) {
    return _koleksi(uid).orderBy('deadline').snapshots().map(
          (snap) => [for (final d in snap.docs) Tugas.fromMap(d.id, d.data())],
        );
  }

  /// Menyimpan tugas. Tugas baru (id kosong) dibuatkan id. Mengembalikan tugas tersimpan.
  Future<Tugas> save(String uid, Tugas tugas) async {
    if (tugas.id.isEmpty) {
      final ref = _koleksi(uid).doc();
      final baru = tugas.copyWith(id: ref.id);
      await ref.set({...baru.toMap(), 'createdAt': FieldValue.serverTimestamp()});
      return baru;
    }
    await _koleksi(uid).doc(tugas.id).set(tugas.toMap(), SetOptions(merge: true));
    return tugas;
  }

  Future<void> setStatus(String uid, String id, StatusTugas status) {
    return _koleksi(uid).doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String uid, String id) => _koleksi(uid).doc(id).delete();
}
