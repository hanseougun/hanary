import 'package:flutter/material.dart';

import '../../l10n/bahasa.dart';
import '../../models/chat_room.dart';
import '../../services/avatar_service.dart';
import '../../services/chat_repository.dart';
import '../../services/user_directory.dart';
import 'chat_widgets.dart';
import 'lihat_foto.dart';
import 'new_group_screen.dart';
import 'profil_orang_screen.dart';

/// Info grup: foto, nama, deskripsi, daftar anggota, tambah anggota,
/// dan keluar dari grup. Semua anggota boleh mengubah info grup; hanya
/// pemilik yang boleh mengeluarkan anggota dan menyerahkan kepemilikan.
class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key, required this.chatId, required this.me});
  final String chatId;
  final String me;

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late final _room = ChatRepository.instance.watchRoom(widget.chatId);

  Future<void> _addMembers(ChatRoom room) async {
    final picked = await Navigator.of(context).push<List<String>>(MaterialPageRoute(
      builder: (_) => NewGroupScreen(me: widget.me, existingMembers: room.members),
    ));
    if (picked == null || picked.isEmpty) return;
    try {
      await ChatRepository.instance.addMembers(room, widget.me, picked);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _gantiFoto(ChatRoom room) async {
    if (room.fotoVer != null) {
      final pilihan = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded),
                title: Text(tr('Lihat foto')),
                onTap: () => Navigator.pop(ctx, 'lihat'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(tr('Ganti foto')),
                onTap: () => Navigator.pop(ctx, 'ganti'),
              ),
            ],
          ),
        ),
      );
      if (pilihan == null || !mounted) return;
      if (pilihan == 'lihat') return lihatFotoGrup(context, room);
    }
    try {
      final foto = await AvatarService.instance.pilihFoto(context);
      if (foto == null) return;
      await AvatarService.instance.simpanFotoGrup(room.id, foto);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _ubahTeks(ChatRoom room, {required bool nama}) async {
    final controller = TextEditingController(text: nama ? room.name : room.deskripsi);
    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nama ? tr('Nama grup') : tr('Deskripsi grup')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: nama ? 50 : 300,
          maxLines: nama ? 1 : 5,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              InputDecoration(hintText: nama ? tr('mis. Kelompok Biologi') : tr('mis. Grup diskusi tugas kelompok')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Batal'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(tr('Simpan'))),
        ],
      ),
    );
    controller.dispose();
    if (hasil == null) return;
    if (nama && hasil.trim().isEmpty) return;
    try {
      await ChatRepository.instance.updateGroup(
        room.id,
        name: nama ? hasil : null,
        deskripsi: nama ? null : hasil,
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// Ketuk anggota: lihat profil, atau (untuk pemilik) jadikan pemilik /
  /// keluarkan dari grup.
  Future<void> _menuAnggota(ChatRoom room, String uid) async {
    if (!room.isPemilik(widget.me)) {
      bukaProfil(context, uid);
      return;
    }
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final merah = Theme.of(ctx).colorScheme.error;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: UserAvatar(uid: uid), title: UserName(uid: uid)),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(tr('Lihat profil')),
                onTap: () => Navigator.pop(ctx, 'profil'),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(tr('Jadikan pemilik grup')),
                subtitle: Text(tr('Kamu tidak lagi menjadi pemilik')),
                onTap: () => Navigator.pop(ctx, 'pemilik'),
              ),
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: merah),
                title: Text(tr('Keluarkan dari grup'), style: TextStyle(color: merah)),
                onTap: () => Navigator.pop(ctx, 'keluarkan'),
              ),
            ],
          ),
        );
      },
    );
    if (pilihan == null || !mounted) return;
    final repo = ChatRepository.instance;
    final nama = await UserDirectory.instance.get(uid);
    final sebutan = nama == null ? tr('anggota ini') : (nama.sebutan.isNotEmpty ? nama.sebutan : nama.namaLengkap);
    if (!mounted) return;
    try {
      switch (pilihan) {
        case 'profil':
          bukaProfil(context, uid);
        case 'pemilik':
          final ok = await confirmDialog(
            context,
            title: tr('Jadikan {nama} pemilik grup?', {'nama': sebutan}),
            message: tr('Setelah ini hanya {nama} yang bisa mengeluarkan anggota dan memindahkan kepemilikan.',
                {'nama': sebutan}),
            action: tr('Jadikan pemilik'),
          );
          if (ok) await repo.jadikanPemilik(room, widget.me, uid);
        case 'keluarkan':
          final ok = await confirmDialog(
            context,
            title: tr('Keluarkan {nama} dari grup?', {'nama': sebutan}),
            message: tr('Dia tidak bisa lagi membaca atau mengirim pesan di grup ini.'),
            action: tr('Keluarkan'),
          );
          if (ok) await repo.keluarkanAnggota(room, widget.me, uid);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _leave(ChatRoom room) async {
    final ok = await confirmDialog(
      context,
      title: tr('Keluar dari grup "{nama}"?', {'nama': room.name}),
      message: room.isPemilik(widget.me) && room.members.length > 1
          ? tr('Kamu tidak akan menerima pesan baru dari grup ini. Kepemilikan grup pindah ke anggota lain.')
          : tr('Kamu tidak akan menerima pesan baru dari grup ini.'),
      action: tr('Keluar dari grup'),
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await ChatRepository.instance.leaveGroup(room, widget.me);
      navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoom?>(
      stream: _room,
      builder: (context, snap) {
        final room = snap.data;
        if (room == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(tr('Info grup'))),
          body: ListView(
            children: [
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => _gantiFoto(room),
                  child: Stack(
                    children: [
                      Hero(tag: 'avatar-${room.id}', child: GroupAvatar(room: room, radius: 52)),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(Icons.photo_camera, size: 18, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _ubahTeks(room, nama: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(room.name, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit, size: 18, color: theme.colorScheme.outline),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ListTile(
                  leading: const Icon(Icons.notes_outlined),
                  title: Text(tr('Deskripsi grup')),
                  subtitle: Text(room.deskripsi.isEmpty ? tr('Ketuk untuk menambah deskripsi') : room.deskripsi),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _ubahTeks(room, nama: false),
                ),
              ),
              const EncryptedNote(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(tr('{jumlah} anggota', {'jumlah': room.members.length}), style: theme.textTheme.titleSmall),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
                title: Text(tr('Tambah anggota')),
                onTap: () => _addMembers(room),
              ),
              for (final m in room.members)
                ListTile(
                  leading: UserAvatar(uid: m, showOnline: true),
                  title: m == widget.me ? Text(tr('Kamu')) : UserName(uid: m),
                  trailing: m == room.pemilik ? Chip(label: Text(tr('Pemilik'))) : null,
                  onTap: m == widget.me ? null : () => _menuAnggota(room, m),
                ),
              if (room.isPemilik(widget.me))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    tr('Kamu pemilik grup ini. Ketuk anggota untuk mengeluarkannya atau menjadikannya pemilik.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(tr('Keluar dari grup'), style: TextStyle(color: theme.colorScheme.error)),
                onTap: () => _leave(room),
              ),
            ],
          ),
        );
      },
    );
  }
}
