import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import '../models/chat_payload.dart';
import '../models/chat_room.dart';
import 'chat_repository.dart';
import 'chat_settings.dart';
import 'notifikasi_service.dart';
import 'user_directory.dart';

/// Notifikasi pesan chat yang masuk.
///
/// - Saat aplikasi dibuka atau masih berjalan di belakang: memantau daftar
///   chat secara langsung.
/// - Saat aplikasi ditutup: Android menjalankan [chatCallbackDispatcher]
///   kira-kira setiap 15 menit untuk memeriksa pesan baru. Pemeriksaan ini
///   hanya membaca satu dokumen `inbox/{uid}` kecuali memang ada pesan baru.
class ChatNotifier {
  ChatNotifier._();
  static final instance = ChatNotifier._();

  static const _tugasLatar = 'hanary-cek-chat';

  /// Chat yang sedang dibuka di layar (tidak perlu notifikasi).
  String? openChatId;

  StreamSubscription<List<ChatRoom>>? _sub;
  String? _uid;
  Future<void> _antrean = Future.value();

  /// Mendaftarkan pemeriksaan latar belakang. Dipanggil sekali di main().
  static Future<void> daftarLatar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Workmanager().initialize(chatCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        _tugasLatar,
        'cekChat',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('Pemeriksaan chat di latar belakang tidak bisa didaftarkan: $e');
    }
  }

  void start(String uid) {
    if (_uid == uid) return;
    _sub?.cancel();
    _uid = uid;
    _sub = ChatRepository.instance.watchRooms(uid).listen(
          (rooms) => _antrean = _antrean.then((_) => _proses(uid, rooms)).catchError((Object _) {}),
          onError: (_) {},
        );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
  }

  /// Pemeriksaan sekali jalan (dipakai di latar belakang).
  Future<void> cekSekali(String uid) async {
    if (!await ChatSettings.notifAktif()) return;
    final prefs = await SharedPreferences.getInstance();
    final terakhir = prefs.getInt(_kunci(uid));
    final db = FirebaseFirestore.instance;
    final inbox = await db.collection('inbox').doc(uid).get(const GetOptions(source: Source.server));
    final at = (inbox.data()?['at'] as Timestamp?)?.millisecondsSinceEpoch;
    if (terakhir != null && (at == null || at <= terakhir)) return;
    final snap = await db
        .collection('chats')
        .where('members', arrayContains: uid)
        .get(const GetOptions(source: Source.server));
    await _proses(uid, snap.docs.map(ChatRoom.fromSnapshot).toList());
  }

  static String _kunci(String uid) => 'chat_notif_terakhir_$uid';

  Future<void> _proses(String uid, List<ChatRoom> rooms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final kunci = _kunci(uid);
    final terakhir = prefs.getInt(kunci);
    var terbaru = terakhir ?? 0;
    for (final r in rooms) {
      final t = r.updatedAt?.millisecondsSinceEpoch;
      if (t != null && t > terbaru) terbaru = t;
    }
    if (terakhir == null) {
      // Pertama kali: jangan memunculkan notifikasi untuk pesan lama.
      await prefs.setInt(kunci, terbaru);
      return;
    }
    if (terbaru <= terakhir) return;
    await prefs.setInt(kunci, terbaru);
    if (!(prefs.getBool(ChatSettings.kunciNotif) ?? true)) return;
    for (final r in rooms) {
      final t = r.updatedAt?.millisecondsSinceEpoch;
      if (t == null || t <= terakhir) continue;
      if (r.lastSender == null || r.lastSender == uid || r.id == openChatId) continue;
      if (r.status == ChatStatus.ditolak) continue;
      try {
        await _tampilkan(uid, r);
      } catch (e) {
        debugPrint('Gagal menampilkan notifikasi chat: $e');
      }
    }
  }

  Future<void> _tampilkan(String uid, ChatRoom room) async {
    final pengirim = await UserDirectory.instance.get(room.lastSender!);
    final nama = pengirim == null
        ? 'Seseorang'
        : (pengirim.sebutan.isNotEmpty ? pengirim.sebutan : pengirim.namaLengkap);
    var isi = 'Pesan baru';
    try {
      final key = await ChatRepository.instance.roomKey(room, uid).timeout(const Duration(seconds: 10));
      final box = room.lastBox;
      if (room.lastKind == lastKindDitarik) {
        isi = 'Pesan ditarik';
      } else if (key != null && box != null) {
        final pesan = await ChatRepository.instance
            .decryptIsi(room.id, MessageKind.dari(room.lastKind), box, key);
        if (pesan != null) isi = pesan.ringkas();
      }
    } catch (_) {
      // Tampilkan tanpa isi pesan.
    }
    if (room.isIncomingRequest(uid)) {
      await NotifikasiService.instance.tampilkanChat(
        chatId: room.id,
        judul: 'Permintaan pesan dari $nama',
        isi: isi,
      );
    } else if (room.isGroup) {
      await NotifikasiService.instance.tampilkanChat(chatId: room.id, judul: room.name, isi: '$nama: $isi');
    } else {
      await NotifikasiService.instance.tampilkanChat(chatId: room.id, judul: nama, isi: isi);
    }
  }
}

/// Dijalankan Android di latar belakang (lihat [ChatNotifier.daftarLatar]).
@pragma('vm:entry-point')
void chatCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      await NotifikasiService.instance.init();
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 10), onTimeout: () => FirebaseAuth.instance.currentUser);
      if (user != null) await ChatNotifier.instance.cekSekali(user.uid);
    } catch (e) {
      debugPrint('Pemeriksaan chat gagal: $e');
    }
    return true;
  });
}
