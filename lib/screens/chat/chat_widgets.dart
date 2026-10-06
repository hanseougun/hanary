import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/chat_room.dart';
import '../../services/avatar_service.dart';

/// Profil seseorang yang selalu terbaru (foto, nama, status online).
/// Satu pemantauan per orang, dipakai bersama oleh semua widget.
class UserFeed {
  UserFeed._(String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen(
      (s) {
        last = s.data() == null ? null : AppUser.fromMap(uid, s.data()!);
        _ctrl.add(last);
      },
      onError: (Object _) {},
    );
  }

  static final _feeds = <String, UserFeed>{};
  static UserFeed of(String uid) => _feeds.putIfAbsent(uid, () => UserFeed._(uid));

  final _ctrl = StreamController<AppUser?>.broadcast();
  AppUser? last;
  Stream<AppUser?> get stream => _ctrl.stream;
}

/// StreamBuilder untuk profil seseorang.
class UserBuilder extends StatelessWidget {
  const UserBuilder({super.key, required this.uid, required this.builder});
  final String uid;
  final Widget Function(BuildContext context, AppUser? user) builder;

  @override
  Widget build(BuildContext context) {
    final feed = UserFeed.of(uid);
    return StreamBuilder<AppUser?>(
      stream: feed.stream,
      initialData: feed.last,
      builder: (context, snap) => builder(context, snap.data ?? feed.last),
    );
  }
}

/// Foto profil seseorang berdasarkan uid, dengan titik hijau jika
/// [showOnline] dan orangnya sedang online.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.uid, this.radius = 20, this.showOnline = false});
  final String uid;
  final double radius;
  final bool showOnline;

  @override
  Widget build(BuildContext context) {
    return UserBuilder(
      uid: uid,
      builder: (context, user) {
        final initial = (user?.sebutan.isNotEmpty ?? false) ? user!.sebutan[0].toUpperCase() : '?';
        final avatar = FotoBulat(
          radius: radius,
          fotoUrl: user?.fotoUrl,
          foto: user?.fotoVer == null ? null : AvatarService.instance.fotoUser(uid, user!.fotoVer!),
          fallback: Text(initial, style: TextStyle(fontSize: radius * 0.8)),
        );
        if (!showOnline || !(user?.sedangOnline ?? false)) return avatar;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(right: 0, bottom: 0, child: OnlineDot(size: radius * 0.55)),
          ],
        );
      },
    );
  }
}

/// Titik hijau tanda online.
class OnlineDot extends StatelessWidget {
  const OnlineDot({super.key, this.size = 12});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
      ),
    );
  }
}

/// Foto grup.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.room, this.radius = 20});
  final ChatRoom room;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FotoBulat(
      radius: radius,
      foto: room.fotoVer == null ? null : AvatarService.instance.fotoGrup(room.id, room.fotoVer!),
      fallback: Icon(Icons.group, size: radius),
    );
  }
}

/// Foto bulat dari data foto (diunggah sendiri), URL, atau tanda pengganti.
class FotoBulat extends StatelessWidget {
  const FotoBulat({super.key, required this.radius, this.foto, this.fotoUrl, required this.fallback});
  final double radius;
  final Future<Uint8List?>? foto;
  final String? fotoUrl;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: foto,
      builder: (context, snap) {
        final ImageProvider? image = snap.data != null
            ? MemoryImage(snap.data!)
            : (foto == null && fotoUrl != null ? NetworkImage(fotoUrl!) : null);
        return CircleAvatar(
          radius: radius,
          backgroundImage: image,
          child: image == null ? fallback : null,
        );
      },
    );
  }
}

/// "Online" atau "terakhir dilihat ..." untuk seseorang.
class PresenceText extends StatelessWidget {
  const PresenceText({super.key, required this.uid, this.style});
  final String uid;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return UserBuilder(
      uid: uid,
      builder: (context, user) {
        final label = presenceLabel(user);
        if (label == null) return const SizedBox.shrink();
        return Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    );
  }
}

String? presenceLabel(AppUser? user) {
  if (user == null || !user.tampilOnline) return null;
  if (user.sedangOnline) return 'Online';
  final t = user.lastSeen;
  if (t == null) return null;
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final jam = '${two(t.hour)}:${two(t.minute)}';
  if (t.year == now.year && t.month == now.month && t.day == now.day) {
    return 'Terakhir dilihat hari ini $jam';
  }
  final kemarin = now.subtract(const Duration(days: 1));
  if (t.year == kemarin.year && t.month == kemarin.month && t.day == kemarin.day) {
    return 'Terakhir dilihat kemarin $jam';
  }
  return 'Terakhir dilihat ${two(t.day)}/${two(t.month)} $jam';
}

/// Sebutan orang lain berdasarkan uid.
class UserName extends StatelessWidget {
  const UserName({super.key, required this.uid, this.style});
  final String uid;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return UserBuilder(
      uid: uid,
      builder: (context, user) {
        final name = user == null ? '...' : (user.sebutan.isNotEmpty ? user.sebutan : user.namaLengkap);
        return Text(name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    );
  }
}

/// Keterangan kecil bahwa chat terenkripsi end-to-end.
class EncryptedNote extends StatelessWidget {
  const EncryptedNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Pesan terenkripsi end-to-end. Hanya anggota chat yang bisa membacanya.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

String formatChatTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return '${two(time.hour)}:${two(time.minute)}';
  }
  return '${two(time.day)}/${two(time.month)}';
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ),
  );
  return ok == true;
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Terjadi kesalahan: $error')),
  );
}
