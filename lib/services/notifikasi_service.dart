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

  final _plugin = FlutterLocalNotificationsPlugin();
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
      );
      _siap = true;
    } catch (e) {
      debugPrint('Notifikasi tidak bisa disiapkan: $e');
    }
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
