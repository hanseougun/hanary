import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/chat_payload.dart';
import 'package:tugasku/models/chat_room.dart';
import 'package:tugasku/services/chat_crypto.dart';

void main() {
  test('isi pesan foto, file, dan tugas bisa dibaca lagi', () {
    const berkas = BerkasChat(fileId: 'f1', nama: 'soal.pdf', ukuran: 2048, parts: 1);
    final file = IsiPesan.parse(MessageKind.file, const IsiPesan.berkas(MessageKind.file, berkas).encode());
    expect(file.berkas!.nama, 'soal.pdf');
    expect(file.ringkas(), '📎 soal.pdf');

    final foto = IsiPesan.parse(
      MessageKind.gambar,
      const IsiPesan.berkas(MessageKind.gambar, berkas, teks: 'halaman 3').encode(),
    );
    expect(foto.teks, 'halaman 3');
    expect(foto.ringkas(), '📷 halaman 3');

    final deadline = DateTime(2026, 10, 9, 7, 30);
    final tugas = IsiPesan.parse(
      MessageKind.tugas,
      IsiPesan.tugas(TugasBagikan(judul: 'Makalah Biologi', mapel: 'Biologi', deadline: deadline)).encode(),
    );
    expect(tugas.tugas!.judul, 'Makalah Biologi');
    expect(tugas.tugas!.keTugas().deadline, deadline);
  });

  test('pesan lama tanpa jenis tetap dibaca sebagai teks', () {
    expect(IsiPesan.parse(MessageKind.dari(null), 'halo').teks, 'halo');
    // JSON rusak tidak membuat aplikasi error.
    expect(IsiPesan.parse(MessageKind.file, 'bukan json').kind, MessageKind.teks);
  });

  test('potongan file terenkripsi terikat pada posisinya', () async {
    final key = await ChatCrypto.newRoomKey();
    final data = List<int>.generate(5000, (i) => i % 256);
    final enc = await ChatCrypto.encryptBytes(data, key, 'room|f1|0');
    expect(await ChatCrypto.decryptBytes(enc, key, 'room|f1|0'), data);
    expect(
      () => ChatCrypto.decryptBytes(enc, key, 'room|f1|1'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('aturan kirim pesan untuk permintaan pesan', () {
    ChatRoom room(ChatStatus s, {bool sent = false}) => ChatRoom(
          id: 'p_a_b',
          isGroup: false,
          members: const ['a', 'b'],
          keys: const {},
          status: s,
          requester: 'a',
          requestSent: sent,
        );
    expect(room(ChatStatus.permintaan).canSend('a'), isTrue);
    expect(room(ChatStatus.permintaan, sent: true).canSend('a'), isFalse);
    expect(room(ChatStatus.permintaan).canSend('b'), isFalse);
    expect(room(ChatStatus.permintaan).isIncomingRequest('b'), isTrue);
    expect(room(ChatStatus.ditolak).canSend('a'), isFalse);
    expect(room(ChatStatus.aktif).canSend('b'), isTrue);
  });
}
