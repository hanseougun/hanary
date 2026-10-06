import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pesan yang dihapus "untuk saya": hanya disembunyikan di HP ini,
/// orang lain tetap bisa melihatnya.
class PesanDihapus extends ChangeNotifier {
  PesanDihapus._();
  static final instance = PesanDihapus._();

  final _cache = <String, Set<String>>{};

  static String _kunci(String chatId) => 'pesan_dihapus_$chatId';

  /// Memuat daftar id pesan yang disembunyikan di chat ini.
  Future<Set<String>> muat(String chatId) async {
    final ada = _cache[chatId];
    if (ada != null) return ada;
    final prefs = await SharedPreferences.getInstance();
    return _cache[chatId] = (prefs.getStringList(_kunci(chatId)) ?? const []).toSet();
  }

  Set<String> dari(String chatId) => _cache[chatId] ?? const {};

  Future<void> sembunyikan(String chatId, String messageId) async {
    final ids = {...await muat(chatId), messageId};
    _cache[chatId] = ids;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kunci(chatId), ids.toList());
  }
}
