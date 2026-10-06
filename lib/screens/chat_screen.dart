import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat_payload.dart';
import '../models/chat_room.dart';
import '../services/chat_keys.dart';
import '../services/chat_repository.dart';
import '../services/draf_chat.dart';
import '../services/friend_repository.dart';
import 'chat/chat_room_screen.dart';
import 'chat/chat_widgets.dart';
import 'chat/friend_search_screen.dart';
import 'chat/new_group_screen.dart';
import 'chat/profil_orang_screen.dart';
import 'chat/story_widgets.dart';
import 'pengaturan/pengaturan_chat_screen.dart';

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
    DrafChat.instance.muat();
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
            IconButton(
              tooltip: 'Pengaturan chat & privasi',
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PengaturanChatScreen(uid: me),
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
          heroTag: 'fab-chat',
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

/// Chat yang tampil di daftar Obrolan (bukan permintaan masuk / yang ditolak).
bool _tampilDiObrolan(ChatRoom r, String me) =>
    !r.isIncomingRequest(me) && !(r.status == ChatStatus.ditolak && r.requester != me);

class _RoomList extends StatefulWidget {
  const _RoomList({required this.me});
  final String me;

  @override
  State<_RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<_RoomList> {
  // Disimpan agar tidak memantau ulang setiap kali halaman dibangun ulang.
  late final _lastRead = ChatRepository.instance.watchLastRead(widget.me);
  late final _rooms = ChatRepository.instance.watchRooms(widget.me);

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    return StreamBuilder<Map<String, DateTime>>(
      stream: _lastRead,
      builder: (context, readSnap) => StreamBuilder<List<ChatRoom>>(
        stream: _rooms,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Gagal memuat chat: ${snap.error}'));
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          final lastRead = readSnap.data ?? const <String, DateTime>{};
          final requests = all.where((r) => r.isIncomingRequest(me)).toList();
          final rooms = all.where((r) => _tampilDiObrolan(r, me)).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              StoryBar(me: me),
              if (requests.isNotEmpty)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                    child: const Icon(Icons.mark_chat_unread_outlined),
                  ),
                  title: const Text('Permintaan pesan'),
                  subtitle: Text('${requests.length} orang yang belum berteman ingin mengirim pesan'),
                  trailing: Badge(label: Text('${requests.length}')),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _RequestsScreen(me: me),
                  )),
                ),
              const EncryptedNote(),
              if (rooms.isEmpty)
                const _Empty(
                  icon: Icons.forum_outlined,
                  title: 'Belum ada obrolan',
                  message: 'Tambah teman di tab Teman, lalu ketuk namanya untuk mulai chat.',
                ),
              for (var i = 0; i < rooms.length; i++)
                _MasukBertahap(
                  index: i,
                  child: _RoomTile(
                    key: ValueKey(rooms[i].id),
                    room: rooms[i],
                    me: me,
                    lastRead: lastRead[rooms[i].id],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Animasi masuk berurutan untuk daftar.
class _MasukBertahap extends StatelessWidget {
  const _MasukBertahap({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + 40 * index.clamp(0, 10)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

/// Daftar permintaan pesan dari orang yang belum berteman.
class _RequestsScreen extends StatelessWidget {
  const _RequestsScreen({required this.me});
  final String me;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permintaan pesan')),
      body: StreamBuilder<List<ChatRoom>>(
        stream: ChatRepository.instance.watchRooms(me),
        builder: (context, snap) {
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          final requests = all.where((r) => r.isIncomingRequest(me)).toList();
          final ditolak = all.where((r) => r.status == ChatStatus.ditolak && r.requester != me).toList();
          if (requests.isEmpty && ditolak.isEmpty) {
            return const _Empty(
              icon: Icons.mark_chat_read_outlined,
              title: 'Tidak ada permintaan',
              message: 'Pesan dari orang yang belum berteman denganmu akan muncul di sini.',
            );
          }
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Orang yang belum berteman hanya bisa mengirim 1 pesan. Buka pesannya lalu pilih '
                  'Terima agar bisa saling membalas, atau Tolak.',
                ),
              ),
              for (final r in requests) _RoomTile(room: r, me: me, lastRead: null),
              if (ditolak.isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Sudah ditolak'),
                ),
                for (final r in ditolak) _RoomTile(room: r, me: me, lastRead: null),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RoomTile extends StatefulWidget {
  const _RoomTile({super.key, required this.room, required this.me, required this.lastRead});
  final ChatRoom room;
  final String me;
  final DateTime? lastRead;

  @override
  State<_RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<_RoomTile> {
  late Future<String> _preview;
  late Future<int> _unread;

  @override
  void initState() {
    super.initState();
    _preview = _bacaPreview();
    _unread = _hitungBelumDibaca();
  }

  @override
  void didUpdateWidget(covariant _RoomTile old) {
    super.didUpdateWidget(old);
    if (old.room.lastBox != widget.room.lastBox || old.room.keys.length != widget.room.keys.length) {
      _preview = _bacaPreview();
    }
    if (old.room.updatedAt != widget.room.updatedAt || old.lastRead != widget.lastRead) {
      _unread = _hitungBelumDibaca();
    }
  }

  Future<int> _hitungBelumDibaca() async {
    final room = widget.room;
    final t = room.updatedAt;
    if (room.lastSender == null || room.lastSender == widget.me || t == null) return 0;
    if (widget.lastRead != null && !t.isAfter(widget.lastRead!)) return 0;
    try {
      return await ChatRepository.instance.unreadCount(room.id, widget.lastRead);
    } catch (_) {
      return 1;
    }
  }

  Future<String> _bacaPreview() async {
    final room = widget.room;
    final repo = ChatRepository.instance;
    // Juga membungkus kunci untuk anggota yang belum punya (lihat roomKey).
    final key = await repo.roomKey(room, widget.me);
    final box = room.lastBox;
    if (box == null) return room.isOutgoingRequest(widget.me) ? 'Menunggu diterima' : 'Belum ada pesan';
    if (room.lastKind == lastKindDitarik) {
      return room.lastSender == widget.me ? 'Kamu menarik pesan' : 'Pesan ditarik';
    }
    if (key == null) return 'Pesan terenkripsi';
    final isi = await repo.decryptIsi(room.id, MessageKind.dari(room.lastKind), box, key);
    final text = isi?.ringkas() ?? 'Pesan terenkripsi';
    return room.lastSender == widget.me ? 'Kamu: $text' : text;
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final me = widget.me;
    final other = room.otherMember(me);
    final theme = Theme.of(context);
    return FutureBuilder<int>(
      future: _unread,
      builder: (context, unreadSnap) {
        final unread = unreadSnap.data ?? 0;
        return ListTile(
          leading: GestureDetector(
            onTap: room.isGroup ? null : () => bukaProfil(context, other),
            child: Hero(
              tag: 'avatar-${room.id}',
              child: room.isGroup ? GroupAvatar(room: room) : UserAvatar(uid: other, showOnline: true),
            ),
          ),
          title: room.isGroup
              ? Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis)
              : UserName(
                  uid: other,
                  style: unread > 0 ? const TextStyle(fontWeight: FontWeight.bold) : null,
                ),
          subtitle: ListenableBuilder(
            listenable: DrafChat.instance,
            builder: (context, _) {
              // Pesan yang belum terkirim ditampilkan sebagai "Draf".
              final draf = DrafChat.instance.dari(room.id).trim();
              if (draf.isNotEmpty) {
                return Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Draf: ',
                      style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: draf.replaceAll('\n', ' ')),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }
              return FutureBuilder<String>(
                future: _preview,
                builder: (context, snap) => Text(
                  room.isOutgoingRequest(me) && room.requestSent
                      ? 'Menunggu diterima · ${snap.data ?? ''}'
                      : snap.data ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: unread > 0 ? TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600) : null,
                ),
              );
            },
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatChatTime(room.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: unread > 0 ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedScale(
                scale: unread > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatRoomScreen(chatId: room.id, me: me),
          )),
        );
      },
    );
  }
}

class _FriendsTab extends StatefulWidget {
  const _FriendsTab({required this.me});
  final String me;

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  late final _incoming = FriendRepository.instance.watchIncoming(widget.me);
  late final _friends = FriendRepository.instance.watchFriends(widget.me);
  String get me => widget.me;

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
      stream: _incoming,
      builder: (context, incomingSnap) {
        return StreamBuilder<List<String>>(
          stream: _friends,
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
                      onTap: () => bukaProfil(context, from),
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
                    // Ketuk foto: lihat profil. Ketuk baris: buka chat.
                    leading: GestureDetector(
                      onTap: () => bukaProfil(context, friend, onKirimPesan: () => _openChat(context, friend)),
                      child: UserAvatar(uid: friend, showOnline: true),
                    ),
                    title: UserName(uid: friend),
                    subtitle: PresenceText(uid: friend, style: theme.textTheme.bodySmall),
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
