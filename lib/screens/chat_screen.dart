import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat_room.dart';
import '../services/chat_keys.dart';
import '../services/chat_repository.dart';
import '../services/friend_repository.dart';
import 'chat/chat_room_screen.dart';
import 'chat/chat_widgets.dart';
import 'chat/friend_search_screen.dart';
import 'chat/new_group_screen.dart';

/// Tab Chat: daftar obrolan (pribadi dan grup) serta daftar teman.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});
  final AppUser user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // Siapkan kunci enkripsi HP ini sejak awal agar teman bisa mengirim pesan.
    ChatKeys.instance.keyPairFor(widget.user.uid).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.user.uid;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          actions: [
            IconButton(
              tooltip: 'Tambah teman',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FriendSearchScreen(me: me),
              )),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Obrolan'), Tab(text: 'Teman')]),
        ),
        body: TabBarView(
          children: [
            _RoomList(me: me),
            _FriendsTab(me: me),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => NewGroupScreen(me: me),
          )),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Grup baru'),
        ),
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({required this.me});
  final String me;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoom>>(
      stream: ChatRepository.instance.watchRooms(me),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Gagal memuat chat: ${snap.error}'));
        final rooms = snap.data;
        if (rooms == null) return const Center(child: CircularProgressIndicator());
        if (rooms.isEmpty) {
          return const _Empty(
            icon: Icons.forum_outlined,
            title: 'Belum ada obrolan',
            message: 'Tambah teman di tab Teman, lalu ketuk namanya untuk mulai chat.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: rooms.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return const EncryptedNote();
            return _RoomTile(room: rooms[i - 1], me: me);
          },
        );
      },
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.me});
  final ChatRoom room;
  final String me;

  Future<String> _preview() async {
    final repo = ChatRepository.instance;
    // Juga membungkus kunci untuk anggota yang belum punya (lihat roomKey).
    final key = await repo.roomKey(room, me);
    final box = room.lastBox;
    if (box == null) return 'Belum ada pesan';
    if (key == null) return 'Pesan terenkripsi';
    final text = await repo.decrypt(room.id, box, key) ?? 'Pesan terenkripsi';
    return room.lastSender == me ? 'Kamu: $text' : text;
  }

  @override
  Widget build(BuildContext context) {
    final other = room.otherMember(me);
    return ListTile(
      leading: room.isGroup
          ? const CircleAvatar(child: Icon(Icons.group))
          : UserAvatar(uid: other),
      title: room.isGroup ? Text(room.name) : UserName(uid: other),
      subtitle: FutureBuilder<String>(
        future: _preview(),
        builder: (context, snap) => Text(
          snap.data ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Text(formatChatTime(room.updatedAt)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatRoomScreen(chatId: room.id, me: me),
      )),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.me});
  final String me;

  Future<void> _openChat(BuildContext context, String friend) async {
    try {
      final id = await ChatRepository.instance.openPrivate(me: me, other: friend);
      if (!context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatRoomScreen(chatId: id, me: me),
      ));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _unfriend(BuildContext context, String friend) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus dari daftar teman?',
      action: 'Hapus',
    );
    if (!ok) return;
    try {
      await FriendRepository.instance.unfriend(me: me, other: friend);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = FriendRepository.instance;
    final theme = Theme.of(context);
    return StreamBuilder<List<String>>(
      stream: friends.watchIncoming(me),
      builder: (context, incomingSnap) {
        return StreamBuilder<List<String>>(
          stream: friends.watchFriends(me),
          builder: (context, friendSnap) {
            if (friendSnap.hasError) {
              return Center(child: Text('Gagal memuat teman: ${friendSnap.error}'));
            }
            final incoming = incomingSnap.data ?? const [];
            final list = friendSnap.data;
            if (list == null) return const Center(child: CircularProgressIndicator());
            if (list.isEmpty && incoming.isEmpty) {
              return const _Empty(
                icon: Icons.people_outline,
                title: 'Belum ada teman',
                message: 'Ketuk ikon tambah teman di kanan atas, lalu cari sebutan atau email temanmu.',
              );
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                if (incoming.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text('Permintaan pertemanan', style: theme.textTheme.titleSmall),
                  ),
                  for (final from in incoming)
                    ListTile(
                      leading: UserAvatar(uid: from),
                      title: UserName(uid: from),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Tolak',
                            icon: const Icon(Icons.close),
                            onPressed: () => friends.reject(from: from, me: me),
                          ),
                          FilledButton(
                            onPressed: () => friends.accept(from: from, me: me).catchError(
                              (Object e) {
                                if (context.mounted) showError(context, e);
                              },
                            ),
                            child: const Text('Terima'),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                ],
                if (list.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text('Teman (${list.length})', style: theme.textTheme.titleSmall),
                  ),
                for (final friend in list)
                  ListTile(
                    leading: UserAvatar(uid: friend),
                    title: UserName(uid: friend),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () => _openChat(context, friend),
                    onLongPress: () => _unfriend(context, friend),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
