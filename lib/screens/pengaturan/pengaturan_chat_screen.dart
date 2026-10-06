import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/chat_settings.dart';
import '../../services/notifikasi_service.dart';
import '../../services/presence_service.dart';
import '../chat/chat_widgets.dart';

/// Pengaturan chat & privasi: notifikasi pesan, status online, tanda dibaca.
class PengaturanChatScreen extends StatelessWidget {
  const PengaturanChatScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat & privasi')),
      body: PengaturanChatBagian(uid: uid),
    );
  }
}

/// Isi pengaturan chat. Bisa juga dipasang sebagai satu bagian di halaman
/// Pengaturan utama.
class PengaturanChatBagian extends StatefulWidget {
  const PengaturanChatBagian({super.key, required this.uid, this.shrinkWrap = false});
  final String uid;
  final bool shrinkWrap;

  @override
  State<PengaturanChatBagian> createState() => _PengaturanChatBagianState();
}

class _PengaturanChatBagianState extends State<PengaturanChatBagian> {
  bool? _notif;

  @override
  void initState() {
    super.initState();
    ChatSettings.notifAktif().then((v) {
      if (mounted) setState(() => _notif = v);
    });
  }

  Future<void> _ubah(Future<void> Function() aksi) async {
    try {
      await aksi();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UserBuilder(
      uid: widget.uid,
      builder: (context, AppUser? user) => ListView(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Notifikasi', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifikasi pesan masuk'),
            subtitle: const Text(
              'Muncul saat ada pesan baru. Jika aplikasi ditutup, pesan dicek sekitar tiap 15 menit.',
            ),
            value: _notif ?? true,
            onChanged: _notif == null
                ? null
                : (v) => _ubah(() async {
                      setState(() => _notif = v);
                      await ChatSettings.setNotif(v);
                      if (v) await NotifikasiService.instance.mintaIzin();
                    }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Privasi', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.circle, color: Color(0xFF22C55E), size: 18),
            title: const Text('Tampilkan status online'),
            subtitle: const Text('Teman bisa melihat kamu sedang online atau kapan terakhir dilihat.'),
            value: user?.tampilOnline ?? true,
            onChanged: user == null
                ? null
                : (v) => _ubah(() async {
                      await ChatSettings.setPrivasi(widget.uid, online: v);
                      PresenceService.instance.setTampil(v);
                    }),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.done_all, color: Color(0xFF0EA5E9)),
            title: const Text('Tanda sudah dibaca'),
            subtitle: const Text('Jika dimatikan, pengirim tidak melihat centang biru saat kamu membaca pesannya.'),
            value: user?.kirimDibaca ?? true,
            onChanged: user == null ? null : (v) => _ubah(() => ChatSettings.setPrivasi(widget.uid, dibaca: v)),
          ),
          const ListTile(
            leading: Icon(Icons.mark_chat_unread_outlined),
            title: Text('Permintaan pesan'),
            subtitle: Text(
              'Orang yang belum berteman hanya bisa mengirim 1 pesan. Pesannya masuk ke "Permintaan pesan" '
              'di tab Chat dan baru bisa dibalas setelah kamu menerimanya.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Enkripsi end-to-end'),
            subtitle: Text('Pesan, foto, dan file di chat dienkripsi di HP. Server hanya menyimpan data acak.'),
          ),
        ],
      ),
    );
  }
}
