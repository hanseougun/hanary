import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/chat_room.dart';
import 'package:tugasku/services/chat_crypto.dart';

void main() {
  test('kunci ruang hanya bisa dibuka oleh penerimanya', () async {
    final ani = await ChatCrypto.keyPairFromSeed(ChatCrypto.newSeed());
    final budi = await ChatCrypto.keyPairFromSeed(ChatCrypto.newSeed());
    final roomKey = await ChatCrypto.newRoomKey();

    final untukAni = await ChatCrypto.wrap(roomKey, await ChatCrypto.publicKeyOf(ani), 'room1');
    final dibuka = await ChatCrypto.unwrap(untukAni, ani, 'room1');
    expect(await dibuka.extractBytes(), await roomKey.extractBytes());

    expect(
      () => ChatCrypto.unwrap(untukAni, budi, 'room1'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    // Kunci yang dibungkus untuk satu ruang tidak bisa dipakai di ruang lain.
    expect(
      () => ChatCrypto.unwrap(untukAni, ani, 'room2'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('pesan terenkripsi dan bisa dibuka lagi dengan kunci ruang', () async {
    final roomKey = await ChatCrypto.newRoomKey();
    final box = await ChatCrypto.encryptText('Besok kumpul tugas jam 7 ya 📚', roomKey, 'room1');
    expect(box.contains('Besok'), isFalse);
    expect(await ChatCrypto.decryptText(box, roomKey, 'room1'), 'Besok kumpul tugas jam 7 ya 📚');

    final kunciLain = await ChatCrypto.newRoomKey();
    expect(
      () => ChatCrypto.decryptText(box, kunciLain, 'room1'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('kunci dari seed yang sama selalu sama', () async {
    final seed = ChatCrypto.newSeed();
    final a = await ChatCrypto.keyPairFromSeed(seed);
    final b = await ChatCrypto.keyPairFromSeed(seed);
    expect(await ChatCrypto.publicKeyOf(a), await ChatCrypto.publicKeyOf(b));
  });

  test('id chat pribadi sama dari kedua sisi', () {
    expect(ChatRoom.privateId('b', 'a'), ChatRoom.privateId('a', 'b'));
    expect(ChatRoom.privateId('a', 'b'), 'p_a_b');
  });
}
