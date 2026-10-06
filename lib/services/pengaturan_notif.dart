import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Jenis notifikasi yang suaranya bisa diatur sendiri.
enum JenisNotif {
  chat('pesan_chat', 'Pesan chat', 'Pesan baru dari teman dan grup'),
  tugas('deadline_tugas', 'Pengingat deadline', 'Pengingat harian dan menjelang deadline tugas');

  const JenisNotif(this.saluranDasar, this.namaSaluran, this.deskripsi);

  /// Id saluran notifikasi Android untuk setelan bawaan.
  final String saluranDasar;
  final String namaSaluran;
  final String deskripsi;
}

/// Setelan suara dan durasi untuk satu jenis notifikasi.
@immutable
class SetelanNotif {
  const SetelanNotif({
    this.suara = suaraBawaan,
    this.namaSuara = '',
    this.getar = true,
    this.berulang = false,
    this.tampilMenit = 0,
  });

  static const suaraBawaan = 'bawaan';
  static const suaraSenyap = 'senyap';

  /// [suaraBawaan], [suaraSenyap], atau alamat nada (`content://...`).
  final String suara;

  /// Nama nada pilihan sendiri (untuk ditampilkan).
  final String namaSuara;
  final bool getar;

  /// Bunyi terus berulang sampai notifikasinya dilihat.
  final bool berulang;

  /// Notifikasi hilang sendiri setelah sekian menit (0 = sampai dihapus).
  final int tampilMenit;

  bool get nadaSendiri => suara != suaraBawaan && suara != suaraSenyap;

  String get labelSuara => switch (suara) {
        suaraBawaan => 'Bawaan HP',
        suaraSenyap => 'Tanpa suara',
        _ => namaSuara.isEmpty ? 'Nada pilihan' : namaSuara,
      };

  SetelanNotif copyWith({String? suara, String? namaSuara, bool? getar, bool? berulang, int? tampilMenit}) =>
      SetelanNotif(
        suara: suara ?? this.suara,
        namaSuara: namaSuara ?? this.namaSuara,
        getar: getar ?? this.getar,
        berulang: berulang ?? this.berulang,
        tampilMenit: tampilMenit ?? this.tampilMenit,
      );

  /// Id saluran notifikasi Android. Suara dan getar saluran tidak bisa
  /// diubah setelah dibuat, jadi setiap kombinasi memakai id sendiri.
  String saluran(JenisNotif jenis) {
    if (suara == suaraBawaan && getar) return jenis.saluranDasar;
    return '${jenis.saluranDasar}_${_fnv('$suara|$getar')}';
  }

  static String _fnv(String s) {
    var hash = 0x811c9dc5;
    for (final c in s.codeUnits) {
      hash = ((hash ^ c) * 0x01000193) & 0x7fffffff;
    }
    return hash.toRadixString(36);
  }
}

/// Menyimpan setelan notifikasi di HP (dibaca juga oleh pemeriksaan di
/// latar belakang, jadi memakai SharedPreferences).
class PengaturanNotif {
  PengaturanNotif._();

  static String _k(JenisNotif j, String nama) => 'notif_${j.name}_$nama';

  static Future<SetelanNotif> baca(JenisNotif j) async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return SetelanNotif(
      suara: p.getString(_k(j, 'suara')) ?? SetelanNotif.suaraBawaan,
      namaSuara: p.getString(_k(j, 'namaSuara')) ?? '',
      getar: p.getBool(_k(j, 'getar')) ?? true,
      berulang: p.getBool(_k(j, 'berulang')) ?? false,
      tampilMenit: p.getInt(_k(j, 'tampilMenit')) ?? 0,
    );
  }

  static Future<void> simpan(JenisNotif j, SetelanNotif s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k(j, 'suara'), s.suara);
    await p.setString(_k(j, 'namaSuara'), s.namaSuara);
    await p.setBool(_k(j, 'getar'), s.getar);
    await p.setBool(_k(j, 'berulang'), s.berulang);
    await p.setInt(_k(j, 'tampilMenit'), s.tampilMenit);
  }
}

/// Nada dering dari HP (lewat kode Android di MainActivity.kt).
class NadaHp {
  NadaHp._();
  static const _ch = MethodChannel('hanary/nada');

  /// Membuka daftar nada notifikasi HP. Mengembalikan (alamat, nama) atau null.
  static Future<(String, String)?> pilih({String? sekarang}) async {
    final r = await _ch.invokeMapMethod<String, String>('pilih', {'uri': sekarang});
    if (r == null || r['uri'] == null) return null;
    return (r['uri']!, r['judul'] ?? 'Nada pilihan');
  }

  /// Menyalin file suara ke folder Notifications HP agar bisa dipakai
  /// sebagai nada notifikasi (Android 10 ke atas). Mengembalikan alamatnya.
  static Future<String?> simpanFile(String path, String nama) =>
      _ch.invokeMethod<String>('simpanFile', {'path': path, 'nama': nama});

  static Future<bool> bisaSimpanFile() async => await _ch.invokeMethod<bool>('bisaSimpanFile') ?? false;

  /// Memutar contoh nada (null = nada notifikasi bawaan).
  static Future<void> putar(String? uri) => _ch.invokeMethod('putar', {'uri': uri});
  static Future<void> berhenti() => _ch.invokeMethod('berhenti');
}
