import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/tugas.dart';
import 'package:tugasku/services/notifikasi_service.dart';

void main() {
  final deadline = DateTime(2026, 10, 10, 23, 59);

  test('tugas tersimpan dan terbaca kembali dari Firestore', () {
    final tugas = Tugas(
      id: 't1',
      judul: ' Makalah sejarah ',
      mapel: 'Sejarah',
      deadline: deadline,
      status: StatusTugas.dikerjakan,
      lampiran: const [Lampiran(nama: 'soal.PDF', berkas: '1_soal.PDF', ukuran: 2048)],
    );
    final map = tugas.toMap();
    expect(map['judul'], 'Makalah sejarah');
    expect(map['status'], 'dikerjakan');

    final baca = Tugas.fromMap('t1', {...map, 'deadline': Timestamp.fromDate(deadline)});
    expect(baca.deadline, deadline);
    expect(baca.status, StatusTugas.dikerjakan);
    expect(baca.lampiran.single.nama, 'soal.PDF');
    expect(baca.lampiran.single.isGambar, isFalse);
  });

  test('status tak dikenal jadi Belum, terlambat jika lewat deadline', () {
    final tugas = Tugas(id: 't', judul: 'x', deadline: deadline);
    expect(StatusTugas.dari('aneh'), StatusTugas.belum);
    expect(tugas.terlambat(DateTime(2026, 10, 11)), isTrue);
    expect(tugas.copyWith(status: StatusTugas.selesai).terlambat(DateTime(2026, 10, 11)), isFalse);
  });

  test('id notifikasi tetap dan positif', () {
    final a = NotifikasiService.idNotifikasi('abcDEF123');
    expect(a, NotifikasiService.idNotifikasi('abcDEF123'));
    expect(a, isNot(NotifikasiService.idNotifikasi('abcDEF124')));
    expect(a, greaterThanOrEqualTo(0));
  });
}
