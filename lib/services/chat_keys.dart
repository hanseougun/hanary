import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'chat_crypto.dart';

/// Menyimpan kunci privat chat di penyimpanan aman HP dan
/// menerbitkan kunci publiknya di Firestore `publicKeys/{uid}`.
class ChatKeys {
  ChatKeys._();
  static final instance = ChatKeys._();

  final _storage = const FlutterSecureStorage();
  final _publicKeys = FirebaseFirestore.instance.collection('publicKeys');

  String? _uid;
  Future<SimpleKeyPair>? _keyPair;

  /// Pasangan kunci milik [uid]. Dibuat sekali per HP, lalu disimpan.
  Future<SimpleKeyPair> keyPairFor(String uid) async {
    if (_uid != uid || _keyPair == null) {
      _uid = uid;
      _keyPair = _load(uid);
    }
    try {
      return await _keyPair!;
    } catch (_) {
      // Jika gagal (mis. sedang offline), coba lagi pada panggilan berikutnya.
      _keyPair = null;
      rethrow;
    }
  }

  Future<SimpleKeyPair> _load(String uid) async {
    final name = 'chat_seed_$uid';
    String? seedB64;
    try {
      seedB64 = await _storage.read(key: name);
    } catch (_) {
      // Data aman tidak bisa dibaca (mis. dipulihkan dari backup ke HP lain).
      seedB64 = null;
    }
    if (seedB64 == null) {
      seedB64 = base64Encode(ChatCrypto.newSeed());
      await _storage.write(key: name, value: seedB64);
    }
    final keyPair = await ChatCrypto.keyPairFromSeed(base64Decode(seedB64));
    final pub = await ChatCrypto.publicKeyOf(keyPair);
    final remote = await _publicKeys.doc(uid).get();
    if (remote.data()?['pub'] != pub) {
      await _publicKeys.doc(uid).set({'pub': pub, 'updatedAt': FieldValue.serverTimestamp()});
    }
    return keyPair;
  }

  Future<String?> publicKeyOf(String uid) async {
    final snap = await _publicKeys.doc(uid).get();
    return snap.data()?['pub'] as String?;
  }
}
