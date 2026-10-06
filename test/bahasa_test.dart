import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/l10n/bahasa.dart';
import 'package:tugasku/l10n/kamus.dart';

Set<String> _isian(String s) => RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m[1]!).toSet();

void main() {
  test('setiap terjemahan lengkap untuk 4 bahasa dan isiannya sama', () {
    for (final e in semuaTerjemahan) {
      expect(e.value.length, 4, reason: e.key);
      for (final t in e.value) {
        expect(t.trim(), isNotEmpty, reason: e.key);
        expect(_isian(t), _isian(e.key), reason: '${e.key} → $t');
      }
    }
  });

  test('tr mengisi bagian yang berubah dan kembali ke Bahasa Indonesia jika belum ada', () {
    expect(tr('Teks tanpa terjemahan {x}', {'x': 5}), 'Teks tanpa terjemahan 5');
    expect(tr('Halo'), 'Halo');
  });
}
