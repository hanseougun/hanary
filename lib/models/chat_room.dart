import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/chat_crypto.dart';

/// Status chat pribadi.
///
/// - [aktif]: chat biasa (antar teman, atau permintaan yang sudah diterima).
/// - [permintaan]: orang yang belum berteman mengirim satu pesan dan
///   menunggu diterima ("Permintaan pesan").
/// - [ditolak]: permintaan ditolak; pengirim tidak bisa mengirim lagi.
enum ChatStatus { aktif, permintaan, ditolak }

/// Ruang chat (pribadi atau grup) di Firestore: `chats/{id}`.
///
/// Isi pesan dan pratinjau pesan terakhir terenkripsi. Yang terlihat oleh
/// server hanya daftar anggota, nama/foto/deskripsi grup, dan waktu.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.isGroup,
    required this.members,
    required this.keys,
    this.name = '',
    this.deskripsi = '',
    this.fotoVer,
    this.admin,
    this.lastBox,
    this.lastKind,
    this.lastSender,
    this.updatedAt,
    this.status = ChatStatus.aktif,
    this.requester,
    this.requestSent = false,
    this.readAt = const {},
    this.pin = const [],
  });

  final String id;
  final bool isGroup;
  final List<String> members;
  final Map<String, WrappedKey> keys;

  /// Nama grup (kosong untuk chat pribadi).
  final String name;

  /// Deskripsi grup.
  final String deskripsi;

  /// Versi foto grup (`groupAvatars/{id}`), null jika belum ada foto.
  final int? fotoVer;

  /// Pemilik grup (pembuatnya, atau orang yang diberi kepemilikan). Hanya
  /// pemilik yang boleh mengeluarkan anggota lain.
  final String? admin;

  /// Id pesan yang disematkan di atas chat (paling lama dulu, maks. 3).
  final List<String> pin;

  /// Pesan terakhir, terenkripsi dengan kunci ruang.
  final String? lastBox;

  /// Jenis pesan terakhir (teks, gambar, file, tugas).
  final String? lastKind;
  final String? lastSender;
  final DateTime? updatedAt;

  final ChatStatus status;

  /// Untuk permintaan pesan: uid yang mengirim permintaan.
  final String? requester;

  /// Apakah pengirim permintaan sudah memakai jatah satu pesannya.
  final bool requestSent;

  /// Kapan tiap anggota terakhir membaca chat ini. Hanya diisi oleh anggota
  /// yang menyalakan "Tanda sudah dibaca".
  final Map<String, DateTime> readAt;

  /// Saya pemilik grup ini. Jika pemilik sudah keluar, anggota pertama
  /// dianggap pemilik.
  bool isPemilik(String myUid) => isGroup && pemilik == myUid;

  /// Pemilik grup saat ini.
  String? get pemilik {
    if (!isGroup || members.isEmpty) return null;
    final a = admin;
    return a != null && members.contains(a) ? a : members.first;
  }

  /// Untuk chat pribadi: uid lawan bicara.
  String otherMember(String myUid) => members.firstWhere((m) => m != myUid, orElse: () => myUid);

  /// Permintaan pesan yang masuk ke saya (belum saya terima).
  bool isIncomingRequest(String myUid) => status == ChatStatus.permintaan && requester != null && requester != myUid;

  /// Saya mengirim permintaan dan masih menunggu jawaban.
  bool isOutgoingRequest(String myUid) => status == ChatStatus.permintaan && requester == myUid;

  /// Saya boleh mengirim pesan di chat ini sekarang.
  bool canSend(String myUid) =>
      status == ChatStatus.aktif || (status == ChatStatus.permintaan && requester == myUid && !requestSent);

  /// Id chat pribadi selalu sama untuk dua orang yang sama.
  static String privateId(String a, String b) {
    final pair = [a, b]..sort();
    return 'p_${pair[0]}_${pair[1]}';
  }

  factory ChatRoom.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const {};
    final rawKeys = (d['keys'] as Map<String, dynamic>?) ?? const {};
    final rawRead = (d['readAt'] as Map<String, dynamic>?) ?? const {};
    return ChatRoom(
      id: snap.id,
      isGroup: d['type'] == 'grup',
      members: List<String>.from(d['members'] as List? ?? const []),
      keys: {
        for (final e in rawKeys.entries) e.key: WrappedKey.fromMap(Map<String, dynamic>.from(e.value as Map)),
      },
      name: d['name'] as String? ?? '',
      deskripsi: d['deskripsi'] as String? ?? '',
      fotoVer: (d['fotoVer'] as num?)?.toInt(),
      admin: d['admin'] as String?,
      lastBox: d['lastBox'] as String?,
      lastKind: d['lastKind'] as String?,
      lastSender: d['lastSender'] as String?,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      status: ChatStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => ChatStatus.aktif,
      ),
      requester: d['requester'] as String?,
      requestSent: d['requestSent'] == true,
      readAt: {
        for (final e in rawRead.entries)
          if (e.value is Timestamp) e.key: (e.value as Timestamp).toDate(),
      },
      pin: List<String>.from(d['pin'] as List? ?? const []),
    );
  }
}

/// Jenis pesan.
enum MessageKind {
  teks,
  gambar,
  file,
  tugas,
  suara;

  static MessageKind dari(String? nama) =>
      MessageKind.values.firstWhere((k) => k.name == nama, orElse: () => MessageKind.teks);
}

/// Satu pesan: `chats/{id}/messages/{msgId}`. [box] adalah isi terenkripsi:
/// teks biasa untuk [MessageKind.teks], atau JSON untuk jenis lain.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.box,
    this.kind = MessageKind.teks,
    this.createdAt,
    this.pending = false,
    this.ditarik = false,
    this.balasBox,
  });

  final String id;
  final String senderId;
  final String box;
  final MessageKind kind;
  final DateTime? createdAt;

  /// Belum sampai ke server (mis. sedang offline).
  final bool pending;

  /// Ditarik pengirimnya: isi pesan sudah dikosongkan untuk semua orang.
  final bool ditarik;

  /// Kutipan pesan yang dibalas (terenkripsi), lihat `BalasanPesan`.
  final String? balasBox;

  factory ChatMessage.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const {};
    return ChatMessage(
      id: snap.id,
      senderId: d['senderId'] as String? ?? '',
      box: d['box'] as String? ?? '',
      kind: MessageKind.dari(d['kind'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      pending: snap.metadata.hasPendingWrites,
      ditarik: d['ditarik'] == true,
      balasBox: d['balas'] is String && (d['balas'] as String).isNotEmpty ? d['balas'] as String : null,
    );
  }
}
