import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/data/kalimat_penyemangat.dart';
import 'package:tugasku/theme/hanary_theme.dart';

void main() {
  test('salam mengikuti jam', () {
    expect(salamWaktu(DateTime(2026, 1, 1, 7)), 'Selamat pagi');
    expect(salamWaktu(DateTime(2026, 1, 1, 12)), 'Selamat siang');
    expect(salamWaktu(DateTime(2026, 1, 1, 16)), 'Selamat sore');
    expect(salamWaktu(DateTime(2026, 1, 1, 20)), 'Selamat malam');
    expect(salamWaktu(DateTime(2026, 1, 1, 2)), 'Selamat malam');
  });

  test('kalimat penyemangat selalu dari daftar', () {
    final acak = Random(1);
    for (var i = 0; i < 50; i++) {
      expect(kalimatPenyemangat, contains(kalimatAcak(acak)));
    }
  });

  test('tema latar tersimpan dan terbaca kembali dengan namanya', () {
    for (final t in TemaLatar.values) {
      expect(TemaLatar.dari(t.name), t);
    }
    expect(TemaLatar.dari('tidak-ada'), TemaLatar.hanary);
    expect(TemaLatar.dari(null), TemaLatar.hanary);
  });

  test('setiap tema bisa dibuat untuk mode terang dan gelap', () {
    for (final t in TemaLatar.values) {
      for (final b in Brightness.values) {
        final tema = buatTema(t, b);
        expect(tema.brightness, b);
        expect(tema.extension<GayaHanary>()!.gradasi, t.gradasi);
      }
    }
  });
}
