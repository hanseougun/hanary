import 'package:flutter/material.dart';

import '../../models/chat_room.dart';
import '../../services/avatar_service.dart';
import '../../services/chat_repository.dart';
import 'chat_widgets.dart';
import 'new_group_screen.dart';
import 'profil_orang_screen.dart';

/// Info grup: foto, nama, deskripsi, daftar anggota, tambah anggota,
/// dan keluar dari grup. Semua anggota boleh mengubah info grup.
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
    try {
      final foto = await AvatarService.instance.pilihFoto();
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
        title: Text(nama ? 'Nama grup' : 'Deskripsi grup'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: nama ? 50 : 300,
          maxLines: nama ? 1 : 5,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: nama ? 'mis. Kelompok Biologi' : 'mis. Grup diskusi tugas kelompok'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Simpan')),
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

  Future<void> _leave(ChatRoom room) async {
    final ok = await confirmDialog(
      context,
      title: 'Keluar dari grup "${room.name}"?',
      message: 'Kamu tidak akan menerima pesan baru dari grup ini.',
      action: 'Keluar',
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
          appBar: AppBar(title: const Text('Info grup')),
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
                  title: const Text('Deskripsi grup'),
                  subtitle: Text(room.deskripsi.isEmpty ? 'Ketuk untuk menambah deskripsi' : room.deskripsi),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _ubahTeks(room, nama: false),
                ),
              ),
              const EncryptedNote(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('${room.members.length} anggota', style: theme.textTheme.titleSmall),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
                title: const Text('Tambah anggota'),
                onTap: () => _addMembers(room),
              ),
              for (final m in room.members)
                ListTile(
                  leading: UserAvatar(uid: m, showOnline: true),
                  title: m == widget.me ? const Text('Kamu') : UserName(uid: m),
                  trailing: m == room.admin ? const Chip(label: Text('Pembuat')) : null,
                  onTap: m == widget.me ? null : () => bukaProfil(context, m),
                ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text('Keluar dari grup', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () => _leave(room),
              ),
            ],
          ),
        );
      },
    );
  }
}
