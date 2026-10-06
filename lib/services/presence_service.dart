import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

/// Menulis status online/offline pengguna ke `users/{uid}` (online, lastSeen)
/// mengikuti apakah aplikasi sedang dibuka. Bisa dimatikan di pengaturan
/// privasi; jika dimatikan, orang lain tidak melihat status online kita.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final instance = PresenceService._();

  String? _uid;
  bool _tampil = true;
  bool _aktif = false;
  String? _terakhir;
  Timer? _detak;

  void start(String uid, {required bool tampil}) {
    if (_uid == uid) {
      setTampil(tampil);
      return;
    }
    if (_uid == null) WidgetsBinding.instance.addObserver(this);
    _uid = uid;
    _tampil = tampil;
    _terakhir = null;
    _tulis(true);
  }

  void setTampil(bool tampil) {
    if (_tampil == tampil) return;
    _tampil = tampil;
    _tulis(_aktif);
  }

  /// Dipanggil saat keluar dari akun.
  Future<void> stop() async {
    final uid = _uid;
    if (uid == null) return;
    await _tulis(false);
    WidgetsBinding.instance.removeObserver(this);
    _uid = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _tulis(state == AppLifecycleState.resumed);
  }

  Future<void> _tulis(bool aktif) async {
    final uid = _uid;
    if (uid == null) return;
    _aktif = aktif;
    _detak?.cancel();
    final kunci = '$_tampil|$aktif';
    if (!_tampil) {
      if (_terakhir == kunci) return;
      _terakhir = kunci;
      await _update(uid, {'online': false, 'lastSeen': FieldValue.delete()});
      return;
    }
    _terakhir = kunci;
    await _update(uid, {'online': aktif, 'lastSeen': FieldValue.serverTimestamp()});
    // Selama aplikasi dibuka, perbarui berkala agar status tidak dianggap basi.
    if (aktif) _detak = Timer(const Duration(minutes: 2), () => _tulis(true));
  }

  Future<void> _update(String uid, Map<String, Object> data) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
    } catch (_) {
      // Offline: dicoba lagi pada perubahan berikutnya.
    }
  }
}
