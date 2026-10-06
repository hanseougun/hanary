import 'dart:async';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../models/chat_payload.dart';
import '../../models/chat_room.dart';
import '../../models/tugas.dart';
import '../../services/chat_files.dart';
import '../../services/chat_notifier.dart';
import '../../services/chat_repository.dart';
import '../../services/draf_chat.dart';
import '../../services/edit_gambar.dart';
import '../../services/notifikasi_service.dart';
import '../../services/pesan_dihapus.dart';
import '../../services/tugas_repository.dart';
import '../../theme/hanary_theme.dart';
import 'chat_widgets.dart';
import 'group_info_screen.dart';
import 'panggilan_screen.dart';
import 'pesan_suara.dart';
import 'profil_orang_screen.dart';

/// Halaman percakapan (pribadi atau grup).
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.chatId, required this.me, this.draft});
  final String chatId;
  final String me;

  /// Teks awal di kolom pesan (mis. saat membalas story).
  final String? draft;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

/// File yang sedang diunggah (ditampilkan sementara di bawah percakapan).
class _Unggahan {
  _Unggahan(this.nama, this.isGambar);
  final String nama;
  final bool isGambar;
  double progress = 0;
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _repo = ChatRepository.instance;
  late final _room = _repo.watchRoom(widget.chatId);
  late final _messages = _repo.watchMessages(widget.chatId);
  late final _input = TextEditingController(text: widget.draft);
  final _unggahan = <_Unggahan>[];

  Future<SecretKey?>? _keyFuture;
  String? _keySignature;
  bool _sending = false;
  final _fokus = FocusNode();

  /// Pesan yang sedang dibalas (tampil di atas kolom ketik).
  BalasanPesan? _balas;
  DateTime? _dibacaSampai;
  String? _statusDibaca;

