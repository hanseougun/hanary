import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';

import '../models/chat_room.dart';
import 'chat_crypto.dart';
import 'chat_keys.dart';

/// Baca/tulis ruang chat dan pesan. Semua isi pesan dienkripsi di HP
/// sebelum dikirim, dan dibuka lagi di HP penerima.
class ChatRepository {
  ChatRepository._();
  static final instance = ChatRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  final _roomKeys = <String, SecretKey>{};
  final _plain = <String, String>{};
  final _healed = <String, String>{};

  Stream<List<ChatRoom>> watchRooms(String myUid) {
    return _chats.where('members', arrayContains: myUid).snapshots().map((s) {
      final rooms = s.docs.map(ChatRoom.fromSnapshot).toList();
      rooms.sort((a, b) => (b.updatedAt ?? DateTime.now()).compareTo(a.updatedAt ?? DateTime.now()));
      return rooms;
    });
  }

  Stream<ChatRoom?> watchRoom(String id) {
    return _chats.doc(id).snapshots().map((s) => s.exists ? ChatRoom.fromSnapshot(s) : null);
  }

  /// Kunci ruang untuk saya, atau `null` jika belum ada kunci yang
  /// dibungkus untuk kunci publik saya saat ini (menunggu anggota lain).
  Future<SecretKey?> roomKey(ChatRoom room, String myUid) async {
    final mine = await ChatKeys.instance.keyPairFor(myUid);
    final myPub = await ChatCrypto.publicKeyOf(mine);
    final wrapped = room.keys[myUid];
    final cacheId = '${room.id}|$myPub';
    var key = _roomKeys[cacheId];
    if (key == null && wrapped != null && wrapped.forPub == myPub) {
      try {
        key = await ChatCrypto.unwrap(wrapped, mine, room.id);
        _roomKeys[cacheId] = key;
      } on SecretBoxAuthenticationError {
        key = null;
      }
    }
    if (key != null) _healKeys(room, key);
    return key;
  }

  /// Membungkus ulang kunci ruang untuk anggota yang belum punya kunci
  /// atau yang kunci publiknya berubah (mis. ganti HP / install ulang).
  Future<void> _healKeys(ChatRoom room, SecretKey key) async {
    final signature = [
      for (final m in room.members) '$m:${room.keys[m]?.forPub}',
    ].join(',');
    if (_healed[room.id] == signature) return;
    _healed[room.id] = signature;
    try {
      final updates = <String, Object>{};
      for (final m in room.members) {
        final pub = await ChatKeys.instance.publicKeyOf(m);
        if (pub == null || room.keys[m]?.forPub == pub) continue;
        updates['keys.$m'] = (await ChatCrypto.wrap(key, pub, room.id)).toMap();
      }
      if (updates.isNotEmpty) await _chats.doc(room.id).update(updates);
    } catch (_) {
      _healed.remove(room.id);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _wrapFor(
    Iterable<String> uids,
    SecretKey key,
    String chatId,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    for (final uid in uids) {
      final pub = await ChatKeys.instance.publicKeyOf(uid);
      if (pub == null) continue; // Dibungkus nanti setelah dia membuka aplikasi.
      result[uid] = (await ChatCrypto.wrap(key, pub, chatId)).toMap();
    }
    return result;
  }

  /// Membuka (atau membuat) chat pribadi dengan [other]. Mengembalikan id chat.
  Future<String> openPrivate({required String me, required String other}) async {
    await ChatKeys.instance.keyPairFor(me);
    final id = ChatRoom.privateId(me, other);
    final ref = _chats.doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      final key = await ChatCrypto.newRoomKey();
      await ref.set({
        'type': 'pribadi',
        'members': [me, other],
        'keys': await _wrapFor([me, other], key, id),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Future<String> createGroup({
    required String me,
    required String name,
    required List<String> memberUids,
  }) async {
    await ChatKeys.instance.keyPairFor(me);
    final ref = _chats.doc();
    final members = {me, ...memberUids}.toList();
    final key = await ChatCrypto.newRoomKey();
    await ref.set({
      'type': 'grup',
      'name': name.trim(),
      'admin': me,
      'members': members,
      'keys': await _wrapFor(members, key, ref.id),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> addMembers(ChatRoom room, String me, List<String> uids) async {
    final key = await roomKey(room, me);
    if (key == null) throw StateError('Kunci grup belum tersedia di HP ini.');
    final wrapped = await _wrapFor(uids, key, room.id);
    await _chats.doc(room.id).update({
      'members': FieldValue.arrayUnion(uids),
      for (final e in wrapped.entries) 'keys.${e.key}': e.value,
    });
  }

  Future<void> leaveGroup(ChatRoom room, String me) {
    return _chats.doc(room.id).update({
      'members': FieldValue.arrayRemove([me]),
      'keys.$me': FieldValue.delete(),
    });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromSnapshot).toList());
  }

  Future<void> send(ChatRoom room, String me, SecretKey key, String text) async {
    final box = await ChatCrypto.encryptText(text, key, room.id);
    final msgRef = _chats.doc(room.id).collection('messages').doc();
    _plain['${room.id}|$box'] = text;
    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': me,
      'box': box,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_chats.doc(room.id), {
      'lastBox': box,
      'lastSender': me,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Membuka teks terenkripsi. Mengembalikan `null` jika gagal.
  Future<String?> decrypt(String chatId, String box, SecretKey key) async {
    final cacheId = '$chatId|$box';
    final cached = _plain[cacheId];
    if (cached != null) return cached;
    try {
      final text = await ChatCrypto.decryptText(box, key, chatId);
      _plain[cacheId] = text;
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Versi cepat tanpa menunggu: hanya dari cache.
  String? cachedPlain(String chatId, String box) => _plain['$chatId|$box'];
}
