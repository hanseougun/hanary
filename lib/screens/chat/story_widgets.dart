import 'package:flutter/material.dart';

import '../../services/chat_repository.dart';
import '../../services/friend_repository.dart';
import '../../services/story_repository.dart';
import 'chat_room_screen.dart';
import 'chat_widgets.dart';

/// Warna latar gelembung story catatan.
const warnaStory = <Color>[
  Color(0xFF7C3AED),
  Color(0xFFF97362),
  Color(0xFF0EA5E9),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
];

Color _warna(int i) => warnaStory[i % warnaStory.length];

/// Deretan story catatan di atas daftar obrolan: catatan saya, lalu
/// catatan teman yang masih berlaku (24 jam).
class StoryBar extends StatefulWidget {
  const StoryBar({super.key, required this.me});
  final String me;

  @override
  State<StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<StoryBar> {
  late final _friends = FriendRepository.instance.watchFriends(widget.me);

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    return SizedBox(
      height: 132,
      child: StreamBuilder<List<String>>(
        stream: _friends,
        builder: (context, snap) {
          final friends = snap.data ?? const <String>[];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _StoryItem(key: ValueKey(me), uid: me, me: me),
              for (final f in friends) _StoryItem(key: ValueKey(f), uid: f, me: me),
            ],
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatefulWidget {
  const _StoryItem({super.key, required this.uid, required this.me});
  final String uid;
  final String me;

  @override
  State<_StoryItem> createState() => _StoryItemState();
}

class _StoryItemState extends State<_StoryItem> {
  late final _story = StoryRepository.instance.watch(widget.uid);
  String get uid => widget.uid;
  String get me => widget.me;
  bool get _milikSaya => uid == me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<StoryCatatan?>(
      stream: _story,
      builder: (context, snap) {
        final story = snap.data;
        if (story == null && !_milikSaya) return const SizedBox.shrink();
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _milikSaya
              ? tulisStory(context, me, story)
              : lihatStory(context, me, story!),
          child: SizedBox(
            width: 84,
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: story == null
                          ? _Gelembung(
                              key: const ValueKey('kosong'),
                              teks: 'Tulis catatan',
                              warna: theme.colorScheme.surfaceContainerHighest,
                              warnaTeks: theme.colorScheme.onSurfaceVariant,
                            )
                          : _Gelembung(
                              key: ValueKey(story.teks + story.warna.toString()),
                              teks: story.teks,
                              warna: _warna(story.warna),
                              warnaTeks: Colors.white,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: story == null
                            ? null
                            : LinearGradient(colors: [_warna(story.warna), _warna(story.warna + 1)]),
                      ),
                      child: UserAvatar(uid: uid, radius: 26, showOnline: !_milikSaya),
                    ),
                    if (_milikSaya && story == null)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(Icons.add, size: 14, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _milikSaya
                    ? Text('Catatanmu', style: theme.textTheme.labelSmall)
                    : UserName(uid: uid, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Gelembung kecil seperti balon percakapan.
class _Gelembung extends StatelessWidget {
  const _Gelembung({super.key, required this.teks, required this.warna, required this.warnaTeks});
  final String teks;
  final Color warna;
  final Color warnaTeks;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(
            teks,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: warnaTeks, fontSize: 11, height: 1.2),
          ),
        ),
        CustomPaint(size: const Size(10, 5), painter: _Ekor(warna)),
      ],
    );
  }
}

class _Ekor extends CustomPainter {
  _Ekor(this.warna);
  final Color warna;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = warna);
  }

  @override
  bool shouldRepaint(covariant _Ekor old) => old.warna != warna;
}

/// Menulis atau mengubah story catatan saya.
Future<void> tulisStory(BuildContext context, String me, StoryCatatan? lama) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _TulisStory(me: me, lama: lama),
  );
}

class _TulisStory extends StatefulWidget {
  const _TulisStory({required this.me, this.lama});
  final String me;
  final StoryCatatan? lama;

  @override
  State<_TulisStory> createState() => _TulisStoryState();
}

class _TulisStoryState extends State<_TulisStory> {
  late final _teks = TextEditingController(text: widget.lama?.teks);
  late int _warnaIdx = widget.lama?.warna ?? 0;
  bool _menyimpan = false;

  @override
  void dispose() {
    _teks.dispose();
    super.dispose();
  }

  Future<void> _jalankan(Future<void> Function() aksi) async {
    setState(() => _menyimpan = true);
    try {
      await aksi();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _menyimpan = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catatanmu', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Muncul sebagai gelembung di atas fotomu di daftar chat teman selama 24 jam.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _warna(_warnaIdx), borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: _teks,
              autofocus: true,
              maxLength: 60,
              maxLines: 3,
              minLines: 1,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Lagi ngerjain apa?',
                hintStyle: TextStyle(color: Colors.white70),
                counterStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < warnaStory.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _warnaIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _warnaIdx == i ? 34 : 28,
                    height: _warnaIdx == i ? 34 : 28,
                    decoration: BoxDecoration(
                      color: warnaStory[i],
                      shape: BoxShape.circle,
                      border: _warnaIdx == i ? Border.all(color: theme.colorScheme.onSurface, width: 2) : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.lama != null)
                TextButton.icon(
                  onPressed: _menyimpan ? null : () => _jalankan(() => StoryRepository.instance.hapus(widget.me)),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _menyimpan
                    ? null
                    : () {
                        final teks = _teks.text.trim();
                        if (teks.isEmpty) return;
                        _jalankan(() => StoryRepository.instance.simpan(widget.me, teks, _warnaIdx));
                      },
                child: const Text('Bagikan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Melihat story catatan teman dan membalasnya lewat chat pribadi.
Future<void> lihatStory(BuildContext context, String me, StoryCatatan story) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final sisa = StoryCatatan.masaBerlaku - DateTime.now().difference(story.dibuat);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: UserAvatar(uid: story.uid, showOnline: true),
                title: UserName(uid: story.uid, style: theme.textTheme.titleMedium),
                subtitle: Text('Hilang dalam ${sisa.inHours > 0 ? '${sisa.inHours} jam' : '${sisa.inMinutes} menit'}'),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: _warna(story.warna), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  story.teks,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  try {
                    final id = await ChatRepository.instance.openPrivate(me: me, other: story.uid);
                    navigator.pop();
                    await navigator.push(MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chatId: id,
                        me: me,
                        draft: 'Membalas catatanmu "${story.teks}": ',
                      ),
                    ));
                  } catch (e) {
                    if (ctx.mounted) showError(ctx, e);
                  }
                },
                icon: const Icon(Icons.reply),
                label: const Text('Balas'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
