import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/app_user.dart';

void main() {
  test('profil lengkap jika nama, sebutan, dan username terisi', () {
    const kosong = AppUser(uid: 'u1', email: 'a@b.com');
    expect(kosong.isComplete, isFalse);
    final tanpaUsername = kosong.copyWith(namaLengkap: 'Ohgun Saputra', sebutan: 'Gun');
    expect(tanpaUsername.isComplete, isFalse);
    expect(tanpaUsername.copyWith(username: 'gun.hans').isComplete, isTrue);
  });

  test('aturan username', () {
    for (final ok in ['gun', 'gun.hans', 'ohgun_27', 'a1b2c3d4e5f6g7h8i9j0']) {
      expect(polaUsername.hasMatch(ok), isTrue, reason: ok);
    }
    for (final salah in ['', 'gu', 'Gun', 'gun hans', 'gun-hans', '@gun', 'a1b2c3d4e5f6g7h8i9j0k']) {
      expect(polaUsername.hasMatch(salah), isFalse, reason: salah);
    }
  });

  test('label isian mengikuti kegiatan', () {
    const pekerja = AppUser(uid: 'u1', email: 'a@b.com', peran: Peran.pekerja);
    expect(pekerja.labelTempat, 'Perusahaan / instansi');
    expect(pekerja.labelPosisi, 'Jabatan / pekerjaan');
    const lama = AppUser(uid: 'u2', email: 'b@b.com');
    expect(lama.labelTempat, 'Sekolah / kampus');
    expect(Peran.dari('mahasiswa'), Peran.mahasiswa);
    expect(Peran.dari('aneh'), isNull);
  });
}
