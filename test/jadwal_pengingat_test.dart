import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/tugas.dart';
import 'package:tugasku/services/jadwal_pengingat.dart';

void main() {
  // Sekarang: Senin 6 Okt 2026 jam 10.00.
  final sekarang = DateTime(2026, 10, 6, 10);

  test('harian 12.00 & 18.00 sampai deadline, lalu menjelang dan terlewat', () {
    final t = Tugas(id: 'a', judul: 'Makalah', deadline: DateTime(2026, 10, 8, 14));
    final jadwal = hitungPengingat([t], sekarang);
    final waktu = jadwal.map((p) => (p.jenis, p.waktu)).toList();
    expect(waktu, [
      (JenisPengingat.harian, DateTime(2026, 10, 6, 12)),
      (JenisPengingat.harian, DateTime(2026, 10, 6, 18)),
      (JenisPengingat.harian, DateTime(2026, 10, 7, 12)),
      (JenisPengingat.harian, DateTime(2026, 10, 7, 18)),
      (JenisPengingat.harian, DateTime(2026, 10, 8, 12)),
      (JenisPengingat.menjelang, DateTime(2026, 10, 8, 13)),
      (JenisPengingat.menjelang, DateTime(2026, 10, 8, 13, 30)),
      (JenisPengingat.menjelang, DateTime(2026, 10, 8, 13, 45)),
      (JenisPengingat.menjelang, DateTime(2026, 10, 8, 13, 55)),
      (JenisPengingat.terlewat, DateTime(2026, 10, 8, 14)),
    ]);
    final kunci = jadwal.map((p) => p.kunci).toSet();
    expect(kunci.length, jadwal.length, reason: 'setiap pengingat punya id sendiri');
  });

  test('tugas Selesai tidak diingatkan; yang sudah lewat tidak dijadwalkan', () {
    final selesai = Tugas(
      id: 's',
      judul: 'x',
      deadline: DateTime(2026, 10, 8, 14),
      status: StatusTugas.selesai,
    );
    final lewat = Tugas(id: 'l', judul: 'y', deadline: DateTime(2026, 10, 6, 9));
    expect(hitungPengingat([selesai, lewat], sekarang), isEmpty);
  });

  test('deadline sebentar lagi: hanya pengingat yang masih di depan', () {
    final t = Tugas(id: 'b', judul: 'Kuis', deadline: DateTime(2026, 10, 6, 10, 20));
    final jadwal = hitungPengingat([t], sekarang);
    expect(jadwal.map((p) => p.menitSebelum), [15, 5, 0]);
    expect(jadwal.last.jenis, JenisPengingat.terlewat);
  });

  test('beberapa tugas digabung dalam satu pengingat harian', () {
    final a = Tugas(id: 'a', judul: 'A', deadline: DateTime(2026, 10, 7, 9));
    final b = Tugas(id: 'b', judul: 'B', deadline: DateTime(2026, 10, 6, 15));
    final harian = hitungPengingat([a, b], sekarang).where((p) => p.jenis == JenisPengingat.harian).toList();
    expect(harian.map((p) => p.waktu), [DateTime(2026, 10, 6, 12), DateTime(2026, 10, 6, 18)]);
    expect(harian.first.tugas.map((t) => t.judul), ['B', 'A']);
    expect(harian.last.tugas.map((t) => t.judul), ['A']);
  });

  test('jadwal harian dibatasi agar tidak melebihi batas alarm HP', () {
    final jauh = [
      for (var i = 0; i < 40; i++) Tugas(id: 't$i', judul: 'T$i', deadline: DateTime(2027, 1, 1)),
    ];
    final jadwal = hitungPengingat(jauh, sekarang);
    expect(jadwal.length, lessThanOrEqualTo(batasJumlahPengingat));
    final harian = jadwal.where((p) => p.jenis == JenisPengingat.harian);
    expect(harian.last.waktu.isBefore(DateTime(2026, 10, 21)), isTrue);
  });

  test('teks sisa waktu', () {
    expect(teksSisa(const Duration(days: 2, hours: 3)), '2 hari 3 jam');
    expect(teksSisa(const Duration(hours: 5, minutes: 20)), '5 jam 20 menit');
    expect(teksSisa(const Duration(minutes: 15)), '15 menit');
    expect(teksSisa(const Duration(hours: 1)), '1 jam');
  });
}
