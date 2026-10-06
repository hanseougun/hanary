import 'package:flutter/material.dart';

import '../../models/chat_room.dart';
import '../../services/chat_repository.dart';
import 'chat_widgets.dart';
import 'new_group_screen.dart';

/// Info grup: daftar anggota, tambah anggota, dan keluar dari grup.
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
              const Center(child: CircleAvatar(radius: 40, child: Icon(Icons.group, size: 40))),
              const SizedBox(height: 12),
              Text(room.name, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
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
                  leading: UserAvatar(uid: m),
                  title: m == widget.me ? const Text('Kamu') : UserName(uid: m),
                  trailing: m == room.admin ? const Chip(label: Text('Pembuat')) : null,
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
