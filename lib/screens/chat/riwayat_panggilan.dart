import 'package:flutter/material.dart';

import '../../models/chat_room.dart';
import '../../services/chat_repository.dart';
import '../../services/panggilan_service.dart';
import 'chat_widgets.dart';
import 'panggilan_screen.dart';

/// Tab "Panggilan": riwayat panggilan masuk, keluar, dan tak terjawab.
class RiwayatPanggilanTab extends StatefulWidget {
  const RiwayatPanggilanTab({super.key, required this.me});
  final String me;

  @override
  State<RiwayatPanggilanTab> createState() => _RiwayatPanggilanTabState();
}

class _RiwayatPanggilanTabState extends State<RiwayatPanggilanTab> {
  late final _riwayat = PanggilanService.instance.riwayat(widget.me);

  Future<void> _hapusSemua() async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus semua riwayat panggilan?',
      message: 'Riwayat hanya hilang dari daftarmu.',
      action: 'Hapus semua',
    );
    if (!ok) return;
    try {
      await PanggilanService.instance.hapusSemuaRiwayat(widget.me);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _hapus(Panggilan p) async {
    try {
      await PanggilanService.instance.hapusRiwayat(widget.me, p.id);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _menu(Panggilan p) async {
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error),
              title: const Text('Hapus dari riwayat'),
              onTap: () => Navigator.pop(ctx, 'hapus'),
            ),
          ],
        ),
      ),
    );
    if (pilihan == 'hapus') await _hapus(p);
  }

  /// Telepon balik ke chat yang sama.
  Future<void> _teleponBalik(Panggilan p) async {
    try {
      // Bisa gagal dibaca jika saya hanya diajak dari luar chat itu.
      final room = await ChatRepository.instance.watchRoom(p.chatId).first.catchError((Object _) => null);
      if (!mounted) return;
      if (room == null || !room.members.contains(widget.me) || room.status != ChatStatus.aktif) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa menelepon chat ini lagi.')),
        );
        return;
      }
      await mulaiPanggilan(context, room: room, me: widget.me, video: p.video);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Panggilan>>(
      stream: _riwayat,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Gagal memuat riwayat: ${snap.error}'));
        final daftar = snap.data;
        if (daftar == null) return const Center(child: CircularProgressIndicator());
        if (daftar.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('Belum ada riwayat panggilan', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Buka chat lalu ketuk ikon telepon atau kamera di kanan atas untuk menelepon.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: TextButton.icon(
                  onPressed: _hapusSemua,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Hapus semua'),
                ),
              ),
            ),
            for (final p in daftar)
              Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: theme.colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
                ),
                onDismissed: (_) => _hapus(p),
                child: _BarisPanggilan(
                  panggilan: p,
                  me: widget.me,
                  onTelepon: () => _teleponBalik(p),
                  onTekanLama: () => _menu(p),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Geser ke kiri atau tekan lama untuk menghapus satu riwayat.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Jenis satu panggilan dari sudut pandang saya.
enum JenisRiwayat { keluar, masuk, takTerjawab, ditolak }

JenisRiwayat jenisRiwayat(Panggilan p, String me) {
  if (p.dari == me) return JenisRiwayat.keluar;
  if (p.tolak.contains(me)) return JenisRiwayat.ditolak;
  if (p.pernah.contains(me)) return JenisRiwayat.masuk;
  // Panggilan lama (sebelum ada daftar "pernah") dianggap masuk.
  if (p.pernah.isEmpty) return JenisRiwayat.masuk;
  return JenisRiwayat.takTerjawab;
}

/// "Tak terjawab", "Keluar · 3:05", dst.
String keteranganRiwayat(Panggilan p, String me) {
  final jenis = switch (jenisRiwayat(p, me)) {
    JenisRiwayat.keluar => p.durasi == null && p.status == StatusPanggilan.selesai ? 'Tidak dijawab' : 'Keluar',
    JenisRiwayat.masuk => 'Masuk',
    JenisRiwayat.takTerjawab => 'Tak terjawab',
    JenisRiwayat.ditolak => 'Ditolak',
  };
  final d = p.durasi;
  if (d == null) return jenis;
  final jam = d.inHours;
  final menit = (d.inMinutes % 60).toString().padLeft(jam > 0 ? 2 : 1, '0');
  final detik = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$jenis · ${jam > 0 ? '$jam:' : ''}$menit:$detik';
}

class _BarisPanggilan extends StatelessWidget {
  const _BarisPanggilan({
    required this.panggilan,
    required this.me,
    required this.onTelepon,
    required this.onTekanLama,
  });
  final Panggilan panggilan;
  final String me;
  final VoidCallback onTelepon;
  final VoidCallback onTekanLama;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = panggilan;
    final jenis = jenisRiwayat(p, me);
    final merah = jenis == JenisRiwayat.takTerjawab || jenis == JenisRiwayat.ditolak;
    final warna = merah ? theme.colorScheme.error : const Color(0xFF16A34A);
    final ikonArah = switch (jenis) {
      JenisRiwayat.keluar => Icons.call_made_rounded,
      JenisRiwayat.masuk => Icons.call_received_rounded,
      JenisRiwayat.takTerjawab => Icons.call_missed_rounded,
      JenisRiwayat.ditolak => Icons.call_end_rounded,
    };
    // Lawan bicara: untuk panggilan berdua, orang selain saya.
    final lain = p.anggota.where((u) => u != me).toList();
    final berdua = !p.ramai && lain.length == 1;
    return ListTile(
      leading: berdua ? UserAvatar(uid: lain.first) : _AvatarGrup(chatId: p.chatId),
      title: berdua
          ? UserName(uid: lain.first, style: merah ? TextStyle(color: theme.colorScheme.error) : null)
          : _NamaGrup(chatId: p.chatId, jumlah: p.anggota.length, merah: merah),
      subtitle: Row(
        children: [
          Icon(ikonArah, size: 16, color: warna),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${keteranganRiwayat(p, me)} · ${formatChatTime(p.dibuat)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: p.video ? 'Panggilan video' : 'Panggilan suara',
        icon: Icon(p.video ? Icons.videocam_outlined : Icons.call_outlined, color: theme.colorScheme.primary),
        onPressed: onTelepon,
      ),
      onLongPress: onTekanLama,
    );
  }
}

class _NamaGrup extends StatelessWidget {
  const _NamaGrup({required this.chatId, required this.jumlah, required this.merah});
  final String chatId;
  final int jumlah;
  final bool merah;

  @override
  Widget build(BuildContext context) {
    final gaya = merah ? TextStyle(color: Theme.of(context).colorScheme.error) : null;
    return StreamBuilder<ChatRoom?>(
      stream: ChatRepository.instance.watchRoom(chatId),
      builder: (context, snap) {
        final room = snap.data;
        final nama = room != null && room.isGroup ? room.name : 'Panggilan grup';
        return Text('$nama ($jumlah)', maxLines: 1, overflow: TextOverflow.ellipsis, style: gaya);
      },
    );
  }
}

class _AvatarGrup extends StatelessWidget {
  const _AvatarGrup({required this.chatId});
  final String chatId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoom?>(
      stream: ChatRepository.instance.watchRoom(chatId),
      builder: (context, snap) {
        final room = snap.data;
        if (room != null && room.isGroup) return GroupAvatar(room: room);
        return const CircleAvatar(child: Icon(Icons.groups_outlined));
      },
    );
  }
}
