import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/friend_repository.dart';
import 'chat_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final repo = FriendRepository.instance;
    final me = widget.me;
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah teman')),
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
                labelText: 'Sebutan atau email teman',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
            ),
          ),
          Expanded(
            child: _results == null
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ketik sebutan temanmu (mis. "Gun") atau alamat email Google-nya.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : FutureBuilder<List<AppUser>>(
                    future: _results,
                    builder: (context, snap) {
                      if (snap.hasError) return Center(child: Text('Gagal mencari: ${snap.error}'));
                      final users = snap.data;
                      if (users == null) return const Center(child: CircularProgressIndicator());
                      if (users.isEmpty) return const Center(child: Text('Tidak ditemukan.'));
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
                                      leading: UserAvatar(uid: u.uid),
                                      title: Text(u.sebutan.isNotEmpty ? u.sebutan : u.namaLengkap),
                                      subtitle: Text(
                                        [u.namaLengkap, u.sekolah].where((s) => s.isNotEmpty).join(' · '),
                                      ),
                                      trailing: friends.contains(u.uid)
                                          ? const Chip(label: Text('Teman'))
                                          : incoming.contains(u.uid)
                                              ? FilledButton(
                                                  onPressed: () => _run(() => repo.accept(from: u.uid, me: me)),
                                                  child: const Text('Terima'),
                                                )
                                              : outgoing.contains(u.uid)
                                                  ? OutlinedButton(
                                                      onPressed: () =>
                                                          _run(() => repo.cancelRequest(from: me, to: u.uid)),
                                                      child: const Text('Batalkan'),
                                                    )
                                                  : FilledButton.tonal(
                                                      onPressed: () =>
                                                          _run(() => repo.sendRequest(from: me, to: u.uid)),
                                                      child: const Text('Tambah'),
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
