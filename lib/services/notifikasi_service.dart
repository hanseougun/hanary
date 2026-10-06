import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/tugas.dart';
import 'jadwal_pengingat.dart';

/// Notifikasi pengingat tugas yang dijadwalkan di HP (tidak butuh internet).
/// Selama tugas belum Selesai: tiap hari jam 12.00 dan 18.00, lalu 1 jam,
/// 30, 15, dan 5 menit sebelum deadline, dan pemberitahuan saat deadline
/// terlewat. Jadwalnya dihitung di [hitungPengingat].
class NotifikasiService {
  NotifikasiService._();
  static final instance = NotifikasiService._();

  static const _prefix = 'tugas:';
  static const _detail = NotificationDetails(
    android: AndroidNotificationDetails(
      'deadline_tugas',
      'Pengingat deadline',
      channelDescription: 'Pengingat harian dan menjelang deadline tugas',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
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
  bool _tepat = false;
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
      _tepat = await _android?.canScheduleExactNotifications() ?? false;
      // Jika izin alarm tepat waktu baru diberikan (atau dicabut) di
      // pengaturan HP, jadwal pengingat disusun ulang saat kembali ke aplikasi.
      AppLifecycleListener(onResume: () async {
        final tepat = await _android?.canScheduleExactNotifications() ?? false;
        if (tepat != _tepat) {
          _tepat = tepat;
          await jadwalUlang();
        }
      });
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

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static const _kunciTanyaAlarm = 'izin_alarm_tepat_ditanya';

  /// True jika HP belum mengizinkan alarm tepat waktu dan pengguna belum
  /// pernah ditawari. Tanpa izin ini, pengingat 5 menit bisa telat beberapa menit.
  Future<bool> perluTawarkanAlarmTepat() async {
    if (!_siap) return false;
    final bisa = await _android?.canScheduleExactNotifications() ?? true;
    if (bisa) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kunciTanyaAlarm) ?? false);
  }

  /// Membuka pengaturan "Alarm & pengingat" (hanya ditawarkan sekali).
  Future<void> mintaIzinAlarmTepat({bool buka = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kunciTanyaAlarm, true);
    if (buka) await _android?.requestExactAlarmsPermission();
  }

  /// Menyamakan jadwal notifikasi dengan daftar tugas terbaru.
  /// Dipanggil setiap kali daftar tugas berubah, jadi tugas yang diedit,
  /// diselesaikan, atau dihapus otomatis ikut diperbarui pengingatnya.
  Future<void> sinkron(List<Tugas> semua) {
    if (!_siap) return Future.value();
    _terakhir = semua;
    return _antrean = _antrean.then((_) => _sinkron(semua)).catchError((Object e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    });
  }

  List<Tugas>? _terakhir;

  /// Menjadwalkan ulang dengan daftar tugas terakhir (mis. setelah izin
  /// alarm tepat waktu diberikan).
  Future<void> jadwalUlang() async {
    final t = _terakhir;
    if (t != null) await sinkron(t);
  }

  Future<void> _sinkron(List<Tugas> semua) async {
    final sekarang = DateTime.now();
    final terjadwal = await _plugin.pendingNotificationRequests();
    for (final n in terjadwal) {
      if (n.payload?.startsWith(_prefix) ?? false) await _plugin.cancel(id: n.id);
    }
    // Tugas yang baru diselesaikan: hapus juga notifikasi "terlewat" yang
    // mungkin masih tampil di HP.
    for (final t in semua) {
      if (t.status == StatusTugas.selesai &&
          t.deadline.isBefore(sekarang) &&
          sekarang.difference(t.deadline) < const Duration(days: 7)) {
        await _plugin.cancel(id: idNotifikasi('${t.id}:lewat'));
      }
    }

    final tepat = _tepat = await _android?.canScheduleExactNotifications() ?? false;
    final jam = DateFormat('HH:mm', 'id_ID');
    final tanggal = DateFormat('EEEE, d MMM, HH:mm', 'id_ID');
    for (final p in hitungPengingat(semua, sekarang)) {
      final t = p.tugas.first;
      String judul;
      String isi;
      var detail = _detail;
      switch (p.jenis) {
        case JenisPengingat.menjelang:
          final lagi = p.menitSebelum >= 60 ? '${p.menitSebelum ~/ 60} jam' : '${p.menitSebelum} menit';
          judul = '$lagi lagi deadline: ${t.judul}';
          isi = [
            if (t.mapel.isNotEmpty) t.mapel,
            'Dikumpulkan jam ${jam.format(t.deadline)}',
            'Status: ${t.status.label}',
          ].join(' · ');
        case JenisPengingat.terlewat:
          judul = 'Deadline terlewat: ${t.judul}';
          isi = 'Tugas ini belum ditandai Selesai. Segera kumpulkan, lalu ubah statusnya ya.';
        case JenisPengingat.harian:
          String baris(Tugas x) => '${x.judul} · sisa ${teksSisa(x.deadline.difference(p.waktu))}';
          if (p.tugas.length == 1) {
            judul = 'Jangan lupa: ${t.judul}';
            isi = [
              if (t.mapel.isNotEmpty) t.mapel,
              'Deadline ${tanggal.format(t.deadline)}',
              'sisa ${teksSisa(t.deadline.difference(p.waktu))}',
            ].join(' · ');
          } else {
            final daftar = p.tugas.map(baris).toList();
            judul = '${p.tugas.length} tugas belum selesai';
            isi = daftar.join('\n');
            detail = NotificationDetails(
              android: AndroidNotificationDetails(
                'deadline_tugas',
                'Pengingat deadline',
                channelDescription: 'Pengingat harian dan menjelang deadline tugas',
                importance: Importance.high,
                priority: Priority.high,
                category: AndroidNotificationCategory.reminder,
                styleInformation: InboxStyleInformation(
                  daftar.take(6).toList(),
                  summaryText: daftar.length > 6 ? '+${daftar.length - 6} tugas lagi' : null,
                ),
              ),
            );
          }
      }
      // Pengingat menjelang dan terlewat perlu tepat waktu; harian boleh
      // bergeser sedikit agar hemat baterai.
      final mode = tepat && p.jenis != JenisPengingat.harian
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      await _plugin.zonedSchedule(
        id: idNotifikasi(p.kunci),
        title: judul,
        body: isi,
        scheduledDate: tz.TZDateTime.from(p.waktu, tz.local),
        notificationDetails: detail,
        androidScheduleMode: mode,
        payload: '$_prefix${p.kunci}',
      );
    }
  }

  /// Angka id notifikasi yang tetap untuk setiap kunci pengingat.
  @visibleForTesting
  static int idNotifikasi(String idTugas) {
    var hash = 0x811c9dc5;
    for (final c in idTugas.codeUnits) {
      hash = ((hash ^ c) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
