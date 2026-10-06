import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/chat_crypto.dart';

/// Ruang chat (pribadi atau grup) di Firestore: `chats/{id}`.
///
/// Isi pesan dan pratinjau pesan terakhir terenkripsi. Yang terlihat oleh
/// server hanya daftar anggota, nama grup, dan waktu.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.isGroup,
    required this.members,
    required this.keys,
    this.name = '',
    this.admin,
    this.lastBox,
    this.lastSender,
    this.updatedAt,
  });

  final String id;
  final bool isGroup;
  final List<String> members;
  final Map<String, WrappedKey> keys;

  /// Nama grup (kosong untuk chat pribadi).
  final String name;

  /// Pembuat grup.
  final String? admin;

  /// Pesan terakhir, terenkripsi dengan kunci ruang.
  final String? lastBox;
  final String? lastSender;
  final DateTime? updatedAt;

  /// Untuk chat pribadi: uid lawan bicara.
  String otherMember(String myUid) =>
      members.firstWhere((m) => m != myUid, orElse: () => myUid);

  /// Id chat pribadi selalu sama untuk dua orang yang sama.
  static String privateId(String a, String b) {
    final pair = [a, b]..sort();
    return 'p_${pair[0]}_${pair[1]}';
  }

  factory ChatRoom.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const {};
    final rawKeys = (d['keys'] as Map<String, dynamic>?) ?? const {};
    return ChatRoom(
      id: snap.id,
      isGroup: d['type'] == 'grup',
      members: List<String>.from(d['members'] as List? ?? const []),
      keys: {
        for (final e in rawKeys.entries)
          e.key: WrappedKey.fromMap(Map<String, dynamic>.from(e.value as Map)),
      },
      name: d['name'] as String? ?? '',
      admin: d['admin'] as String?,
      lastBox: d['lastBox'] as String?,
      lastSender: d['lastSender'] as String?,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Satu pesan: `chats/{id}/messages/{msgId}`. [box] adalah teks terenkripsi.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.box,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String box;
  final DateTime? createdAt;

  factory ChatMessage.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const {};
    return ChatMessage(
      id: snap.id,
      senderId: d['senderId'] as String? ?? '',
      box: d['box'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
