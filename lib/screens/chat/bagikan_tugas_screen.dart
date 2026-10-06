import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/bahasa.dart';
import '../../models/chat_payload.dart';
import '../../models/chat_room.dart';
import '../../models/tugas.dart';
import '../../services/chat_repository.dart';
import '../../services/friend_repository.dart';
import 'chat_widgets.dart';

/// Membagikan tugas ke teman atau grup lewat chat (terenkripsi).
/// Penerima bisa menyimpannya ke daftar tugasnya sendiri.
class BagikanTugasScreen extends StatefulWidget {
  const BagikanTugasScreen({super.key, required this.me, required this.tugas});
  final String me;
  final Tugas tugas;

  @override
  State<BagikanTugasScreen> createState() => _BagikanTugasScreenState();
}

class _BagikanTugasScreenState extends State<BagikanTugasScreen> {
  final _repo = ChatRepository.instance;
  late final _rooms = _repo.watchRooms(widget.me);
  late final _friends = FriendRepository.instance.watchFriends(widget.me);

  /// Tujuan terpilih: id chat, atau `teman:{uid}` untuk teman yang belum
  /// pernah di-chat.
  final _pilih = <String>{};
  bool _mengirim = false;

  Future<void> _kirim(List<ChatRoom> rooms) async {
    setState(() => _mengirim = true);
    final isi = IsiPesan.tugas(TugasBagikan.dariTugas(widget.tugas));
    var gagal = 0;
    for (final tujuan in _pilih) {
      try {
        var id = tujuan;
        if (tujuan.startsWith('teman:')) {
          id = await _repo.openPrivate(me: widget.me, other: tujuan.substring(6));
        }
        final room = await _repo.watchRoom(id).firstWhere((r) => r != null);
        final key = await _repo.roomKey(room!, widget.me);
        if (key == null) throw StateError('Kunci chat belum tersedia');
        await _repo.sendIsi(room, widget.me, key, isi);
      } catch (_) {
        gagal++;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(gagal == 0
          ? tr('Tugas dibagikan ke {n} chat', {'n': _pilih.length})
          : tr('Gagal membagikan ke {n} chat. Coba lagi nanti.', {'n': gagal})),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.tugas;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Bagikan tugas'))),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _rooms,
        builder: (context, roomSnap) => StreamBuilder<List<String>>(
          stream: _friends,
          builder: (context, friendSnap) {
            final rooms = roomSnap.data?.where((r) => r.canSend(widget.me)).toList();
            final friends = friendSnap.data;
            if (rooms == null || friends == null) return const Center(child: CircularProgressIndicator());
            final sudahAdaChat = {
              for (final r in rooms)
                if (!r.isGroup) r.otherMember(widget.me)
            };
            final temanBaru = friends.where((f) => !sudahAdaChat.contains(f)).toList();
            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(t.judul),
                    subtitle: Text(
                      [
                        if (t.mapel.isNotEmpty) t.mapel,
                        tr('Deadline {waktu}', {'waktu': DateFormat('d MMM y, HH:mm', kodeTanggal).format(t.deadline)}),
                      ].join(' · '),
                    ),
                  ),
                ),
                if (t.lampiran.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      tr('Lampiran tidak ikut dibagikan. Kirim filenya lewat tombol + di chat jika perlu.'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: rooms.isEmpty && temanBaru.isEmpty
                      ? Center(child: Text(tr('Belum ada teman atau grup. Tambah teman dulu di tab Chat.')))
                      : ListView(
                          children: [
                            for (final r in rooms)
                              CheckboxListTile(
                                value: _pilih.contains(r.id),
                                onChanged: (v) => setState(() => v == true ? _pilih.add(r.id) : _pilih.remove(r.id)),
                                secondary: r.isGroup ? GroupAvatar(room: r) : UserAvatar(uid: r.otherMember(widget.me)),
                                title: r.isGroup ? Text(r.name) : UserName(uid: r.otherMember(widget.me)),
                                subtitle: r.isGroup ? Text(tr('Grup · {n} anggota', {'n': r.members.length})) : null,
                              ),
                            for (final f in temanBaru)
                              CheckboxListTile(
                                value: _pilih.contains('teman:$f'),
                                onChanged: (v) =>
                                    setState(() => v == true ? _pilih.add('teman:$f') : _pilih.remove('teman:$f')),
                                secondary: UserAvatar(uid: f),
                                title: UserName(uid: f),
                              ),
                          ],
                        ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _pilih.isEmpty || _mengirim ? null : () => _kirim(rooms),
                      icon: _mengirim
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(tr('Kirim ke {n} chat', {'n': _pilih.length})),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