  // Pesan suara yang sedang direkam.
  AudioRecorder? _perekam;
  DateTime? _mulaiRekam;
  Timer? _detikRekam;
  static const _maksRekam = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    ChatNotifier.instance.openChatId = widget.chatId;
    NotifikasiService.instance.hapusChat(widget.chatId);
    PesanDihapus.instance.muat(widget.chatId).then((_) {
      if (mounted) setState(() {});
    });
    // Draf yang belum terkirim dikembalikan ke kolom ketik.
    if (widget.draft == null) {
      DrafChat.instance.ambil(widget.chatId).then((teks) {
        if (mounted && _input.text.isEmpty && teks.isNotEmpty) _input.text = teks;
      });
    }
    _input.addListener(_simpanDraf);
  }

  void _simpanDraf() => DrafChat.instance.simpan(widget.chatId, _input.text);

  /// Mengambil pesan yang sedang dibalas, lalu menutup kutipannya.
  BalasanPesan? _ambilBalas() {
    final b = _balas;
    if (b != null && mounted) setState(() => _balas = null);
    return b;
  }

  void _mulaiBalas(BalasanPesan b) {
    setState(() => _balas = b);
    _fokus.requestFocus();
  }

  @override
  void dispose() {
    if (ChatNotifier.instance.openChatId == widget.chatId) ChatNotifier.instance.openChatId = null;
    _input.removeListener(_simpanDraf);
    DrafChat.instance.simpan(widget.chatId, _input.text, segera: true);
    _input.dispose();
    _fokus.dispose();
    _detikRekam?.cancel();
    _perekam?.cancel().whenComplete(() => _perekam?.dispose());
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

  /// Menandai sudah dibaca saat ada pesan baru dari orang lain.
  void _tandaiDibaca(ChatRoom room, List<ChatMessage> messages) {
    final terbaru = messages.where((m) => m.senderId != widget.me && m.createdAt != null).firstOrNull;
    final publish = UserFeed.of(widget.me).last?.kirimDibaca ?? true;
    final status = '${room.status.name}|$publish';
    final waktu = terbaru?.createdAt;
    if (waktu == null) return;
    if (_dibacaSampai != null && !waktu.isAfter(_dibacaSampai!) && _statusDibaca == status) return;
    _dibacaSampai = waktu;
    _statusDibaca = status;
    _repo.markRead(room, widget.me, publish: publish).catchError((Object _) {});
  }

  Future<void> _send(ChatRoom room, SecretKey key) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final balas = _balas;
    try {
      await _repo.send(room, widget.me, key, text, balas: balas);
      _input.clear();
      if (mounted && identical(_balas, balas)) setState(() => _balas = null);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _mulaiMerekam() async {
    final perekam = _perekam ??= AudioRecorder();
    try {
      if (!await perekam.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izinkan mikrofon untuk mengirim pesan suara.')),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      await perekam.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 22050, numChannels: 1),
        path: '${dir.path}/rekaman_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      HapticFeedback.mediumImpact();
      setState(() => _mulaiRekam = DateTime.now());
      _detikRekam = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        setState(() {});
        if (DateTime.now().difference(_mulaiRekam!) >= _maksRekam) _kirimRekaman();
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _batalRekam() {
    _detikRekam?.cancel();
    _perekam?.cancel();
    setState(() => _mulaiRekam = null);
  }

  ChatRoom? _roomTerakhir;
  SecretKey? _kunciTerakhir;

  Future<void> _kirimRekaman() async {
    final mulai = _mulaiRekam;
    final room = _roomTerakhir;
    final key = _kunciTerakhir;
    if (mulai == null || room == null || key == null) return;
    _detikRekam?.cancel();
    setState(() => _mulaiRekam = null);
    final durasi = DateTime.now().difference(mulai);
    try {
      final path = await _perekam?.stop();
      if (path == null) return;
      final file = File(path);
      if (durasi < const Duration(seconds: 1)) {
        await file.delete().catchError((Object _) => file);
        return;
      }
      final isi = await file.readAsBytes();
      await file.delete().catchError((Object _) => file);
      final u = _Unggahan('Pesan suara (${formatDurasi(durasi.inMilliseconds)})', false);
      setState(() => _unggahan.add(u));
      try {
        final berkas = await ChatFiles.instance.unggah(
          chatId: room.id,
          me: widget.me,
          key: key,
          nama: 'pesan-suara.m4a',
          isi: isi,
          onProgress: (p) {
            if (mounted) setState(() => u.progress = p);
          },
        );
        await _repo.sendIsi(
          room,
          widget.me,
          key,
          IsiPesan.berkas(MessageKind.suara, berkas.denganDurasi(durasi.inMilliseconds)),
          balas: _ambilBalas(),
        );
      } finally {
        if (mounted) setState(() => _unggahan.remove(u));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _lampirkan(ChatRoom room, SecretKey key) async {
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PilihanLampiran(icon: Icons.photo_library, label: 'Galeri', warna: Colors.purple, nilai: 'galeri'),
              _PilihanLampiran(icon: Icons.photo_camera, label: 'Kamera', warna: Colors.pink, nilai: 'kamera'),
              _PilihanLampiran(icon: Icons.insert_drive_file, label: 'File', warna: Colors.indigo, nilai: 'file'),
              _PilihanLampiran(icon: Icons.assignment, label: 'Tugas', warna: Colors.teal, nilai: 'tugas'),
            ],
          ),
        ),
      ),
    );
    if (pilihan == null || !mounted) return;
    try {
      switch (pilihan) {
        case 'galeri' || 'kamera':
          final foto = await ImagePicker().pickImage(
            source: pilihan == 'galeri' ? ImageSource.gallery : ImageSource.camera,
            maxWidth: 1600,
            maxHeight: 1600,
            imageQuality: 75,
          );
          if (foto == null || !mounted) return;
          // Edit dulu (potong, putar) sebelum dikirim.
          final hasil = await editGambar(context, foto.path);
          if (hasil == null) return;
          await _kirimBerkas(room, key, 'foto.jpg', await File(hasil).readAsBytes(), isGambar: true);
        case 'file':
          final hasil = await FilePicker.pickFiles();
          for (final f in hasil) {
            final ukuran = await f.length();
            if (ukuran != null && ukuran > ChatFiles.maxUkuran) throw const FileTerlaluBesar();
            final bytes = await f.xFile.readAsBytes();
            final isGambar = const ['.jpg', '.jpeg', '.png', '.gif', '.webp'].any(f.name.toLowerCase().endsWith);
            await _kirimBerkas(room, key, f.name, bytes, isGambar: isGambar);
          }
        case 'tugas':
          final tugas = await pilihTugas(context, widget.me);
          if (tugas == null) return;
          await _repo.sendIsi(
            room,
            widget.me,
            key,
            IsiPesan.tugas(TugasBagikan.dariTugas(tugas)),
            balas: _ambilBalas(),
          );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _kirimBerkas(
    ChatRoom room,
    SecretKey key,
    String nama,
    List<int> isi, {
    required bool isGambar,
  }) async {
    if (isi.length > ChatFiles.maxUkuran) throw const FileTerlaluBesar();
    final u = _Unggahan(nama, isGambar);
    setState(() => _unggahan.add(u));
    try {
      final berkas = await ChatFiles.instance.unggah(
        chatId: room.id,
        me: widget.me,
        key: key,
        nama: nama,
        isi: isi is Uint8List ? isi : Uint8List.fromList(isi),
        onProgress: (p) {
          if (mounted) setState(() => u.progress = p);
        },
      );
      final keterangan = _input.text.trim();
      if (isGambar && keterangan.isNotEmpty) _input.clear();
      await _repo.sendIsi(
        room,
        widget.me,
        key,
        IsiPesan.berkas(
          isGambar ? MessageKind.gambar : MessageKind.file,
          berkas,
          teks: isGambar ? keterangan : '',
        ),
        balas: _ambilBalas(),
      );
    } finally {
      if (mounted) setState(() => _unggahan.remove(u));
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
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: InkWell(
              onTap: room.isGroup
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => GroupInfoScreen(chatId: room.id, me: widget.me),
                      ))
                  : () => bukaProfil(context, other),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar-${room.id}',
                    child: room.isGroup
                        ? GroupAvatar(room: room, radius: 18)
                        : UserAvatar(uid: other, radius: 18, showOnline: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        room.isGroup
                            ? Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis)
                            : UserName(uid: other),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: room.isGroup
                              ? Text('${room.members.length} anggota', style: theme.textTheme.bodySmall)
                              : PresenceText(uid: other, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (room.status == ChatStatus.aktif) ...[
                IconButton(
                  tooltip: 'Panggilan suara',
                  icon: const Icon(Icons.call_outlined),
                  onPressed: () => mulaiPanggilan(context, room: room, me: widget.me, video: false),
                ),
                IconButton(
                  tooltip: 'Panggilan video',
                  icon: const Icon(Icons.videocam_outlined),
                  onPressed: () => mulaiPanggilan(context, room: room, me: widget.me, video: true),
                ),
              ],
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
                  _bawah(room, key),
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
        final semua = snap.data;
        if (semua == null) return const Center(child: CircularProgressIndicator());
        final disembunyikan = PesanDihapus.instance.dari(room.id);
        final messages = semua.where((m) => !disembunyikan.contains(m.id)).toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tandaiDibaca(room, messages);
        });
        final lihatDibaca = UserFeed.of(widget.me).last?.kirimDibaca ?? true;
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length + _unggahan.length + 1,
          itemBuilder: (context, i) {
            if (i < _unggahan.length) return _BubbleUnggah(unggahan: _unggahan[_unggahan.length - 1 - i]);
            i -= _unggahan.length;
            if (i == messages.length) return const EncryptedNote();
            final m = messages[i];
            final older = i + 1 < messages.length ? messages[i + 1] : null;
            final hariBaru = older == null || !_hariSama(older.createdAt, m.createdAt);
            final bubble = _Bubble(
              key: ValueKey(m.id),
              onHapusUntukSaya: () async {
                await PesanDihapus.instance.sembunyikan(room.id, m.id);
                if (mounted) setState(() {});
              },
              room: room,
              message: m,
              roomKey: key,
              me: widget.me,
              onBalas: _mulaiBalas,
              isMine: m.senderId == widget.me,
              showSender: room.isGroup && m.senderId != widget.me && (older?.senderId != m.senderId || hariBaru),
              dibaca: lihatDibaca && _sudahDibaca(room, m),
            );
            if (!hariBaru) return bubble;
            return Column(children: [_PemisahHari(waktu: m.createdAt ?? DateTime.now()), bubble]);
          },
        );
      },
    );
  }

  static bool _hariSama(DateTime? a, DateTime? b) {
    a ??= DateTime.now();
    b ??= DateTime.now();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Pesan saya sudah dibaca semua anggota lain (yang menyalakan tanda dibaca).
  bool _sudahDibaca(ChatRoom room, ChatMessage m) {
    final waktu = m.createdAt;
    if (m.senderId != widget.me || waktu == null) return false;
    final lain = room.members.where((u) => u != widget.me).toList();
    if (lain.isEmpty) return false;
    return lain.every((u) {
      final r = room.readAt[u];
      return r != null && !r.isBefore(waktu);
    });
  }

  Widget _bawah(ChatRoom room, SecretKey key) {
    final me = widget.me;
    final other = room.otherMember(me);
    if (room.isIncomingRequest(me)) {
      return _Banner(
        icon: Icons.mark_chat_unread_outlined,
        teks: 'Kalian belum berteman. Terima permintaan pesan ini agar bisa saling membalas?',
        aksi: [
          OutlinedButton(
            onPressed: () => _repo.rejectRequest(room.id).catchError((Object e) {
              if (mounted) showError(context, e);
            }),
            child: const Text('Tolak'),
          ),
          FilledButton(
            onPressed: () => _repo.acceptRequest(room.id).catchError((Object e) {
              if (mounted) showError(context, e);
            }),
            child: const Text('Terima'),
          ),
        ],
      );
    }
    if (room.status == ChatStatus.ditolak) {
      final sayaPenolak = room.requester != me;
      return _Banner(
        icon: Icons.block,
        teks: sayaPenolak
            ? 'Kamu menolak permintaan pesan ini.'
            : 'Permintaan pesanmu tidak diterima. Kirim permintaan pertemanan agar bisa chat.',
        aksi: [
          if (sayaPenolak)
            FilledButton.tonal(
              onPressed: () => _repo.acceptRequest(room.id),
              child: const Text('Terima sekarang'),
            ),
        ],
      );
    }
    if (room.isOutgoingRequest(me) && room.requestSent) {
      return _Banner(
        icon: Icons.hourglass_top,
        teks: 'Permintaan pesan terkirim. Kamu bisa mengirim pesan lagi setelah dia menerimanya.',
        aksi: const [],
        extra: UserName(uid: other, style: Theme.of(context).textTheme.labelLarge),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (room.isOutgoingRequest(me))
          const _Banner(
            icon: Icons.info_outline,
            teks: 'Kalian belum berteman. Kamu hanya bisa mengirim 1 pesan sampai dia menerima permintaanmu.',
            aksi: [],
          ),
        _inputBar(room, key),
      ],
    );
  }

  Widget _inputBar(ChatRoom room, SecretKey key) {
    _roomTerakhir = room;
    _kunciTerakhir = key;
    final bolehLampiran = room.status == ChatStatus.aktif || room.canSend(widget.me);
    final mulai = _mulaiRekam;
    if (mulai != null) {
      return BilahRekam(
        durasi: DateTime.now().difference(mulai),
        onBatal: _batalRekam,
        onKirim: _kirimRekaman,
      );
    }
    final balas = _balas;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: balas == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
                    child: Row(
                      children: [
                        Icon(Icons.reply_rounded, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: KutipanBalasan(balas: balas, me: widget.me)),
                        IconButton(
                          tooltip: 'Batal membalas',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _balas = null),
                        ),
                      ],
                    ),
                  ),
          ),
          _barisKetik(room, key, bolehLampiran),
        ],
      ),
    );
  }

  Widget _barisKetik(ChatRoom room, SecretKey key, bool bolehLampiran) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (bolehLampiran)
            IconButton(
              tooltip: 'Kirim foto, file, atau tugas',
              onPressed: () => _lampirkan(room, key),
              icon: const Icon(Icons.add_circle_outline),
            ),
          Expanded(
            child: TextField(
              controller: _input,
              focusNode: _fokus,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Tulis pesan',
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Kolom kosong: tombol mikrofon untuk pesan suara.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _input,
            builder: (context, nilai, _) {
              if (nilai.text.trim().isEmpty && bolehLampiran) {
                return IconButton.filled(
                  tooltip: 'Rekam pesan suara',
                  onPressed: _mulaiMerekam,
                  icon: const Icon(Icons.mic),
                );
              }
              return IconButton.filled(
                tooltip: 'Kirim',
                onPressed: _sending ? null : () => _send(room, key),
                icon: const Icon(Icons.send),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PilihanLampiran extends StatelessWidget {
  const _PilihanLampiran({required this.icon, required this.label, required this.warna, required this.nilai});
  final IconData icon;
  final String label;
  final Color warna;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pop(context, nilai),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(radius: 28, backgroundColor: warna, child: Icon(icon, color: Colors.white)),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.teks, required this.aksi, this.extra});
  final IconData icon;
  final String teks;
  final List<Widget> aksi;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (extra != null) extra!,
                      Text(teks, style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                    ],
                  ),
                ),
              ],
            ),
            if (aksi.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final a in aksi) Padding(padding: const EdgeInsets.only(left: 8), child: a),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PemisahHari extends StatelessWidget {
  const _PemisahHari({required this.waktu});
  final DateTime waktu;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final kemarin = now.subtract(const Duration(days: 1));
    bool sama(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    final label = sama(waktu, now)
        ? 'Hari ini'
        : sama(waktu, kemarin)
            ? 'Kemarin'
            : DateFormat('EEEE, d MMMM y', 'id_ID').format(waktu);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: theme.textTheme.labelSmall),
        ),
      ),
    );
  }
}

