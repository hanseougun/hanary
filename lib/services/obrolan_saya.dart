import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Pengaturan pribadi saya untuk satu chat: `users/{me}/obrolan/{chatId}`.
/// Hanya bisa dibaca dan diubah oleh saya sendiri.
class StatusObrolan {
  const StatusObrolan({
    this.disematkan,
    this.arsip = false,
    this.hapusSebelum,
    this.bintang = const [],
  });

  /// Kapan chat disematkan di atas daftar (null = tidak disematkan).
  final DateTime? disematkan;

  /// Chat dipindah ke "Diarsipkan".
  final bool arsip;

  /// Obrolan dihapus untuk saya: pesan sampai waktu ini disembunyikan, dan
  /// chat baru muncul lagi di daftar jika ada pesan baru.
  final DateTime? hapusSebelum;

  /// Id pesan yang saya beri bintang.
  final List<String> bintang;

  static const kosong = StatusObrolan();

  factory StatusObrolan.dari(Map<String, dynamic> d) {
    return StatusObrolan(
      disematkan: d['disematkan'] is Timestamp ? (d['disematkan'] as Timestamp).toDate() : null,
      arsip: d['arsip'] == true,
      hapusSebelum: d['hapusSebelum'] is Timestamp ? (d['hapusSebelum'] as Timestamp).toDate() : null,
      bintang: List<String>.from(d['bintang'] as List? ?? const []),
    );
  }

  /// Chat masih "terhapus" (belum ada pesan baru setelah dihapus).
  bool tersembunyi(DateTime? pesanTerakhir) {
    final h = hapusSebelum;
    if (h == null) return false;
    return pesanTerakhir == null || !pesanTerakhir.isAfter(h);
  }

  /// Pesan pada [waktu] sudah ikut terhapus.
  bool pesanTerhapus(DateTime? waktu) {
    final h = hapusSebelum;
    return h != null && waktu != null && !waktu.isAfter(h);
  }
}

/// Sematkan, arsipkan, hapus obrolan, dan bintang pesan (khusus untuk saya).
class ObrolanSaya extends ChangeNotifier {
  ObrolanSaya._();
  static final instance = ObrolanSaya._();

  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;
  Map<String, StatusObrolan> _semua = const {};

  /// Maksimal chat yang bisa disematkan.
  static const maksSemat = 3;

  CollectionReference<Map<String, dynamic>> _koleksi(String uid) =>
      _db.collection('users').doc(uid).collection('obrolan');

  Map<String, StatusObrolan> get semua => _semua;

  StatusObrolan dari(String chatId) => _semua[chatId] ?? StatusObrolan.kosong;

  /// Mulai memantau pengaturan obrolan [uid].
  void mulai(String uid) {
    if (_uid == uid) return;
    _sub?.cancel();
    _uid = uid;
    _semua = const {};
    _sub = _koleksi(uid).snapshots().listen((s) {
      _semua = {for (final d in s.docs) d.id: StatusObrolan.dari(d.data())};
      notifyListeners();
    }, onError: (Object e) => debugPrint('Gagal memuat pengaturan obrolan: $e'));
  }

  void berhenti() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    _semua = const {};
  }

  Future<void> sematkan(String me, String chatId, bool aktif) async {
    if (aktif && _semua.values.where((s) => s.disematkan != null).length >= maksSemat) {
      throw StateError('Maksimal $maksSemat chat yang bisa disematkan.');
    }
    await _koleksi(me).doc(chatId).set(
      {'disematkan': aktif ? Timestamp.now() : FieldValue.delete()},
      SetOptions(merge: true),
    );
  }

  Future<void> arsipkan(String me, String chatId, bool aktif) {
    return _koleksi(me).doc(chatId).set({
      'arsip': aktif,
      // Chat yang diarsipkan tidak disematkan lagi.
      if (aktif) 'disematkan': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Menghapus seluruh obrolan untuk saya saja. Teman tetap melihat pesannya.
  Future<void> hapusObrolan(String me, String chatId) {
    return _koleksi(me).doc(chatId).set({
      'hapusSebelum': Timestamp.now(),
      'disematkan': FieldValue.delete(),
      'arsip': false,
      'bintang': <String>[],
    }, SetOptions(merge: true));
  }

  Future<void> beriBintang(String me, String chatId, String pesanId, bool aktif) {
    return _koleksi(me).doc(chatId).set({
      'bintang': aktif ? FieldValue.arrayUnion([pesanId]) : FieldValue.arrayRemove([pesanId]),
    }, SetOptions(merge: true));
  }
}
