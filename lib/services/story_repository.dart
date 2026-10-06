import 'package:cloud_firestore/cloud_firestore.dart';

/// Story catatan: teks singkat yang tampil sebagai gelembung di atas foto
/// profil di daftar chat, terlihat oleh teman selama 24 jam.
/// Disimpan di `stories/{uid}`; hanya teman yang bisa membacanya.
class StoryCatatan {
  const StoryCatatan({required this.uid, required this.teks, required this.warna, required this.dibuat});

  final String uid;
  final String teks;

  /// Indeks warna latar (lihat [warnaStory] di layar story).
  final int warna;
  final DateTime dibuat;

  static const masaBerlaku = Duration(hours: 24);

  bool get masihBerlaku => DateTime.now().difference(dibuat) < masaBerlaku;

  static StoryCatatan? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data();
    final dibuat = (d?['dibuat'] as Timestamp?)?.toDate();
    final teks = d?['teks'] as String? ?? '';
    if (d == null || teks.isEmpty) return null;
    final story = StoryCatatan(
      uid: snap.id,
      teks: teks,
      warna: (d['warna'] as num?)?.toInt() ?? 0,
      // Waktu masih null sesaat setelah menulis (menunggu server).
      dibuat: dibuat ?? DateTime.now(),
    );
    return story.masihBerlaku ? story : null;
  }
}

class StoryRepository {
  StoryRepository._();
  static final instance = StoryRepository._();

  final _stories = FirebaseFirestore.instance.collection('stories');

  /// Story milik [uid], atau null jika tidak ada / sudah lewat 24 jam
  /// / bukan teman (tidak boleh dibaca).
  Stream<StoryCatatan?> watch(String uid) {
    return _stories.doc(uid).snapshots().map(StoryCatatan.fromSnapshot).handleError((Object _) {});
  }

  Future<void> simpan(String uid, String teks, int warna) {
    return _stories.doc(uid).set({
      'teks': teks.trim(),
      'warna': warna,
      'dibuat': FieldValue.serverTimestamp(),
    });
  }

  Future<void> hapus(String uid) => _stories.doc(uid).delete();
}