class _BubbleUnggah extends StatelessWidget {
  const _BubbleUnggah({required this.unggahan});
  final _Unggahan unggahan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(unggahan.isGambar ? Icons.image_outlined : Icons.insert_drive_file_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(unggahan.nama, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: unggahan.progress == 0 ? null : unggahan.progress),
            const SizedBox(height: 4),
            Text('Mengirim…', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({
    super.key,
    required this.room,
    required this.message,
    required this.roomKey,
    required this.me,
    required this.isMine,
    required this.showSender,
    required this.dibaca,
    required this.onHapusUntukSaya,
    required this.onBalas,
  });
  final Future<void> Function() onHapusUntukSaya;
  final void Function(BalasanPesan balas) onBalas;
  final ChatRoom room;
  final ChatMessage message;
  final SecretKey roomKey;
  final String me;
  final bool isMine;
  final bool showSender;
  final bool dibaca;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  late Future<IsiPesan?> _isi = _buka();
  late Future<BalasanPesan?> _kutipan = _bukaKutipan();
  IsiPesan? _terbuka;

  /// Jarak geser ke kanan untuk membalas.
  double _geser = 0;
  static const _batasGeser = 64.0;

  Future<BalasanPesan?> _bukaKutipan() async {
    final box = widget.message.balasBox;
    if (box == null || widget.message.ditarik) return null;
    final plain = await ChatRepository.instance.decrypt(widget.room.id, box, widget.roomKey);
    return plain == null ? null : BalasanPesan.parse(plain);
  }

  bool get _bisaDibalas => !widget.message.ditarik && !widget.message.pending && _terbuka != null;

  void _balas() {
    final isi = _terbuka;
    if (isi == null) return;
    widget.onBalas(BalasanPesan.dariPesan(widget.message.id, widget.message.senderId, isi));
  }

  Future<IsiPesan?> _buka() async {
    if (widget.message.ditarik) return null;
    final isi = await ChatRepository.instance
        .decryptIsi(widget.room.id, widget.message.kind, widget.message.box, widget.roomKey);
    _terbuka = isi;
    return isi;
  }

  /// Tekan lama pesan: salin, hapus untuk saya, atau tarik.
  Future<void> _menu() async {
    final m = widget.message;
    final isi = _terbuka;
    final bisaTarik = widget.isMine && !m.pending && !m.ditarik;
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bisaDibalas)
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Balas'),
                onTap: () => Navigator.pop(ctx, 'balas'),
              ),
            if (isi != null && isi.kind == MessageKind.teks)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Salin'),
                onTap: () => Navigator.pop(ctx, 'salin'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Hapus untuk saya'),
              subtitle: const Text('Hanya hilang dari HP-mu'),
              onTap: () => Navigator.pop(ctx, 'hapus'),
            ),
            if (bisaTarik)
              ListTile(
                leading: Icon(Icons.undo_rounded, color: Theme.of(ctx).colorScheme.error),
                title: Text('Tarik pesan', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                subtitle: const Text('Hilang untuk semua orang di chat ini'),
                onTap: () => Navigator.pop(ctx, 'tarik'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || pilihan == null) return;
    switch (pilihan) {
      case 'balas':
        _balas();
      case 'salin':
        await Clipboard.setData(ClipboardData(text: isi!.teks));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesan disalin')));
        }
      case 'hapus':
        await widget.onHapusUntukSaya();
      case 'tarik':
        final ok = await confirmDialog(
          context,
          title: 'Tarik pesan ini?',
          message: 'Pesan akan hilang untuk semua orang di chat ini.',
          action: 'Tarik',
        );
        if (!ok || !mounted) return;
        try {
          await ChatRepository.instance.tarik(widget.room, m, berkas: isi?.berkas);
        } catch (e) {
          if (mounted) showError(context, e);
        }
    }
  }

  @override
  void didUpdateWidget(covariant _Bubble old) {
    super.didUpdateWidget(old);
    if (old.message.box != widget.message.box ||
        old.message.ditarik != widget.message.ditarik ||
        old.roomKey != widget.roomKey) {
      _isi = _buka();
    }
    if (old.message.balasBox != widget.message.balasBox ||
        old.message.ditarik != widget.message.ditarik ||
        old.roomKey != widget.roomKey) {
      _kutipan = _bukaKutipan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMine = widget.isMine;
    final m = widget.message;
    final bg = isMine ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = isMine ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(isMine ? 16 * (1 - t) : -16 * (1 - t), 0), child: child),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          child: GestureDetector(
            onLongPress: _menu,
            // Geser pesan ke kanan untuk membalas.
            onHorizontalDragUpdate: (d) {
              if (!_bisaDibalas) return;
              final baru = (_geser + d.delta.dx).clamp(0.0, _batasGeser + 16);
              if (_geser < _batasGeser && baru >= _batasGeser) HapticFeedback.selectionClick();
              setState(() => _geser = baru);
            },
            onHorizontalDragEnd: (_) {
              if (_geser >= _batasGeser) _balas();
              setState(() => _geser = 0);
            },
            onHorizontalDragCancel: () => setState(() => _geser = 0),
            child: AnimatedContainer(
              duration: Duration(milliseconds: _geser == 0 ? 180 : 0),
              transform: Matrix4.translationValues(_geser, 0, 0),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                decoration: BoxDecoration(color: bg, borderRadius: radius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showSender)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: GestureDetector(
                          onTap: () => bukaProfil(context, m.senderId),
                          child: UserName(
                            uid: m.senderId,
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    if (m.balasBox != null && !m.ditarik)
                      FutureBuilder<BalasanPesan?>(
                        future: _kutipan,
                        builder: (context, snap) {
                          final b = snap.data;
                          if (b == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: KutipanBalasan(balas: b, me: widget.me, warnaTeks: fg),
                          );
                        },
                      ),
                    if (m.ditarik)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, size: 16, color: fg.withValues(alpha: 0.7)),
                          const SizedBox(width: 6),
                          Text(
                            isMine ? 'Kamu menarik pesan ini' : 'Pesan ini ditarik',
                            style: TextStyle(color: fg.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                          ),
                        ],
                      )
                    else
                      FutureBuilder<IsiPesan?>(
                        future: _isi,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return Text('…', style: TextStyle(color: fg));
                          }
                          final isi = snap.data;
                          if (isi == null) {
                            return Text(
                              'Pesan tidak bisa dibuka',
                              style: TextStyle(color: fg, fontStyle: FontStyle.italic),
                            );
                          }
                          return _isiPesan(context, isi, fg);
                        },
                      ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatChatTime(m.createdAt ?? DateTime.now()),
                          style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.7)),
                        ),
                        if (isMine && !m.ditarik) ...[
                          const SizedBox(width: 4),
                          Icon(
                            m.pending
                                ? Icons.schedule
                                : widget.dibaca
                                    ? Icons.done_all
                                    : Icons.check,
                            size: 15,
                            color: widget.dibaca ? const Color(0xFF0EA5E9) : fg.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _isiPesan(BuildContext context, IsiPesan isi, Color fg) {
    switch (isi.kind) {
      case MessageKind.teks:
        return Text(isi.teks, style: TextStyle(color: fg));
      case MessageKind.gambar:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GambarChat(chatId: widget.room.id, berkas: isi.berkas!, roomKey: widget.roomKey),
            if (isi.teks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(isi.teks, style: TextStyle(color: fg)),
              ),
          ],
        );
      case MessageKind.file:
        return _FileChat(chatId: widget.room.id, berkas: isi.berkas!, roomKey: widget.roomKey, fg: fg);
      case MessageKind.tugas:
        return _TugasChat(tugas: isi.tugas!, me: widget.me, isMine: widget.isMine);
      case MessageKind.suara:
        return SuaraChat(chatId: widget.room.id, berkas: isi.berkas!, roomKey: widget.roomKey, fg: fg);
    }
  }
}

