import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/bahasa.dart';
import '../models/tugas.dart';
import 'jadwal_pengingat.dart';
import 'panggilan_service.dart';
import 'pengaturan_notif.dart';

/// Notifikasi pengingat tugas yang dijadwalkan di HP (tidak butuh internet).
/// Selama tugas belum Selesai: tiap hari jam 12.00 dan 18.00, lalu 1 jam,
/// 30, 15, dan 5 menit sebelum deadline, dan pemberitahuan saat deadline
/// terlewat. Jadwalnya dihitung di [hitungPengingat].
class NotifikasiService {
  NotifikasiService._();
  static final instance = NotifikasiService._();

  static const _prefix = 'tugas:';
  static const _prefixPanggilan = 'panggilan:';

  /// Bendera Android FLAG_INSISTENT: suara diulang sampai notifikasi dilihat.
  static const _flagBerulang = 4;

  /// Detail notifikasi sesuai setelan suara/getar/durasi pilihan pengguna
  /// (lihat Pengaturan → Suara notifikasi).
  static Future<NotificationDetails> detailUntuk(
    JenisNotif jenis, {
    StyleInformation? gaya,
  }) async {
    final s = await PengaturanNotif.baca(jenis);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        s.saluran(jenis),
        jenis.namaSaluran,
        channelDescription: jenis.deskripsi,
        importance: Importance.high,
        priority: Priority.high,
        category: jenis == JenisNotif.chat ? AndroidNotificationCategory.message : AndroidNotificationCategory.reminder,
        playSound: s.suara != SetelanNotif.suaraSenyap,
        sound: s.nadaSendiri ? UriAndroidNotificationSound(s.suara) : null,
        enableVibration: s.getar,
        additionalFlags: s.berulang ? Int32List.fromList([_flagBerulang]) : null,
        timeoutAfter: s.tampilMenit > 0 ? s.tampilMenit * 60 * 1000 : null,
        styleInformation: gaya,
      ),
    );
  }

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Id chat dari notifikasi yang baru saja diketuk (untuk dibuka).
  final ketukChat = ValueNotifier<String?>(null);

  /// Panggilan masuk yang diketuk/diterima dari notifikasi: (id panggilan, terima?).
  final ketukPanggilan = ValueNotifier<(String, bool)?>(null);
  bool _siap = false;
  bool _tepat = false;
  Future<void> _antrean = Future.value();

  Future<void> init() async {
    // Notifikasi juga disusun di proses latar, jadi bahasa dibaca di sini.
    await PengaturanBahasa.instance.muat();
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
        onDidReceiveNotificationResponse: (r) => _diketuk(r.payload, r.actionId),
        onDidReceiveBackgroundNotificationResponse: notifikasiDiketukLatar,
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
        _diketuk(awal!.notificationResponse?.payload, awal.notificationResponse?.actionId);
      }
    } catch (e) {
      debugPrint('Notifikasi tidak bisa disiapkan: $e');
    }
  }

  void _diketuk(String? payload, [String? aksi]) {
    if (payload == null) return;
    if (payload.startsWith(_prefixChat)) {
      ketukChat.value = payload.substring(_prefixChat.length);
    } else if (payload.startsWith(_prefixPanggilan)) {
      final id = payload.substring(_prefixPanggilan.length);
      if (aksi == aksiTolak) {
        tolakPanggilanLatar(id);
      } else {
        ketukPanggilan.value = (id, aksi == aksiTerima);
      }
    }
  }

  static const aksiTerima = 'terima';
  static const aksiTolak = 'tolak';

  /// Notifikasi panggilan masuk: berdering terus (nada dering HP) dengan
  /// tombol Terima/Tolak, dan muncul layar penuh saat HP terkunci.
  Future<void> tampilkanPanggilan({
    required String callId,
    required String judul,
    required bool video,
  }) async {
    if (!_siap) return;
    await _plugin.show(
      id: idNotifikasi('$_prefixPanggilan$callId'),
      title: judul,
      body: video ? tr('Panggilan video masuk') : tr('Panggilan suara masuk'),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'panggilan_masuk',
          tr('Panggilan masuk'),
          channelDescription: tr('Panggilan suara dan video dari teman dan grup'),
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          sound: const UriAndroidNotificationSound('content://settings/system/ringtone'),
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          additionalFlags: Int32List.fromList([_flagBerulang]),
          timeoutAfter: 45000,
          actions: [
            AndroidNotificationAction(aksiTolak, tr('Tolak'), titleColor: const Color(0xFFDC2626)),
            AndroidNotificationAction(aksiTerima, tr('Terima'),
                titleColor: const Color(0xFF16A34A), showsUserInterface: true),
          ],
        ),
      ),
      payload: '$_prefixPanggilan$callId',
    );
  }

  Future<void> hapusPanggilan(String callId) async {
    if (!_siap) return;
    await _plugin.cancel(id: idNotifikasi('$_prefixPanggilan$callId'));
  }

  /// Dipanggil setelah setelan suara diubah: saluran lama dihapus, dan
  /// pengingat tugas dijadwalkan ulang dengan suara baru.
  Future<void> terapkanSetelan(JenisNotif jenis) async {
    if (!_siap) return;
    final sekarang = (await PengaturanNotif.baca(jenis)).saluran(jenis);
    final semua = await _android?.getNotificationChannels() ?? const [];
    for (final c in semua) {
      if (c.id != sekarang && (c.id == jenis.saluranDasar || c.id.startsWith('${jenis.saluranDasar}_'))) {
        await _android?.deleteNotificationChannel(channelId: c.id);
      }
    }
    if (jenis == JenisNotif.tugas) await jadwalUlang();
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
      notificationDetails: await detailUntuk(JenisNotif.chat),
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
    final detailBiasa = await detailUntuk(JenisNotif.tugas);
    final jam = DateFormat('HH:mm', kodeTanggal);
    final tanggal = DateFormat('EEEE, d MMM, HH:mm', kodeTanggal);
    for (final p in hitungPengingat(semua, sekarang)) {
      final t = p.tugas.first;
      String judul;
      String isi;
      var detail = detailBiasa;
      switch (p.jenis) {
        case JenisPengingat.menjelang:
          judul = p.menitSebelum >= 60
              ? tr('{n} jam lagi deadline: {judul}', {'n': p.menitSebelum ~/ 60, 'judul': t.judul})
              : tr('{n} menit lagi deadline: {judul}', {'n': p.menitSebelum, 'judul': t.judul});
          isi = [
            if (t.mapel.isNotEmpty) t.mapel,
            tr('Dikumpulkan jam {jam}', {'jam': jam.format(t.deadline)}),
            tr('Status: {status}', {'status': t.status.labelTr}),
          ].join(' · ');
        case JenisPengingat.terlewat:
          judul = tr('Deadline terlewat: {judul}', {'judul': t.judul});
          isi = tr('Tugas ini belum ditandai Selesai. Segera kumpulkan, lalu ubah statusnya ya.');
        case JenisPengingat.harian:
          String baris(Tugas x) =>
              tr('{judul} · sisa {sisa}', {'judul': x.judul, 'sisa': teksSisa(x.deadline.difference(p.waktu))});
          if (p.tugas.length == 1) {
            judul = tr('Jangan lupa: {judul}', {'judul': t.judul});
            isi = [
              if (t.mapel.isNotEmpty) t.mapel,
              tr('Deadline {waktu}', {'waktu': tanggal.format(t.deadline)}),
              tr('sisa {sisa}', {'sisa': teksSisa(t.deadline.difference(p.waktu))}),
            ].join(' · ');
          } else {
            final daftar = p.tugas.map(baris).toList();
            judul = tr('{n} tugas belum selesai', {'n': p.tugas.length});
            isi = daftar.join('\n');
            detail = await detailUntuk(
              JenisNotif.tugas,
              gaya: InboxStyleInformation(
                daftar.take(6).toList(),
                summaryText: daftar.length > 6 ? tr('+{n} tugas lagi', {'n': daftar.length - 6}) : null,
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

/// Tombol notifikasi yang ditekan saat aplikasi tertutup (mis. "Tolak"
/// panggilan). Dijalankan Android di latar belakang.
@pragma('vm:entry-point')
void notifikasiDiketukLatar(NotificationResponse r) {
  final payload = r.payload ?? '';
  if (r.actionId == NotifikasiService.aksiTolak && payload.startsWith('panggilan:')) {
    tolakPanggilanLatar(payload.substring('panggilan:'.length));
  }
}
