import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../l10n/bahasa.dart';
import '../models/chat_room.dart';
import 'notifikasi_service.dart';
import 'push_service.dart';
import 'user_directory.dart';

/// Status panggilan di `panggilan/{id}`.
enum StatusPanggilan { berdering, berlangsung, selesai }

/// Satu panggilan suara/video. Suara dan gambar dikirim langsung antar HP
/// (WebRTC, terenkripsi); Firestore hanya dipakai untuk "berkenalan"
/// (sinyal) dan status panggilan.
class Panggilan {
  const Panggilan({
    required this.id,
    required this.chatId,
    required this.dari,
    required this.video,
    required this.grup,
    required this.anggota,
    required this.ikut,
    required this.tolak,
    required this.status,
    required this.dibuat,
    this.pernah = const [],
    this.mulai,
    this.selesai,
  });

  final String id;
  final String chatId;

  /// Uid yang memulai panggilan.
  final String dari;
  final bool video;
  final bool grup;

  /// Anggota chat yang dipanggil (termasuk pemanggil).
  final List<String> anggota;

  /// Yang sedang ada di dalam panggilan.
  final List<String> ikut;

  /// Yang menolak.
  final List<String> tolak;
  final StatusPanggilan status;
  final DateTime dibuat;

  /// Semua yang pernah masuk ke panggilan (untuk riwayat).
  final List<String> pernah;

  /// Kapan panggilan mulai tersambung dan kapan berakhir.
  final DateTime? mulai;
  final DateTime? selesai;

  /// Panggilan ini sudah diikuti lebih dari dua orang (diperlakukan seperti grup).
  bool get ramai => grup || anggota.length > 2;

  /// Lama bicara (null jika tidak pernah tersambung).
  Duration? get durasi {
    final m = mulai;
    final s = selesai;
    if (m == null || s == null || s.isBefore(m)) return null;
    return s.difference(m);
  }

  factory Panggilan.dari(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? const {};
    return Panggilan(
      id: s.id,
      chatId: d['chatId'] as String? ?? '',
      dari: d['dari'] as String? ?? '',
      video: d['video'] == true,
      grup: d['grup'] == true,
      anggota: List<String>.from(d['anggota'] as List? ?? const []),
      ikut: List<String>.from(d['ikut'] as List? ?? const []),
      tolak: List<String>.from(d['tolak'] as List? ?? const []),
      status: StatusPanggilan.values.firstWhere((x) => x.name == d['status'], orElse: () => StatusPanggilan.selesai),
      dibuat: DateTime.fromMillisecondsSinceEpoch((d['dibuatMs'] as num?)?.toInt() ?? 0),
      pernah: List<String>.from(d['pernah'] as List? ?? const []),
      mulai: _waktu(d['mulaiMs']),
      selesai: _waktu(d['selesaiMs']),
    );
  }

  static DateTime? _waktu(Object? ms) => ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null;

  /// Masih bisa diangkat oleh [uid]. [dipanggil]: kapan dia terakhir
  /// dipanggil/diajak (bawaan: saat panggilan dimulai).
  bool bisaDiangkat(String uid, {DateTime? dipanggil}) =>
      status != StatusPanggilan.selesai &&
      anggota.contains(uid) &&
      !ikut.contains(uid) &&
      !tolak.contains(uid) &&
      DateTime.now().difference(dipanggil ?? dibuat) < PanggilanService.batasBerdering + const Duration(seconds: 15);
}

/// Memulai, menerima, menolak, dan mengakhiri panggilan; serta memantau
/// panggilan masuk selama aplikasi terbuka.
class PanggilanService {
  PanggilanService._();
  static final instance = PanggilanService._();

  /// Berapa lama berdering sebelum dianggap tidak dijawab.
  static const batasBerdering = Duration(seconds: 45);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _koleksi => _db.collection('panggilan');

  /// Panggilan masuk yang perlu ditampilkan di layar (diisi saat ada yang
  /// menelepon dan aplikasi sedang terbuka).
  final masuk = ValueNotifier<Panggilan?>(null);

  /// Panggilan yang sedang dibuka di layar (agar tidak muncul dua kali).
  String? sedangDibuka;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;
  final _sudah = <String>{};