/// Kutipan pesan yang dibalas (di dalam gelembung dan di atas kolom ketik).
class KutipanBalasan extends StatelessWidget {
  const KutipanBalasan({super.key, required this.balas, required this.me, this.warnaTeks});
  final BalasanPesan balas;
  final String me;
  final Color? warnaTeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = warnaTeks ?? theme.colorScheme.onSurface;
    final gayaNama =
        theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          balas.dari == me ? Text('Kamu', style: gayaNama) : UserName(uid: balas.dari, style: gayaNama),
          Text(
            balas.ringkas,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _GambarChat extends StatefulWidget {
  const _GambarChat({required this.chatId, required this.berkas, required this.roomKey});
  final String chatId;
  final BerkasChat berkas;
  final SecretKey roomKey;

  @override
  State<_GambarChat> createState() => _GambarChatState();
}

class _GambarChatState extends State<_GambarChat> {
  late Future<File> _file = ChatFiles.instance.unduh(widget.chatId, widget.berkas, widget.roomKey);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _file,
      builder: (context, snap) {
        final file = snap.data;
        Widget isi;
        if (snap.hasError) {
          isi = InkWell(
            onTap: () => setState(() {
              _file = ChatFiles.instance.unduh(widget.chatId, widget.berkas, widget.roomKey);
            }),
            child: const SizedBox(
              width: 220,
              height: 160,
              child: Center(child: Text('Gagal memuat foto.\nKetuk untuk coba lagi.', textAlign: TextAlign.center)),
            ),
          );
        } else if (file == null) {
          isi = const SizedBox(width: 220, height: 160, child: Center(child: CircularProgressIndicator()));
        } else {
          isi = GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _LihatGambar(file: file, tag: widget.berkas.fileId),
            )),
            child: Hero(
              tag: widget.berkas.fileId,
              child: Image.file(file, width: 240, fit: BoxFit.cover, cacheWidth: 720),
            ),
          );
        }
        return ClipRRect(borderRadius: BorderRadius.circular(12), child: isi);
      },
    );
  }
}

