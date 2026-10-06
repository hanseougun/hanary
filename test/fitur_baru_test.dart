import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/chat_payload.dart';
import 'package:tugasku/models/chat_room.dart';
import 'package:tugasku/screens/chat/lihat_foto.dart';
import 'package:tugasku/services/pengaturan_notif.dart';

void main() {
  test('kutipan balasan bisa dibaca lagi dan dipendekkan', () {
    final panjang = 'a' * 300;
    final b = BalasanPesan.dariPesan('m1', 'ani', IsiPesan.teks('baris 1\n$panjang'));
    expect(b.ringkas.length, 120);
    expect(b.ringkas.contains('\n'), isFalse);
    final lagi = BalasanPesan.parse(b.encode())!;
    expect(lagi.id, 'm1');
    expect(lagi.dari, 'ani');
    expect(lagi.ringkas, b.ringkas);
    expect(lagi.kind, MessageKind.teks);
    expect(BalasanPesan.parse('bukan json'), isNull);
  });

  test('kutipan foto memakai ringkasan foto', () {
    const berkas = BerkasChat(fileId: 'f', nama: 'foto.jpg', ukuran: 10, parts: 1);
    final b = BalasanPesan.dariPesan('m2', 'budi', const IsiPesan.berkas(MessageKind.gambar, berkas));
    expect(b.ringkas, '📷 Foto');
    expect(b.kind, MessageKind.gambar);
  });

  test('saluran notifikasi berganti saat suara atau getar diubah', () {
    const bawaan = SetelanNotif();
    expect(bawaan.saluran(JenisNotif.chat), 'pesan_chat');
    expect(bawaan.saluran(JenisNotif.tugas), 'deadline_tugas');
    // Lama bunyi dan lama tampil tidak butuh saluran baru.
    expect(bawaan.copyWith(berulang: true, tampilMenit: 5).saluran(JenisNotif.chat), 'pesan_chat');
    final senyap = bawaan.copyWith(suara: SetelanNotif.suaraSenyap).saluran(JenisNotif.chat);
    final nada = bawaan.copyWith(suara: 'content://media/1').saluran(JenisNotif.chat);
    final tanpaGetar = bawaan.copyWith(getar: false).saluran(JenisNotif.chat);
    expect({senyap, nada, tanpaGetar, 'pesan_chat'}.length, 4);
    expect(nada, startsWith('pesan_chat_'));
    expect(bawaan.copyWith(suara: 'content://media/1').saluran(JenisNotif.chat), nada);
  });

  test('foto akun Google diminta versi besar', () {
    expect(fotoGoogleBesar('https://lh3.googleusercontent.com/a/abc=s96-c'),
        'https://lh3.googleusercontent.com/a/abc=s1024');
    expect(fotoGoogleBesar('https://contoh.com/foto.png'), 'https://contoh.com/foto.png');
  });
}
