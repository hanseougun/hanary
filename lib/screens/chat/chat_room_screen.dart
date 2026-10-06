import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import '../../models/chat_room.dart';
import '../../services/chat_repository.dart';
import 'chat_widgets.dart';
import 'group_info_screen.dart';

/// Halaman percakapan (pribadi atau grup).
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.chatId, required this.me});
  final String chatId;
  final String me;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _repo = ChatRepository.instance;
  late final _room = _repo.watchRoom(widget.chatId);
  late final _messages = _repo.watchMessages(widget.chatId);
  final _input = TextEditingController();

  Future<SecretKey?>? _keyFuture;
  String? _keySignature;
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Ambil ulang kunci ruang setiap kali daftar kunci berubah
  /// (mis. anggota lain baru saja membungkus kunci untuk HP ini).
  Future<SecretKey?> _keyFor(ChatRoom room) {
    final signature = room.keys.entries.map((e) => '${e.key}:${e.value.forPub}').join(',');
    if (signature != _keySignature || _keyFuture == null) {
      _keySignature = signature;
      _keyFuture = _repo.roomKey(room, widget.me);
    }
    return _keyFuture!;
  }

  Future<void> _send(ChatRoom room, SecretKey key) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.send(room, widget.me, key, text);
      _input.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoom?>(
      stream: _room,
      builder: (context, roomSnap) {
        final room = roomSnap.data;
        if (room == null || !room.members.contains(widget.me)) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: roomSnap.hasError || roomSnap.connectionState == ConnectionState.active
                  ? const Text('Chat tidak tersedia.')
                  : const CircularProgressIndicator(),
            ),
          );
        }
        final other = room.otherMember(widget.me);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                room.isGroup
                    ? const CircleAvatar(radius: 18, child: Icon(Icons.group, size: 20))
                    : UserAvatar(uid: other, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      room.isGroup ? Text(room.name) : UserName(uid: other),
                      if (room.isGroup)
                        Text(
                          '${room.members.length} anggota',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (room.isGroup)
                IconButton(
                  tooltip: 'Info grup',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GroupInfoScreen(chatId: room.id, me: widget.me),
                  )),
                ),
            ],
          ),
          body: FutureBuilder<SecretKey?>(
            future: _keyFor(room),
            builder: (context, keySnap) {
              if (keySnap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final key = keySnap.data;
              if (key == null) return const _WaitingForKey();
              return Column(
                children: [
                  Expanded(child: _messageList(room, key)),
                  _inputBar(room, key),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _messageList(ChatRoom room, SecretKey key) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _messages,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Gagal memuat pesan: ${snap.error}'));
        final messages = snap.data;
        if (messages == null) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length + 1,
          itemBuilder: (context, i) {
            if (i == messages.length) return const EncryptedNote();
            final m = messages[i];
            final older = i + 1 < messages.length ? messages[i + 1] : null;
            return _Bubble(
              room: room,
              message: m,
              roomKey: key,
              isMine: m.senderId == widget.me,
              showSender: room.isGroup && m.senderId != widget.me && older?.senderId != m.senderId,
            );
          },
        );
      },
    );
  }

  Widget _inputBar(ChatRoom room, SecretKey key) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: 'Kirim',
              onPressed: _sending ? null : () => _send(room, key),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.room,
    required this.message,
    required this.roomKey,
    required this.isMine,
    required this.showSender,
  });
  final ChatRoom room;
  final ChatMessage message;
  final SecretKey roomKey;
  final bool isMine;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ChatRepository.instance;
    final cached = repo.cachedPlain(room.id, message.box);
    final bg = isMine ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = isMine ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSender)
                UserName(
                  uid: message.senderId,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              cached != null
                  ? Text(cached, style: TextStyle(color: fg))
                  : FutureBuilder<String?>(
                      future: repo.decrypt(room.id, message.box, roomKey),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return Text('…', style: TextStyle(color: fg));
                        }
                        final text = snap.data;
                        return Text(
                          text ?? 'Pesan tidak bisa dibuka',
                          style: TextStyle(
                            color: fg,
                            fontStyle: text == null ? FontStyle.italic : null,
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 2),
              Text(
                formatChatTime(message.createdAt ?? DateTime.now()),
                style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingForKey extends StatelessWidget {
  const _WaitingForKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_outlined, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Menunggu kunci enkripsi', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'HP ini belum punya kunci untuk membuka chat ini. Kunci dikirim otomatis '
              'saat temanmu membuka aplikasi Hanary. Biarkan halaman ini terbuka atau cek lagi nanti.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
