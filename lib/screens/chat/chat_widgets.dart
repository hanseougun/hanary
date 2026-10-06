import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/user_directory.dart';

/// Foto profil orang lain berdasarkan uid.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.uid, this.radius = 20});
  final String uid;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: UserDirectory.instance.get(uid),
      builder: (context, snap) {
        final user = snap.data;
        final foto = user?.fotoUrl;
        final initial = (user?.sebutan.isNotEmpty ?? false) ? user!.sebutan[0].toUpperCase() : '?';
        return CircleAvatar(
          radius: radius,
          backgroundImage: foto != null ? NetworkImage(foto) : null,
          child: foto == null ? Text(initial) : null,
        );
      },
    );
  }
}

/// Sebutan orang lain berdasarkan uid.
class UserName extends StatelessWidget {
  const UserName({super.key, required this.uid, this.style});
  final String uid;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: UserDirectory.instance.get(uid),
      builder: (context, snap) {
        final user = snap.data;
        final name = user == null
            ? '...'
            : (user.sebutan.isNotEmpty ? user.sebutan : user.namaLengkap);
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
