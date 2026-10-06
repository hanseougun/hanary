import 'package:flutter/material.dart';

import '../../l10n/bahasa.dart';
import '../../models/chat_room.dart';
import '../../services/chat_repository.dart';
import '../../services/obrolan_saya.dart';
import 'chat_room_screen.dart';
import 'chat_widgets.dart';

/// Satu pesan berbintang yang sudah dibuka.
class _Berbintang {
  const _Berbintang({required this.room, required this.pesan, required this.ringkas});
  final ChatRoom room;
  final ChatMessage pesan;
  final String ringkas;
}

/// Daftar pesan yang saya beri bintang (semua chat, atau satu [chatId]).
class PesanBerbintangScreen extends StatefulWidget {
  const PesanBerbintangScreen({super.key, required this.me, this.chatId});
  final String me;
  final String? chatId;

  @override
  State<PesanBerbintangScreen> createState() => _PesanBerbintangScreenState();
}

class _PesanBerbintangScreenState extends State<PesanBerbintangScreen> {
  late final _rooms = ChatRepository.instance.watchRooms(widget.me);
  Future<List<_Berbintang>>? _daftar;
  String? _tanda;

  /// Muat ulang hanya jika daftar bintang atau daftar chat berubah.
  Future<List<_Berbintang>> _muat(List<ChatRoom> rooms) {
    final saya = ObrolanSaya.instance;
    final tanda = [
      for (final r in rooms)
        if (saya.dari(r.id).bintang.isNotEmpty) '${r.id}:${saya.dari(r.id).bintang.join(',')}:${r.keys.length}',
    ].join('|');
    if (tanda != _tanda || _daftar == null) {
      _tanda = tanda;
      _daftar = _bukaSemua(rooms);
    }
    return _daftar!;
  }

  Future<List<_Berbintang>> _bukaSemua(List<ChatRoom> rooms) async {
    final repo = ChatRepository.instance;
    final hasil = <_Berbintang>[];
    for (final room in rooms) {
      if (widget.chatId != null && room.id != widget.chatId) continue;
      final status = ObrolanSaya.instance.dari(room.id);
      if (status.bintang.isEmpty) continue;
      final key = await repo.roomKey(room, widget.me);
      if (key == null) continue;
      for (final id in status.bintang) {
        try {
          final m = await repo.ambilPesan(room.id, id);
          if (m == null || status.pesanTerhapus(m.createdAt)) continue;
          String ringkas;
          if (m.ditarik) {
            ringkas = tr('Pesan ini ditarik');
          } else {
            final isi = await repo.decryptIsi(room.id, m.kind, m.box, key);
            ringkas = isi?.ringkas() ?? tr('Pesan tidak bisa dibuka');
          }
          hasil.add(_Berbintang(room: room, pesan: m, ringkas: ringkas));
        } catch (_) {}
      }
    }
    hasil.sort((a, b) => (b.pesan.createdAt ?? DateTime(0)).compareTo(a.pesan.createdAt ?? DateTime(0)));
    return hasil;
  }

  Future<void> _hapusBintang(_Berbintang b) async {
    try {
      await ObrolanSaya.instance.beriBintang(widget.me, b.room.id, b.pesan.id, false);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Pesan berbintang'))),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _rooms,
        builder: (context, roomSnap) => ListenableBuilder(
          listenable: ObrolanSaya.instance,
          builder: (context, _) {
            final rooms = roomSnap.data;
            if (rooms == null) return const Center(child: CircularProgressIndicator());
            return FutureBuilder<List<_Berbintang>>(
              future: _muat(rooms),
              builder: (context, snap) {
                final daftar = snap.data;
                if (daftar == null) return const Center(child: CircularProgressIndicator());
                if (daftar.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_outline_rounded, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(tr('Belum ada pesan berbintang'), style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            tr('Tekan lama sebuah pesan di chat, lalu pilih Beri bintang agar mudah dicari lagi.'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: daftar.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = daftar[i];
                    final room = b.room;
                    final pengirim = b.pesan.senderId == widget.me
                        ? Text(tr('Kamu'), style: theme.textTheme.labelLarge)
                        : UserName(uid: b.pesan.senderId, style: theme.textTheme.labelLarge);
                    return ListTile(
                      leading: UserAvatar(uid: b.pesan.senderId),
                      title: Row(
                        children: [
                          Flexible(child: pengirim),
                          if (widget.chatId == null) ...[
                            Icon(Icons.arrow_right_rounded, color: theme.colorScheme.outline),
                            Flexible(
                              child: room.isGroup
                                  ? Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis)
                                  : room.otherMember(widget.me) == b.pesan.senderId
                                      ? Text(tr('Kamu'))
                                      : UserName(uid: room.otherMember(widget.me)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(b.ringkas, maxLines: 3, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatChatTime(b.pesan.createdAt), style: theme.textTheme.labelSmall),
                          InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _hapusBintang(b),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                            ),
                          ),
                        ],
                      ),
                      // Dari dalam chat: kembali ke chat itu lalu menuju pesannya.
                      onTap: widget.chatId != null
                          ? () => Navigator.of(context).pop(b.pesan.id)
                          : () => Navigator.of(context).push(MaterialPageRoute<void>(
                                builder: (_) => ChatRoomScreen(chatId: room.id, me: widget.me, sorotPesan: b.pesan.id),
                              )),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
