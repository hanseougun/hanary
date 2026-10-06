import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/app_user.dart';

void main() {
  test('profil lengkap jika nama dan sebutan terisi', () {
    const kosong = AppUser(uid: 'u1', email: 'a@b.com');
    expect(kosong.isComplete, isFalse);
    final lengkap = kosong.copyWith(namaLengkap: 'Ohgun Saputra', sebutan: 'Gun');
    expect(lengkap.isComplete, isTrue);
  });
}