class _LihatGambar extends StatelessWidget {
  const _LihatGambar({required this.file, required this.tag});
  final File file;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Buka dengan aplikasi lain',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(file.path),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Hero(tag: tag, child: Image.file(file)),
        ),
      ),
    );
  }
}

class _FileChat extends StatefulWidget {
  const _FileChat({required this.chatId, required this.berkas, required this.roomKey, required this.fg});
  final String chatId;
  final BerkasChat berkas;
  final SecretKey roomKey;
  final Color fg;

  @override
  State<_FileChat> createState() => _FileChatState();
}

class _FileChatState extends State<_FileChat> {
  bool _memuat = false;

  Future<void> _buka() async {
    setState(() => _memuat = true);
    try {
      final file = await ChatFiles.instance.unduh(widget.chatId, widget.berkas, widget.roomKey);
      final hasil = await OpenFilex.open(file.path);
      if (hasil.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada aplikasi untuk membuka file ini.')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.berkas;
    final ext = b.nama.contains('.') ? b.nama.split('.').last.toUpperCase() : 'FILE';
    return InkWell(
      onTap: _memuat ? null : _buka,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.fg.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: _memuat
                  ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.description, size: 36, color: widget.fg),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.nama, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.fg)),
                  Text(
                    '$ext · ${formatUkuran(b.ukuran)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: widget.fg.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TugasChat extends StatefulWidget {
  const _TugasChat({required this.tugas, required this.me, required this.isMine});
  final TugasBagikan tugas;
  final String me;
  final bool isMine;

  @override
  State<_TugasChat> createState() => _TugasChatState();
}

class _TugasChatState extends State<_TugasChat> {
  bool _tersimpan = false;
  bool _menyimpan = false;

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await TugasRepository.instance.save(widget.me, widget.tugas.keTugas());
      if (!mounted) return;
      setState(() => _tersimpan = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas disimpan ke daftar tugasmu')),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.tugas;
    final lewat = t.deadline.isBefore(DateTime.now());
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: GayaHanary.dari(context).gradasiUtama,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Icon(Icons.assignment, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Tugas dibagikan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.judul, style: theme.textTheme.titleMedium),
                if (t.mapel.isNotEmpty) Text(t.mapel, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: lewat ? theme.colorScheme.error : theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('EEE, d MMM y · HH:mm', 'id_ID').format(t.deadline),
                        style: theme.textTheme.bodySmall?.copyWith(color: lewat ? theme.colorScheme.error : null),
                      ),
                    ),
                  ],
                ),
                if (t.catatan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(t.catatan, maxLines: 4, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                ],
                if (!widget.isMine) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _tersimpan || _menyimpan ? null : _simpan,
                      icon: Icon(_tersimpan ? Icons.check : Icons.add_task),
                      label: Text(_tersimpan ? 'Tersimpan' : 'Simpan ke tugasku'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Memilih salah satu tugas saya (untuk dikirim ke chat).
Future<Tugas?> pilihTugas(BuildContext context, String me) {
  return showModalBottomSheet<Tugas>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => StreamBuilder<List<Tugas>>(
        stream: TugasRepository.instance.watch(me),
        builder: (ctx, snap) {
          final list = snap.data;
          if (list == null) return const Center(child: CircularProgressIndicator());
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada tugas. Buat tugas dulu di Beranda.'));
          }
          return ListView(
            controller: scroll,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Pilih tugas yang mau dibagikan'),
              ),
              for (final t in list)
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(t.judul),
                  subtitle: Text(DateFormat('EEE, d MMM · HH:mm', 'id_ID').format(t.deadline)),
                  onTap: () => Navigator.pop(ctx, t),
                ),
            ],
          );
        },
      ),
    ),
  );
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
