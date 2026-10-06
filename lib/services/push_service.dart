import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import 'chat_notifier.dart';
import 'notifikasi_service.dart';
import 'panggilan_service.dart';

/// Notifikasi instan lewat Firebase Cloud Messaging (FCM).
///
/// Setelah mengirim pesan atau memulai panggilan, HP pengirim meminta
/// server kecil "hanary-notif" (Cloudflare Worker, lihat folder
/// `server/notif-worker`) untuk membangunkan HP penerima. Server hanya
/// mengirim "ada pesan di chat X"; isi pesan tetap terenkripsi dan dibuka
/// di HP penerima, lalu ditampilkan sebagai notifikasi.
///
/// Jika alamat server belum diatur (NOTIF_URL kosong), aplikasi tetap
/// memakai pemeriksaan berkala lama (sekitar 15 menit).
class PushService {
  PushService._();
  static final instance = PushService._();

  /// Alamat server notifikasi, diisi saat APK dibangun di GitHub Actions.
  static const alamatServer = String.fromEnvironment('NOTIF_URL');

  static bool get aktif => alamatServer.isNotEmpty;

  String? _uid;
  StreamSubscription<String>? _subToken;

  /// Mendaftarkan HP ini agar bisa dibangunkan. Dipanggil setelah login.
  Future<void> mulai(String uid) async {
    if (kIsWeb || _uid == uid) return;
    _uid = uid;
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.setAutoInitEnabled(true);
      final token = await fcm.getToken();
      if (token != null) await _simpanToken(uid, token);
      await _subToken?.cancel();
      _subToken = fcm.onTokenRefresh.listen((t) => _simpanToken(uid, t));
    } catch (e) {
      debugPrint('Pendaftaran notifikasi instan gagal: $e');
    }
  }

  Future<void> _simpanToken(String uid, String token) {
    return FirebaseFirestore.instance.collection('fcmTokens').doc(uid).set({
      'token': token,
      'diperbarui': FieldValue.serverTimestamp(),
    });
  }

  /// Saat logout: HP ini tidak lagi menerima notifikasi akun tersebut.
  Future<void> berhenti() async {
    final uid = _uid;
    _uid = null;
    await _subToken?.cancel();
    _subToken = null;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('fcmTokens').doc(uid).delete();
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  /// Meminta server membangunkan anggota lain di chat ini.
  /// Tidak pernah melempar error: kalau gagal, pemeriksaan berkala tetap jalan.
  /// [ke]: untuk `jenis: 'undang'`, uid orang yang diajak ke panggilan.
  Future<void> beriTahu({required String chatId, String jenis = 'pesan', String? callId, String? ke}) async {
    if (!aktif) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null) return;
      await http
          .post(
            Uri.parse('$alamatServer/kirim'),
            headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
            body: jsonEncode({
              'chatId': chatId,
              'jenis': jenis,
              if (callId != null) 'callId': callId,
              if (ke != null) 'ke': ke,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Notifikasi instan tidak terkirim: $e');
    }
  }
}

/// Dijalankan Android saat pesan FCM tiba dan aplikasi di latar belakang
/// atau tertutup. Didaftarkan di main().
@pragma('vm:entry-point')
Future<void> pushLatar(RemoteMessage pesan) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    await NotifikasiService.instance.init();
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 10), onTimeout: () => FirebaseAuth.instance.currentUser);
    if (user == null) return;
    await prosesPush(user.uid, pesan.data);
  } catch (e) {
    debugPrint('Pesan FCM gagal diproses: $e');
  }
}

/// Menangani isi pesan FCM (di latar belakang maupun saat aplikasi terbuka).
Future<void> prosesPush(String uid, Map<String, dynamic> data) async {
  switch (data['jenis']) {
    case 'pesan':
      await ChatNotifier.instance.cekSekali(uid, paksa: true);
    case 'panggilan':
      final callId = data['callId'] as String?;
      if (callId != null) await PanggilanService.tampilkanNotifMasuk(uid, callId);
  }
}
