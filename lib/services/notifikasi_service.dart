import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/tugas.dart';

/// Notifikasi pengingat tugas yang dijadwalkan di HP (tidak butuh internet):
/// muncul sehari sebelum deadline untuk tugas yang belum selesai.
class NotifikasiService {
  NotifikasiService._();
  static final instance = NotifikasiService._();

  static const _prefix = 'tugas:';
  static const _detail = NotificationDetails(
    android: AndroidNotificationDetails(
      'deadline_tugas',
      'Pengingat deadline',
      channelDescription: 'Pengingat sehari sebelum deadline tugas',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static const _detailChat = NotificationDetails(
    android: AndroidNotificationDetails(
      'pesan_chat',
      'Pesan chat',
      channelDescription: 'Pesan baru dari teman dan grup',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
    ),
  );

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Id chat dari notifikasi yang baru saja diketuk (untuk dibuka).
  final ketukChat = ValueNotifier<String?>(null);
  bool _siap = false;
  Future<void> _antrean = Future.value();

  Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final zona = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zona.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (r) => _diketuk(r.payload),
      );
      _siap = true;
      final awal = await _plugin.getNotificationAppLaunchDetails();
      if (awal?.didNotificationLaunchApp ?? false) {
        _diketuk(awal!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('Notifikasi tidak bisa disiapkan: $e');
    }
  }

  void _diketuk(String? payload) {
    if (payload != null && payload.startsWith(_prefixChat)) {
      ketukChat.value = payload.substring(_prefixChat.length);
    }
  }

  static const _prefixChat = 'chat:';

  /// Menampilkan notifikasi pesan chat. Satu notifikasi per ruang chat;
  /// pesan baru menggantikan notifikasi lama dari chat yang sama.
  Future<void> tampilkanChat({required String chatId, required String judul, required String isi}) async {
    if (!_siap) return;
    await _plugin.show(
      id: idNotifikasi('$_prefixChat$chatId'),
      title: judul,
      body: isi,
      notificationDetails: _detailChat,
      payload: '$_prefixChat$chatId',
    );
  }

  /// Menghapus notifikasi chat saat chat-nya dibuka.
  Future<void> hapusChat(String chatId) async {
    if (!_siap) return;
    await _plugin.cancel(id: idNotifikasi('$_prefixChat$chatId'));
  }

  /// Meminta izin menampilkan notifikasi (Android 13 ke atas).
  Future<void> mintaIzin() async {
    if (!_siap) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Menyamakan jadwal notifikasi dengan daftar tugas terbaru.
  /// Dipanggil setiap kali daftar tugas berubah, jadi tugas yang diedit,
  /// diselesaikan, atau dihapus otomatis ikut diperbarui pengingatnya.
  Future<void> sinkron(List<Tugas> semua) {
    if (!_siap) return Future.value();
    return _antrean = _antrean.then((_) => _sinkron(semua)).catchError((Object e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    });
  }

  Future<void> _sinkron(List<Tugas> semua) async {
    final sekarang = DateTime.now();
    final terjadwal = await _plugin.pendingNotificationRequests();
    for (final n in terjadwal) {
      if (n.payload?.startsWith(_prefix) ?? false) await _plugin.cancel(id: n.id);
    }
    final format = DateFormat('EEEE, d MMM, HH:mm', 'id_ID');
    for (final t in semua) {
      if (t.status == StatusTugas.selesai || !t.waktuPengingat.isAfter(sekarang)) continue;
      await _plugin.zonedSchedule(
        id: idNotifikasi(t.id),
        title: 'Besok deadline: ${t.judul}',
        body: [
          if (t.mapel.isNotEmpty) t.mapel,
          'Deadline ${format.format(t.deadline)}',
          'Status: ${t.status.label}',
        ].join(' · '),
        scheduledDate: tz.TZDateTime.from(t.waktuPengingat, tz.local),
        notificationDetails: _detail,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$_prefix${t.id}',
      );
    }
  }

  /// Angka id notifikasi yang tetap untuk setiap id tugas.
  @visibleForTesting
  static int idNotifikasi(String idTugas) {
    var hash = 0x811c9dc5;
    for (final c in idTugas.codeUnits) {
      hash = ((hash ^ c) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
