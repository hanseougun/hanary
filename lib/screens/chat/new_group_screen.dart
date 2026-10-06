import 'package:flutter/material.dart';

import '../../services/chat_repository.dart';
import '../../services/friend_repository.dart';
import 'chat_room_screen.dart';
import 'chat_widgets.dart';

/// Membuat grup baru, atau (jika [existingMembers] diisi) memilih teman
/// untuk ditambahkan ke grup yang sudah ada.
class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key, required this.me, this.existingMembers});
  final String me;

  /// Diisi saat menambah anggota: hasilnya dikembalikan lewat `Navigator.pop`.
  final List<String>? existingMembers;

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _name = TextEditingController();
  final _deskripsi = TextEditingController();
  final _selected = <String>{};
  late final _friends = FriendRepository.instance.watchFriends(widget.me);
  bool _saving = false;

  bool get _addMode => widget.existingMembers != null;

  @override
  void dispose() {
    _name.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_addMode) {
      Navigator.of(context).pop(_selected.toList());
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama grup dulu.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ChatRepository.instance.createGroup(
        me: widget.me,
        name: name,
        memberUids: _selected.toList(),
        deskripsi: _deskripsi.text,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ChatRoomScreen(chatId: id, me: widget.me),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exclude = widget.existingMembers ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(_addMode ? 'Tambah anggota' : 'Grup baru')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_addMode)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nama grup',
                  hintText: 'mis. Kelompok Biologi',
                ),
              ),
            ),
          if (!_addMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _deskripsi,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi grup (boleh dikosongkan)',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Pilih teman', style: theme.textTheme.titleSmall),
          ),
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _friends,
              builder: (context, snap) {
                final friends = snap.data?.where((f) => !exclude.contains(f)).toList();
                if (friends == null) return const Center(child: CircularProgressIndicator());
                if (friends.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada teman yang bisa dipilih. Tambah teman dulu dari tab Chat.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView(
                  children: [
                    for (final f in friends)
                      CheckboxListTile(
                        value: _selected.contains(f),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(f);
                          } else {
                            _selected.remove(f);
                          }
                        }),
                        secondary: UserAvatar(uid: f),
                        title: UserName(uid: f),
                      ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving || (_addMode && _selected.isEmpty) ? null : _submit,
              child: _saving
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_addMode
                      ? 'Tambahkan (${_selected.length})'
                      : 'Buat grup (${_selected.length + 1} anggota)'),
            ),
          ),
        ],
      ),
    );
  }
}
