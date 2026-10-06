import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Teks yang sudah diketik tetapi belum dikirim, per chat. Disimpan di HP
/// agar tidak hilang saat keluar dari chat atau menutup aplikasi.
class DrafChat extends ChangeNotifier {
  DrafChat._();
  static final instance = DrafChat._();

  static const _awalan = 'draf_chat_';

  final _draf = <String, String>{};
  final _tunda = <String, Timer>{};
  bool _dimuat = false;

  /// Memuat semua draf (sekali, saat daftar chat pertama dibuka).
  Future<void> muat() async {
    if (_dimuat) return;
    _dimuat = true;
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys()) {
      if (!k.startsWith(_awalan)) continue;
      final v = prefs.getString(k);
      if (v != null && v.isNotEmpty) _draf.putIfAbsent(k.substring(_awalan.length), () => v);
    }
    notifyListeners();
  }

  /// Draf untuk chat ini, atau string kosong.
  String dari(String chatId) => _draf[chatId] ?? '';

  /// Membaca draf langsung dari penyimpanan (dipakai saat chat dibuka).
  Future<String> ambil(String chatId) async {
    final ada = _draf[chatId];
    if (ada != null) return ada;
    final prefs = await SharedPreferences.getInstance();
    return _draf[chatId] = prefs.getString('$_awalan$chatId') ?? '';
  }

  /// Menyimpan draf. Penulisan ke penyimpanan ditunda sebentar agar tidak
  /// menulis setiap huruf; [segera] untuk saat keluar dari chat.
  void simpan(String chatId, String teks, {bool segera = false}) {
    final lama = _draf[chatId] ?? '';
    if (lama == teks && !segera) return;
    _draf[chatId] = teks;
    if (lama.trim().isEmpty != teks.trim().isEmpty || segera) notifyListeners();
    _tunda.remove(chatId)?.cancel();
    if (segera) {
      _tulis(chatId, teks);
    } else {
      _tunda[chatId] = Timer(const Duration(milliseconds: 600), () {
        _tunda.remove(chatId);
        _tulis(chatId, teks);
      });
    }
  }

  Future<void> _tulis(String chatId, String teks) async {
    final prefs = await SharedPreferences.getInstance();
    if (teks.trim().isEmpty) {
      await prefs.remove('$_awalan$chatId');
    } else {
      await prefs.setString('$_awalan$chatId', teks);
    }
  }
}
