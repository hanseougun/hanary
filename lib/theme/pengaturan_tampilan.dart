import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hanary_theme.dart';

/// Pilihan tampilan (mode gelap/terang dan tema latar) yang disimpan di HP.
class PengaturanTampilan extends ChangeNotifier {
  PengaturanTampilan._();
  static final instance = PengaturanTampilan._();

  static const _kunciMode = 'tampilan.mode';
  static const _kunciTema = 'tampilan.tema';

  ThemeMode _mode = ThemeMode.system;
  TemaLatar _tema = TemaLatar.hanary;

  ThemeMode get mode => _mode;
  TemaLatar get tema => _tema;

  /// Dibaca sekali saat aplikasi dibuka.
  Future<void> muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_kunciMode),
        orElse: () => ThemeMode.system,
      );
      _tema = TemaLatar.dari(prefs.getString(_kunciTema));
    } catch (_) {
      // Pakai bawaan jika penyimpanan HP tidak bisa dibaca.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciMode, mode.name);
  }

  Future<void> setTema(TemaLatar tema) async {
    if (tema == _tema) return;
    _tema = tema;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciTema, tema.name);
  }
}
