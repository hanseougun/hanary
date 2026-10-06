import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';

import '../models/chat_payload.dart';
import '../models/chat_room.dart';
import 'chat_crypto.dart';
import 'chat_files.dart';
import 'chat_keys.dart';
import 'push_service.dart';

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
  ///
  /// Jika belum berteman, chat dibuat sebagai "permintaan pesan": saya hanya
  /// boleh mengirim satu pesan sampai [other] menerimanya.
  Future<String> openPrivate({required String me, required String other}) async {
    await ChatKeys.instance.keyPairFor(me);
    final id = ChatRoom.privateId(me, other);
    final ref = _chats.doc(id);
    final snap = await ref.get();
    final friend = (await _db.collection('users').doc(me).collection('teman').doc(other).get()).exists;
    if (!snap.exists) {
      final key = await ChatCrypto.newRoomKey();
      await ref.set({
        'type': 'pribadi',
        'members': [me, other],
        'keys': await _wrapFor([me, other], key, id),
        if (friend) 'status': ChatStatus.aktif.name,
        if (!friend) ...{
          'status': ChatStatus.permintaan.name,
          'requester': me,
          'requestSent': false,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else if (friend && snap.data()?['status'] == ChatStatus.permintaan.name) {
      // Sudah berteman sekarang: permintaan otomatis menjadi chat biasa.
      await ref.update({'status': ChatStatus.aktif.name});
    }
    return id;
  }

  /// Menerima permintaan pesan: chat menjadi chat biasa.
  Future<void> acceptRequest(String chatId) => _chats.doc(chatId).update({'status': ChatStatus.aktif.name});

  /// Menolak permintaan pesan: pengirim tidak bisa mengirim lagi.
  Future<void> rejectRequest(String chatId) => _chats.doc(chatId).update({'status': ChatStatus.ditolak.name});

  Future<String> createGroup({
    required String me,
    required String name,
    required List<String> memberUids,
    String deskripsi = '',
  }) async {
    await ChatKeys.instance.keyPairFor(me);
    final ref = _chats.doc();
    final members = {me, ...memberUids}.toList();
    final key = await ChatCrypto.newRoomKey();
    await ref.set({
      'type': 'grup',
      'name': name.trim(),
      'deskripsi': deskripsi.trim(),
      'admin': me,
      'members': members,
      'keys': await _wrapFor(members, key, ref.id),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Mengubah nama, deskripsi, atau versi foto grup.
  Future<void> updateGroup(String chatId, {String? name, String? deskripsi, int? fotoVer}) {
    return _chats.doc(chatId).update({
      if (name != null) 'name': name.trim(),
      if (deskripsi != null) 'deskripsi': deskripsi.trim(),
      if (fotoVer != null) 'fotoVer': fotoVer,
    });
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
      'readAt.$me': FieldValue.delete(),
    });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots(includeMetadataChanges: true)
        .map((s) => s.docs.map(ChatMessage.fromSnapshot).toList());
  }

  Future<void> send(ChatRoom room, String me, SecretKey key, String text, {BalasanPesan? balas}) =>
      sendIsi(room, me, key, IsiPesan.teks(text), balas: balas);

  /// Mengirim pesan (teks, foto, file, atau tugas). Isinya dienkripsi dulu.
  /// [balas]: pesan yang sedang dibalas (ikut dienkripsi).
  Future<void> sendIsi(ChatRoom room, String me, SecretKey key, IsiPesan isi, {BalasanPesan? balas}) async {
    final plain = isi.encode();
    final box = await ChatCrypto.encryptText(plain, key, room.id);
    final msgRef = _chats.doc(room.id).collection('messages').doc();
    _plain['${room.id}|$box'] = plain;
    String? balasBox;
    if (balas != null) {
      final p = balas.encode();
      balasBox = await ChatCrypto.encryptText(p, key, room.id);
      _plain['${room.id}|$balasBox'] = p;
    }
    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': me,
      'box': box,
      'kind': isi.kind.name,
      if (balasBox != null) 'balas': balasBox,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_chats.doc(room.id), {
      'lastBox': box,
      'lastKind': isi.kind.name,
      'lastSender': me,
      'updatedAt': FieldValue.serverTimestamp(),
      if (room.isOutgoingRequest(me)) 'requestSent': true,
    });
    await batch.commit();
    _db.collection('users').doc(me).collection('bacaan').doc(room.id).set({
      'at': FieldValue.serverTimestamp(),
    }).catchError((Object _) {});
    _pingInbox(room, me);
    PushService.instance.beriTahu(chatId: room.id);
  }

  /// Menarik pesan saya untuk semua orang: isinya dikosongkan di server,
  /// dan potongan foto/file/suaranya dihapus.
  Future<void> tarik(ChatRoom room, ChatMessage m, {BerkasChat? berkas}) async {
    final batch = _db.batch();
    batch.update(_chats.doc(room.id).collection('messages').doc(m.id), {
      'box': '',
      'ditarik': true,
      if (m.balasBox != null) 'balas': FieldValue.delete(),
    });
    if (room.lastBox == m.box) {
      batch.update(_chats.doc(room.id), {'lastBox': '', 'lastKind': lastKindDitarik});
    }
    await batch.commit();
    if (berkas != null) await ChatFiles.instance.hapus(room.id, berkas);
  }

  /// Memberi tahu anggota lain bahwa ada pesan baru (dipakai pemeriksaan
  /// notifikasi di latar belakang). Gagal pun tidak masalah.
  void _pingInbox(ChatRoom room, String me) {
    final batch = _db.batch();
    for (final m in room.members) {
      if (m == me) continue;
      batch.set(_db.collection('inbox').doc(m), {
        'at': FieldValue.serverTimestamp(),
        'from': me,
        'chat': room.id,
      });
    }
    batch.commit().catchError((Object _) {});
  }

  /// Kapan saya terakhir membaca tiap chat (`users/{me}/bacaan/{chatId}`).
  /// Hanya bisa dibaca oleh saya sendiri.
  Stream<Map<String, DateTime>> watchLastRead(String me) {
    return _db.collection('users').doc(me).collection('bacaan').snapshots().map((s) => {
          for (final d in s.docs)
            if (d.data()['at'] is Timestamp) d.id: (d.data()['at'] as Timestamp).toDate(),
        });
  }

  /// Menandai chat sudah saya baca. Jika [publish], anggota lain juga bisa
  /// melihat tanda "sudah dibaca".
  Future<void> markRead(ChatRoom room, String me, {required bool publish}) async {
    await _db.collection('users').doc(me).collection('bacaan').doc(room.id).set({'at': FieldValue.serverTimestamp()});
    if (room.status == ChatStatus.aktif) {
      await _chats.doc(room.id).update({
        'readAt.$me': publish ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    }
  }

  /// Jumlah pesan dari orang lain sejak [since].
  Future<int> unreadCount(String chatId, DateTime? since) async {
    Query<Map<String, dynamic>> q = _chats.doc(chatId).collection('messages');
    if (since != null) q = q.where('createdAt', isGreaterThan: Timestamp.fromDate(since));
    // Pesan saya sendiri tidak terhitung karena mengirim pesan juga
    // memperbarui waktu baca saya (lihat sendIsi).
    return (await q.count().get()).count ?? 0;
  }

  /// Membuka isi pesan. Mengembalikan `null` jika gagal.
  Future<IsiPesan?> decryptIsi(String chatId, MessageKind kind, String box, SecretKey key) async {
    final plain = await decrypt(chatId, box, key);
    return plain == null ? null : IsiPesan.parse(kind, plain);
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
