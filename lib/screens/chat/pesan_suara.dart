import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import '../../l10n/bahasa.dart';
import '../../models/chat_payload.dart';
import '../../services/chat_files.dart';
import 'chat_widgets.dart';

/// Pesan suara di gelembung chat: tombol putar, garis kemajuan, dan durasi.
class SuaraChat extends StatefulWidget {
  const SuaraChat({super.key, required this.chatId, required this.berkas, required this.roomKey, required this.fg});
  final String chatId;
  final BerkasChat berkas;
  final SecretKey roomKey;
  final Color fg;

  @override
  State<SuaraChat> createState() => _SuaraChatState();
}

class _SuaraChatState extends State<SuaraChat> {
  /// Hanya satu pesan suara yang diputar sekaligus.
  static _SuaraChatState? _sedangDiputar;

  AudioPlayer? _pemutar;
  final _langganan = <StreamSubscription<Object?>>[];
  bool _memuat = false;
  PlayerState _status = PlayerState.stopped;
  Duration _posisi = Duration.zero;
  late Duration _durasi = Duration(milliseconds: widget.berkas.durasiMs);

  AudioPlayer _siapkanPemutar() {
    final p = _pemutar;
    if (p != null) return p;
    final baru = AudioPlayer();
    _langganan
      ..add(baru.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _status = s);
      }))
      ..add(baru.onPositionChanged.listen((d) {
        if (mounted) setState(() => _posisi = d);
      }))
      ..add(baru.onDurationChanged.listen((d) {
        if (mounted && d > Duration.zero) setState(() => _durasi = d);
      }))
      ..add(baru.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _posisi = Duration.zero);
      }));
    return _pemutar = baru;
  }

  Future<void> _putarAtauJeda() async {
    final pemutar = _siapkanPemutar();
    if (_status == PlayerState.playing) {
      await pemutar.pause();
      return;
    }
    if (_sedangDiputar != this) {
      await _sedangDiputar?._pemutar?.pause();
      _sedangDiputar = this;
    }
    if (_status == PlayerState.paused) {
      await pemutar.resume();
      return;
    }
    setState(() => _memuat = true);
    try {
      final file = await ChatFiles.instance.unduh(widget.chatId, widget.berkas, widget.roomKey);
      await pemutar.play(DeviceFileSource(file.path));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  void dispose() {
    if (_sedangDiputar == this) _sedangDiputar = null;
    for (final l in _langganan) {
      l.cancel();
    }
    _pemutar?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.fg;
    final total = _durasi.inMilliseconds;
    final kemajuan = total <= 0 ? 0.0 : (_posisi.inMilliseconds / total).clamp(0.0, 1.0);
    final berjalan = _status == PlayerState.playing || _status == PlayerState.paused;
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: _memuat
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: _status == PlayerState.playing ? tr('Jeda') : tr('Putar'),
                    onPressed: _putarAtauJeda,
                    icon: Icon(
                      _status == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      size: 36,
                      color: fg,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: kemajuan,
                    minHeight: 4,
                    color: fg,
                    backgroundColor: fg.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  berjalan ? formatDurasi(_posisi.inMilliseconds) : formatDurasi(total),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.mic, size: 18, color: fg.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

/// Bilah yang tampil saat sedang merekam: titik merah, waktu, batal, dan kirim.
class BilahRekam extends StatelessWidget {
  const BilahRekam({super.key, required this.durasi, required this.onBatal, required this.onKirim});
  final Duration durasi;
  final VoidCallback onBatal;
  final VoidCallback onKirim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: tr('Batal'),
              onPressed: onBatal,
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const _TitikMerah(),
                    const SizedBox(width: 10),
                    Text(formatDurasi(durasi.inMilliseconds), style: theme.textTheme.titleSmall),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('Merekam…'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(tooltip: tr('Kirim pesan suara'), onPressed: onKirim, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}

class _TitikMerah extends StatefulWidget {
  const _TitikMerah();

  @override
  State<_TitikMerah> createState() => _TitikMerahState();
}

class _TitikMerahState extends State<_TitikMerah> with SingleTickerProviderStateMixin {
  late final _kedip = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _kedip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_kedip),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