  /// Mulai memantau panggilan masuk untuk [uid].
  void mulai(String uid) {
    if (_uid == uid) return;
    _sub?.cancel();
    _uid = uid;
    _sub = _db.collection('panggilanMasuk').doc(uid).snapshots().listen((s) async {
      final callId = s.data()?['callId'] as String?;
      final at = s.data()?['at'];
      final dipanggil = at is Timestamp ? at.toDate() : null;
      // Satu panggilan bisa berdering lagi jika diajak ulang (waktu berbeda).
      final tanda = '$callId|${dipanggil?.millisecondsSinceEpoch}';
      if (callId == null || _sudah.contains(tanda) || callId == sedangDibuka) return;
      try {
        final p = await ambil(callId);
        if (p == null || !p.bisaDiangkat(uid, dipanggil: dipanggil)) return;
        _sudah.add(tanda);
        masuk.value = p;
      } catch (_) {}
    }, onError: (_) {});
  }

  void berhenti() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
  }

  Future<Panggilan?> ambil(String callId) async {
    final s = await _koleksi.doc(callId).get(const GetOptions(source: Source.server));
    return s.exists ? Panggilan.dari(s) : null;
  }

  Stream<Panggilan?> pantau(String callId) =>
      _koleksi.doc(callId).snapshots().map((s) => s.exists ? Panggilan.dari(s) : null);

  /// Memulai panggilan ke semua anggota chat. Mengembalikan id panggilan.
  Future<String> buat({required ChatRoom room, required String me, required bool video}) async {
    final ref = _koleksi.doc();
    final batch = _db.batch();
    batch.set(ref, {
      'chatId': room.id,
      'dari': me,
      'video': video,
      'grup': room.isGroup,
      'anggota': room.members,
      'ikut': [me],
      'pernah': [me],
      'tolak': <String>[],
      'status': StatusPanggilan.berdering.name,
      'dibuatMs': DateTime.now().millisecondsSinceEpoch,
      'dibuat': FieldValue.serverTimestamp(),
    });
    // Tanda untuk tiap anggota yang sedang membuka aplikasi.
    for (final m in room.members) {
      if (m == me) continue;
      batch.set(_db.collection('panggilanMasuk').doc(m), {
        'callId': ref.id,
        'dari': me,
        'at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    // Bangunkan HP anggota yang aplikasinya tertutup.
    PushService.instance.beriTahu(chatId: room.id, jenis: 'panggilan', callId: ref.id);
    return ref.id;
  }

  Future<void> gabung(String callId, String me) {
    return _db.runTransaction((tx) async {
      final s = await tx.get(_koleksi.doc(callId));
      if (!s.exists) return;
      final p = Panggilan.dari(s);
      tx.update(s.reference, {
        'ikut': FieldValue.arrayUnion([me]),
        'pernah': FieldValue.arrayUnion([me]),
        'status': StatusPanggilan.berlangsung.name,
        if (p.mulai == null && p.dari != me) 'mulaiMs': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  /// Mengajak orang lain masuk ke panggilan yang sedang berjalan: teman
  /// baru, atau anggota chat yang belum mengangkat.
  Future<void> undang(Panggilan p, String me, String uid) async {
    final batch = _db.batch();
    if (!p.anggota.contains(uid)) {
      batch.update(_koleksi.doc(p.id), {
        'anggota': FieldValue.arrayUnion([uid]),
      });
    }
    batch.set(_db.collection('panggilanMasuk').doc(uid), {
      'callId': p.id,
      'dari': me,
      'at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    PushService.instance.beriTahu(chatId: p.chatId, jenis: 'undang', callId: p.id, ke: uid);
  }

  /// Riwayat panggilan saya (terbaru dulu, maks. 100), tanpa yang sudah
  /// saya hapus.
  Stream<List<Panggilan>> riwayat(String me) {
    final dihapusRef = _db.collection('users').doc(me).collection('riwayatPanggilan');
    late StreamController<List<Panggilan>> c;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? a;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? b;
    List<Panggilan>? semua;
    Set<String>? sembunyi;
    num? sebelum;
    void kirim() {
      final daftar = semua;
      final h = sembunyi;
      if (daftar == null || h == null) return;
      final hasil = daftar
          .where((p) => !h.contains(p.id) && (sebelum == null || p.dibuat.millisecondsSinceEpoch > sebelum!))
          .toList()
        ..sort((x, y) => y.dibuat.compareTo(x.dibuat));
      c.add(hasil.take(100).toList());
    }

    c = StreamController<List<Panggilan>>(
      onListen: () {
        a = _koleksi.where('anggota', arrayContains: me).snapshots().listen((s) {
          semua = s.docs.map(Panggilan.dari).toList();
          kirim();
        }, onError: c.addError);
        b = dihapusRef.snapshots().listen((s) {
          sembunyi = {for (final d in s.docs) d.id};
          sebelum = s.docs.where((d) => d.id == _semuaDihapus).firstOrNull?.data()['sebelumMs'] as num?;
          kirim();
        }, onError: c.addError);
      },
      onCancel: () async {
        await a?.cancel();
        await b?.cancel();
      },
    );
    return c.stream;
  }

  static const _semuaDihapus = '_semua';

  /// Menghapus satu panggilan dari riwayat saya.
  Future<void> hapusRiwayat(String me, String callId) {
    return _db.collection('users').doc(me).collection('riwayatPanggilan').doc(callId).set({'dihapus': true});
  }

  /// Menghapus seluruh riwayat panggilan saya.
  Future<void> hapusSemuaRiwayat(String me) {
    return _db
        .collection('users')
        .doc(me)
        .collection('riwayatPanggilan')
        .doc(_semuaDihapus)
        .set({'sebelumMs': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> tolak(String callId, String me) async {
    await NotifikasiService.instance.hapusPanggilan(callId);
    await _db.runTransaction((tx) async {
      final s = await tx.get(_koleksi.doc(callId));
      if (!s.exists) return;
      final p = Panggilan.dari(s);
      final tolak = {...p.tolak, me};
      // Semua yang dipanggil menolak: panggilan selesai.
      final semuaMenolak = p.anggota.where((u) => u != p.dari).every(tolak.contains);
      final selesai = semuaMenolak && p.status == StatusPanggilan.berdering;
      tx.update(s.reference, {
        'tolak': FieldValue.arrayUnion([me]),
        if (selesai) ...{'status': StatusPanggilan.selesai.name, 'selesaiMs': DateTime.now().millisecondsSinceEpoch},
      });
    });
  }

  /// Keluar dari panggilan. Panggilan selesai jika tinggal satu orang
  /// (chat pribadi) atau tidak ada orang lagi (grup).
  Future<void> keluar(String callId, String me) async {
    await _db.runTransaction((tx) async {
      final s = await tx.get(_koleksi.doc(callId));
      if (!s.exists) return;
      final p = Panggilan.dari(s);
      final sisa = p.ikut.where((u) => u != me).toList();
      final selesai = sisa.isEmpty ||
          (!p.ramai && p.status == StatusPanggilan.berlangsung) ||
          (p.dari == me && p.status == StatusPanggilan.berdering);
      tx.update(s.reference, {
        'ikut': FieldValue.arrayRemove([me]),
        if (selesai) ...{'status': StatusPanggilan.selesai.name, 'selesaiMs': DateTime.now().millisecondsSinceEpoch},
      });
    });
  }

  /// Tidak ada yang mengangkat: panggilan diakhiri.
  Future<void> tidakDijawab(String callId) {
    return _koleksi.doc(callId).update({
      'status': StatusPanggilan.selesai.name,
      'selesaiMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Dipakai saat HP dibangunkan FCM: tampilkan notifikasi panggilan masuk.
  static Future<void> tampilkanNotifMasuk(String uid, String callId) async {
    final p = await instance.ambil(callId);
    // Waktu dipanggil/diajak terakhir (bisa lebih baru dari awal panggilan).
    DateTime? dipanggil;
    String? pengajak;
    try {
      final ping = await FirebaseFirestore.instance.collection('panggilanMasuk').doc(uid).get();
      final at = ping.data()?['at'];
      if (ping.data()?['callId'] == callId && at is Timestamp) {
        dipanggil = at.toDate();
        pengajak = ping.data()?['dari'] as String?;
      }
    } catch (_) {}
    if (p == null || !p.bisaDiangkat(uid, dipanggil: dipanggil)) return;
    final pemanggil = await UserDirectory.instance.get(pengajak ?? p.dari);
    final nama = pemanggil == null
        ? tr('Seseorang')
        : (pemanggil.sebutan.isNotEmpty ? pemanggil.sebutan : pemanggil.namaLengkap);
    var judul = nama;
    if (p.grup) {
      try {
        final chat = await FirebaseFirestore.instance.collection('chats').doc(p.chatId).get();
        final grup = chat.data()?['name'] as String? ?? tr('grup');
        judul = '$nama · $grup';
      } catch (_) {
        // Diajak dari luar grup: tidak bisa membaca nama grupnya.
      }
    }
    await NotifikasiService.instance.tampilkanPanggilan(callId: callId, judul: judul, video: p.video);
  }
}

/// Menolak panggilan dari tombol notifikasi (bisa saat aplikasi tertutup).
Future<void> tolakPanggilanLatar(String callId) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 10), onTimeout: () => FirebaseAuth.instance.currentUser);
    if (user != null) await PanggilanService.instance.tolak(callId, user.uid);
  } catch (e) {
    debugPrint('Gagal menolak panggilan: $e');
  }
}
