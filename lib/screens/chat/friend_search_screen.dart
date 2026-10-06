import 'package:flutter/material.dart';

import '../../l10n/bahasa.dart';
import '../../models/app_user.dart';
import '../../services/chat_repository.dart';
import '../../services/friend_repository.dart';
import 'chat_room_screen.dart';
import 'chat_widgets.dart';
import 'profil_orang_screen.dart';

/// Mencari pengguna lain berdasarkan sebutan atau email, lalu
/// mengirim permintaan pertemanan.
class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key, required this.me});
  final String me;

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final _controller = TextEditingController();
  Future<List<AppUser>>? _results;
  late final _friends = FriendRepository.instance.watchFriends(widget.me);
  late final _outgoing = FriendRepository.instance.watchOutgoing(widget.me);
  late final _incoming = FriendRepository.instance.watchIncoming(widget.me);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final q = _controller.text;
    if (q.trim().isEmpty) return;
    setState(() {
      _results = FriendRepository.instance.search(q, myUid: widget.me);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// Membuka chat. Jika belum berteman, chat menjadi permintaan pesan
  /// (hanya boleh 1 pesan sampai diterima).
  Future<void> _kirimPesan(String other) async {
    try {
      final id = await ChatRepository.instance.openPrivate(me: widget.me, other: other);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatRoomScreen(chatId: id, me: widget.me),
      ));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = FriendRepository.instance;
    final me = widget.me;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Tambah teman'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: tr('Username, sebutan, atau email teman'),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
            ),
          ),
          Expanded(
            child: _results == null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr('Ketik sebutan temanmu (mis. "Gun") atau alamat email Google-nya. '
                          'Ketuk nama seseorang untuk mengirim pesan, walau belum berteman.'),
                      textAlign: TextAlign.center,
                    ),
                  )
                : FutureBuilder<List<AppUser>>(
                    future: _results,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(child: Text(tr('Gagal mencari: {galat}', {'galat': snap.error})));
                      }
                      final users = snap.data;
                      if (users == null) return const Center(child: CircularProgressIndicator());
                      if (users.isEmpty) return Center(child: Text(tr('Tidak ditemukan.')));
                      return StreamBuilder<List<String>>(
                        stream: _friends,
                        builder: (context, friendsSnap) => StreamBuilder<List<String>>(
                          stream: _outgoing,
                          builder: (context, outSnap) => StreamBuilder<List<String>>(
                            stream: _incoming,
                            builder: (context, inSnap) {
                              final friends = friendsSnap.data ?? const [];
                              final outgoing = outSnap.data ?? const [];
                              final incoming = inSnap.data ?? const [];
                              return ListView(
                                children: [
                                  for (final u in users)
                                    ListTile(
                                      leading: GestureDetector(
                                        onTap: () => bukaProfil(context, u.uid),
                                        child: UserAvatar(uid: u.uid),
                                      ),
                                      title: Text(u.sebutan.isNotEmpty ? u.sebutan : u.namaLengkap),
                                      subtitle: Text(
                                        [if (u.username.isNotEmpty) '@${u.username}', u.namaLengkap, u.sekolah]
                                            .where((s) => s.isNotEmpty)
                                            .join(' · '),
                                      ),
                                      onTap: () => _kirimPesan(u.uid),
                                      trailing: friends.contains(u.uid)
                                          ? Chip(label: Text(tr('Teman')))
                                          : incoming.contains(u.uid)
                                              ? FilledButton(
                                                  onPressed: () => _run(() => repo.accept(from: u.uid, me: me)),
                                                  child: Text(tr('Terima')),
                                                )
                                              : outgoing.contains(u.uid)
                                                  ? OutlinedButton(
                                                      onPressed: () =>
                                                          _run(() => repo.cancelRequest(from: me, to: u.uid)),
                                                      child: Text(tr('Batalkan')),
                                                    )
                                                  : FilledButton.tonal(
                                                      onPressed: () =>
                                                          _run(() => repo.sendRequest(from: me, to: u.uid)),
                                                      child: Text(tr('Tambah')),
                                                    ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
