import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Kunci ruang chat yang dibungkus (dienkripsi) untuk satu anggota.
///
/// Disimpan di `chats/{chatId}.keys.{uid}` sehingga hanya anggota tersebut,
/// yang memegang kunci privat di HP-nya, yang bisa membukanya.
class WrappedKey {
  const WrappedKey({required this.eph, required this.box, required this.forPub});

  /// Kunci publik sementara (X25519) yang dipakai saat membungkus.
  final String eph;

  /// Kunci ruang yang dienkripsi AES-256-GCM (nonce + ciphertext + MAC).
  final String box;

  /// Kunci publik penerima saat dibungkus. Jika berbeda dengan kunci publik
  /// penerima sekarang (mis. ganti HP), anggota lain membungkus ulang.
  final String forPub;

  factory WrappedKey.fromMap(Map<String, dynamic> m) => WrappedKey(
        eph: m['eph'] as String? ?? '',
        box: m['box'] as String? ?? '',
        forPub: m['forPub'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'eph': eph, 'box': box, 'forPub': forPub};
}

/// Enkripsi end-to-end untuk chat.
///
/// - Setiap pengguna punya pasangan kunci X25519; kunci privat hanya ada di HP.
/// - Setiap ruang chat punya satu kunci AES-256-GCM acak ("kunci ruang").
/// - Kunci ruang dibungkus untuk tiap anggota dengan ECDH X25519 + HKDF-SHA256.
/// - Isi pesan dienkripsi dengan kunci ruang. Server hanya melihat teks acak.
class ChatCrypto {
  ChatCrypto._();

  static final _x25519 = X25519();
  static final _aes = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _wrapInfo = utf8.encode('tugasku-chat-room-key-v1');

  static List<int> newSeed() {
    final rnd = Random.secure();
    return List<int>.generate(32, (_) => rnd.nextInt(256));
  }

  static Future<SimpleKeyPair> keyPairFromSeed(List<int> seed) =>
      _x25519.newKeyPairFromSeed(seed);

  static Future<String> publicKeyOf(SimpleKeyPair keyPair) async =>
      base64Encode((await keyPair.extractPublicKey()).bytes);

  static Future<SecretKey> newRoomKey() => _aes.newSecretKey();

  static Future<SecretKey> _deriveWrapKey(SecretKey shared, String chatId) {
    return _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode(chatId),
      info: _wrapInfo,
    );
  }

  /// Membungkus [roomKey] agar hanya pemilik [recipientPub] yang bisa membukanya.
  static Future<WrappedKey> wrap(SecretKey roomKey, String recipientPub, String chatId) async {
    final eph = await _x25519.newKeyPair();
    final shared = await _x25519.sharedSecretKey(
      keyPair: eph,
      remotePublicKey: SimplePublicKey(base64Decode(recipientPub), type: KeyPairType.x25519),
    );
    final wrapKey = await _deriveWrapKey(shared, chatId);
    final box = await _aes.encrypt(
      await roomKey.extractBytes(),
      secretKey: wrapKey,
      aad: utf8.encode(chatId),
    );
    return WrappedKey(
      eph: base64Encode((await eph.extractPublicKey()).bytes),
      box: base64Encode(box.concatenation()),
      forPub: recipientPub,
    );
  }

  /// Membuka kunci ruang dengan kunci privat milik sendiri.
  /// Melempar [SecretBoxAuthenticationError] jika kunci tidak cocok.
  static Future<SecretKey> unwrap(WrappedKey wrapped, SimpleKeyPair mine, String chatId) async {
    final shared = await _x25519.sharedSecretKey(
      keyPair: mine,
      remotePublicKey: SimplePublicKey(base64Decode(wrapped.eph), type: KeyPairType.x25519),
    );
    final wrapKey = await _deriveWrapKey(shared, chatId);
    final bytes = await _aes.decrypt(
      _boxFrom(wrapped.box),
      secretKey: wrapKey,
      aad: utf8.encode(chatId),
    );
    return SecretKey(bytes);
  }

  static Future<String> encryptText(String text, SecretKey roomKey, String chatId) async {
    final box = await _aes.encrypt(
      utf8.encode(text),
      secretKey: roomKey,
      aad: utf8.encode(chatId),
    );
    return base64Encode(box.concatenation());
  }

  static Future<String> decryptText(String box, SecretKey roomKey, String chatId) async {
    final bytes = await _aes.decrypt(
      _boxFrom(box),
      secretKey: roomKey,
      aad: utf8.encode(chatId),
    );
    return utf8.decode(bytes);
  }

  static SecretBox _boxFrom(String b64) => SecretBox.fromConcatenation(
        base64Decode(b64),
        nonceLength: _aes.nonceLength,
        macLength: _aes.macAlgorithm.macLength,
      );
}
