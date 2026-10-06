import 'kamus_daftar_chat.dart';
import 'kamus_panggilan.dart';
import 'kamus_profil.dart';
import 'kamus_ruang_chat.dart';
import 'kamus_tugas.dart';
import 'kamus_umum.dart';

/// Semua kamus. Tiap nilai berisi terjemahan [English, 日本語, 한국어, 中文].
const _semua = [kamusUmum, kamusTugas, kamusRuangChat, kamusDaftarChat, kamusPanggilan, kamusProfil];

/// Terjemahan untuk [teks] (Bahasa Indonesia), atau null jika belum ada.
List<String>? terjemahan(String teks) {
  for (final k in _semua) {
    final t = k[teks];
    if (t != null) return t;
  }
  return null;
}

/// Untuk uji: semua kunci dan terjemahannya.
Iterable<MapEntry<String, List<String>>> get semuaTerjemahan => _semua.expand((k) => k.entries);
