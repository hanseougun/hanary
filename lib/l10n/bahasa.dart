import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kamus.dart';

/// Bahasa tampilan aplikasi.
enum Bahasa {
  id('Bahasa Indonesia', Locale('id'), 'id_ID'),
  en('English', Locale('en'), 'en_US'),
  ja('日本語', Locale('ja'), 'ja'),
  ko('한국어', Locale('ko'), 'ko'),
  zh('中文（简体）', Locale('zh'), 'zh_CN');

  const Bahasa(this.nama, this.locale, this.kodeTanggal);

  /// Nama bahasa dalam bahasanya sendiri.
  final String nama;
  final Locale locale;

  /// Kode untuk format tanggal (`DateFormat(..., kodeTanggal)`).
  final String kodeTanggal;

  static Bahasa dari(String? nama) => Bahasa.values.firstWhere((b) => b.name == nama, orElse: () => Bahasa.id);
}

/// Bahasa yang dipilih, disimpan di HP.
class PengaturanBahasa extends ChangeNotifier {
  PengaturanBahasa._();
  static final instance = PengaturanBahasa._();

  static const _kunci = 'tampilan.bahasa';

  Bahasa _bahasa = Bahasa.id;
  Bahasa get bahasa => _bahasa;

  /// Dibaca sekali saat aplikasi (atau pemeriksaan latar) dimulai.
  Future<void> muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bahasa = Bahasa.dari(prefs.getString(_kunci));
    } catch (_) {}
  }

  Future<void> setBahasa(Bahasa b) async {
    if (b == _bahasa) return;
    _bahasa = b;
    notifyListeners();
    // Semua layar dibangun ulang agar teks langsung berganti bahasa.
    SchedulerBinding.instance.addPostFrameCallback((_) => _bangunUlangSemua());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunci, b.name);
  }

  static void _bangunUlangSemua() {
    void tandai(Element e) {
      e.markNeedsBuild();
      e.visitChildren(tandai);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(tandai);
  }
}

/// Kode format tanggal untuk bahasa yang dipilih, mis. `DateFormat('EEEE', kodeTanggal)`.
String get kodeTanggal => PengaturanBahasa.instance.bahasa.kodeTanggal;

/// Menerjemahkan teks (ditulis dalam Bahasa Indonesia) ke bahasa yang dipilih.
///
/// Bagian yang berubah ditulis `{nama}` dan diisi lewat [isi]:
/// `tr('Hapus {nama}?', {'nama': x})`. Jika terjemahan belum ada, teks
/// Indonesianya yang dipakai.
String tr(String teks, [Map<String, Object?> isi = const {}]) {
  final b = PengaturanBahasa.instance.bahasa;
  var hasil = teks;
  if (b != Bahasa.id) {
    final t = terjemahan(teks);
    if (t != null) hasil = t[b.index - 1];
  }
  if (isi.isEmpty) return hasil;
  return hasil.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '${isi[m[1]] ?? m[0]}');
}
