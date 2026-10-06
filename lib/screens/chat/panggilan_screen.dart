import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../models/chat_room.dart';
import '../../services/chat_repository.dart';
import '../../services/friend_repository.dart';
import '../../services/notifikasi_service.dart';
import '../../services/panggilan_service.dart';
import '../../theme/hanary_theme.dart';
import 'chat_widgets.dart';

/// Server STUN gratis milik Google: membantu dua HP saling menemukan
/// alamatnya di internet. Suara/gambar tetap dikirim langsung antar HP.
const _konfigurasi = <String, dynamic>{
  'iceServers': [
    {
      'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302'],
    },
  ],
  'sdpSemantics': 'unified-plan',
};

const _layar = MethodChannel('hanary/nada');

/// Agar layar panggilan tetap muncul walau HP terkunci (hanya selama panggilan).
Future<void> _tampilDiAtasKunci(bool aktif) async {
  try {
    await _layar.invokeMethod('tampilDiAtasKunci', {'aktif': aktif});
  } catch (_) {}
}

/// Memulai panggilan dari halaman chat.
Future<void> mulaiPanggilan(
  BuildContext context, {
  required ChatRoom room,
  required String me,
  required bool video,
}) async {
  final layanan = PanggilanService.instance;
  if (layanan.sedangDibuka != null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masih ada panggilan yang berjalan.')));
    return;
  }
  try {
    final id = await layanan.buat(room: room, me: me, video: video);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PanggilanScreen(callId: id, me: me, video: video, chatId: room.id),
    ));
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

/// Membuka layar panggilan masuk (berdering) untuk [p].
Future<void> bukaPanggilanMasuk(NavigatorState nav, Panggilan p, String me, {bool langsungTerima = false}) async {
  final layanan = PanggilanService.instance;
  if (layanan.sedangDibuka != null) return;
  if (langsungTerima) {
    await NotifikasiService.instance.hapusPanggilan(p.id);
    await nav.push(MaterialPageRoute<void>(
      builder: (_) => PanggilanScreen(callId: p.id, me: me, video: p.video, chatId: p.chatId),
    ));
    return;
  }
  await nav.push(MaterialPageRoute<void>(builder: (_) => PanggilanMasukScreen(panggilan: p, me: me)));
}

/// Judul panggilan: nama grup, atau nama lawan bicara.
class _JudulPanggilan extends StatelessWidget {
  const _JudulPanggilan({required this.chatId, required this.me, this.style, this.cadangan});
  final String chatId;
  final String me;
  final TextStyle? style;

  /// Ditampilkan jika chat-nya tidak bisa dibuka (saya diajak dari luar chat).
  final String? cadangan;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoom?>(
      stream: ChatRepository.instance.watchRoom(chatId),
      builder: (context, snap) {
        if (snap.hasError) return cadangan != null ? UserName(uid: cadangan!, style: style) : const SizedBox.shrink();
        final room = snap.data;
        if (room == null) return Text('…', style: style);
        if (room.isGroup) return Text(room.name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
        return UserName(uid: room.otherMember(me), style: style);
      },
    );
  }
}

class _LatarPanggilan extends StatelessWidget {
  const _LatarPanggilan({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gradasi = GayaHanary.dari(context).gradasi;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(gradasi.first, Colors.black, 0.55)!, Color.lerp(gradasi.last, Colors.black, 0.75)!],
        ),
      ),
      child: child,
    );
  }
}

/// Layar "panggilan masuk" dengan tombol Tolak dan Terima.
class PanggilanMasukScreen extends StatefulWidget {
  const PanggilanMasukScreen({super.key, required this.panggilan, required this.me});
  final Panggilan panggilan;
  final String me;

  @override
  State<PanggilanMasukScreen> createState() => _PanggilanMasukScreenState();
}

class _PanggilanMasukScreenState extends State<PanggilanMasukScreen> {
  StreamSubscription<Panggilan?>? _sub;
  Timer? _batas;
  bool _selesai = false;

  /// Layar ini terbuka sejak (batas berdering dihitung dari sini, karena
  /// orang yang diajak belakangan berdering lebih lambat dari awal panggilan).
  final _dibuka = DateTime.now();

  Panggilan get p => widget.panggilan;

  @override
  void initState() {
    super.initState();
    _tampilDiAtasKunci(true);
    PanggilanService.instance.sedangDibuka = p.id;
    // Bunyi dering lewat notifikasi panggilan.
    PanggilanService.tampilkanNotifMasuk(widget.me, p.id);
    _sub = PanggilanService.instance.pantau(p.id).listen((baru) {
      if (baru == null || !baru.bisaDiangkat(widget.me, dipanggil: _dibuka)) _tutup();
    });
    _batas = Timer(PanggilanService.batasBerdering, _tutup);
    NotifikasiService.instance.ketukPanggilan.addListener(_dariNotifikasi);
  }

  /// Tombol "Terima" di notifikasi ditekan saat layar ini terbuka.
  void _dariNotifikasi() {
    final k = NotifikasiService.instance.ketukPanggilan.value;
    if (k == null || k.$1 != p.id) return;
    NotifikasiService.instance.ketukPanggilan.value = null;
    if (k.$2) _terima();
  }

  void _tutup() {
    if (_selesai || !mounted) return;
    _selesai = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _batas?.cancel();
    NotifikasiService.instance.ketukPanggilan.removeListener(_dariNotifikasi);
    NotifikasiService.instance.hapusPanggilan(p.id);
    if (PanggilanService.instance.sedangDibuka == p.id) PanggilanService.instance.sedangDibuka = null;
    if (!_diterima) _tampilDiAtasKunci(false);
    super.dispose();
  }

  bool _diterima = false;

  Future<void> _terima() async {
    if (_selesai) return;
    _selesai = true;
    _diterima = true;
    await NotifikasiService.instance.hapusPanggilan(p.id);
    if (!mounted) return;
    PanggilanService.instance.sedangDibuka = null;
    await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => PanggilanScreen(callId: p.id, me: widget.me, video: p.video, chatId: p.chatId),
    ));
  }

  Future<void> _tolak() async {
    if (_selesai) return;
    _selesai = true;
    try {
      await PanggilanService.instance.tolak(p.id, widget.me);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final putih = theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800);
    return Scaffold(
      body: _LatarPanggilan(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              _Denyut(child: UserAvatar(uid: p.dari, radius: 56)),
              const SizedBox(height: 24),
              UserName(uid: p.dari, style: putih),
              if (p.grup) ...[
                const SizedBox(height: 4),
                _JudulPanggilan(
                  chatId: p.chatId,
                  me: widget.me,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                p.video ? 'Panggilan video masuk…' : 'Panggilan suara masuk…',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TombolBulat(
                      warna: const Color(0xFFDC2626),
                      ikon: Icons.call_end_rounded,
                      label: 'Tolak',
                      onTap: _tolak,
                    ),
                    _TombolBulat(
                      warna: const Color(0xFF16A34A),
                      ikon: p.video ? Icons.videocam_rounded : Icons.call_rounded,
                      label: 'Terima',
                      onTap: _terima,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layar panggilan yang sedang berlangsung (suara atau video, pribadi atau grup).
///
/// Setiap pasang peserta terhubung langsung (WebRTC). Peserta dengan uid
/// "lebih kecil" yang memulai penawaran, agar tidak saling tabrakan.
class PanggilanScreen extends StatefulWidget {
  const PanggilanScreen({
    super.key,
    required this.callId,
    required this.me,
    required this.video,
    required this.chatId,
  });
  final String callId;
  final String me;
  final bool video;
  final String chatId;

  @override
  State<PanggilanScreen> createState() => _PanggilanScreenState();
}

class _PanggilanScreenState extends State<PanggilanScreen> {
  final _layanan = PanggilanService.instance;
  late final _sinyal = FirebaseFirestore.instance.collection('panggilan').doc(widget.callId).collection('sinyal');

  MediaStream? _lokal;
  final _rendererLokal = RTCVideoRenderer();
  final _peer = <String, Future<RTCPeerConnection>>{};
  final _jauh = <String, RTCVideoRenderer>{};
  final _terhubung = <String>{};
  final _remoteSiap = <String>{};
  final _iceTertunda = <String, List<RTCIceCandidate>>{};
  Future<void> _antrean = Future.value();

  StreamSubscription<Panggilan?>? _subPanggilan;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subSinyal;
  Panggilan? _p;
  bool _siap = false;
  bool _selesai = false;
  bool _mic = true;
  late bool _kamera = widget.video;
  late bool _speaker = widget.video;
  DateTime? _mulaiBicara;
  Timer? _detik;
  Timer? _batasDering;

  bool get _pemanggil => _p?.dari == widget.me;

  @override
  void initState() {
    super.initState();
    _layanan.sedangDibuka = widget.callId;
    _tampilDiAtasKunci(true);
    _mulai();
  }

  Future<void> _mulai() async {
    try {
      await _rendererLokal.initialize();
      _lokal = await navigator.mediaDevices.getUserMedia({
        'audio': {'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true},
        'video': widget.video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 640},
                'height': {'ideal': 480},
                'frameRate': {'ideal': 24},
              }
            : false,
      });
      _rendererLokal.srcObject = _lokal;
      await Helper.setSpeakerphoneOn(_speaker);
    } catch (e) {
      await _akhiri(pesan: 'Izinkan mikrofon${widget.video ? ' dan kamera' : ''} untuk menelepon.');
      return;
    }
    if (!mounted || _selesai) return;
    setState(() => _siap = true);

    final awal = await _layanan.ambil(widget.callId);
    if (awal == null || awal.status == StatusPanggilan.selesai) {
      await _akhiri(pesan: 'Panggilan sudah berakhir.');
      return;
    }
    if (!awal.ikut.contains(widget.me)) await _layanan.gabung(widget.callId, widget.me);
    if (awal.dari == widget.me) {
      _batasDering = Timer(PanggilanService.batasBerdering, () {
        final p = _p;
        if (p != null && p.ikut.length <= 1 && _terhubung.isEmpty) {
          _layanan.tidakDijawab(widget.callId).catchError((Object _) {});
          _akhiri(pesan: 'Tidak dijawab');
        }
      });
    }
    _subSinyal = _sinyal.where('ke', isEqualTo: widget.me).snapshots().listen((s) {
      for (final c in s.docChanges) {
        if (c.type != DocumentChangeType.added) continue;
        final d = c.doc.data();
        if (d == null) continue;
        _antrean = _antrean.then((_) => _terimaSinyal(d)).catchError((Object e) {
          debugPrint('Sinyal panggilan gagal: $e');
        });
      }
    });
    _subPanggilan = _layanan.pantau(widget.callId).listen((p) {
      _antrean = _antrean.then((_) => _perbarui(p)).catchError((Object e) {
        debugPrint('Status panggilan gagal: $e');
      });
    });
  }

  Future<void> _perbarui(Panggilan? p) async {
    if (_selesai) return;
    if (p == null) return _akhiri(pesan: 'Panggilan berakhir');
    final sebelumnya = _p;
    _p = p;
    if (mounted) setState(() {});
    if (p.status == StatusPanggilan.selesai) {
      final ditolak = !p.ramai && p.tolak.isNotEmpty;
      return _akhiri(pesan: ditolak ? 'Panggilan ditolak' : 'Panggilan berakhir', sudahSelesai: true);
    }
    // Peserta baru: sambungkan.
    for (final u in p.ikut) {
      if (u == widget.me || _peer.containsKey(u)) continue;
      final pc = await _sambungan(u);
      if (widget.me.compareTo(u) < 0) {
        final tawaran = await pc.createOffer();
        await pc.setLocalDescription(tawaran);
        await _kirim(u, 'offer', {'sdp': tawaran.sdp, 'type': tawaran.type});
      }
    }
    // Peserta yang keluar: putuskan.
    for (final u in _peer.keys.toList()) {
      if (!p.ikut.contains(u) && (sebelumnya?.ikut.contains(u) ?? false)) await _putus(u);
    }
  }

  Future<RTCPeerConnection> _sambungan(String u) {
    return _peer[u] ??= () async {
      final pc = await createPeerConnection(_konfigurasi);
      for (final t in _lokal?.getTracks() ?? const <MediaStreamTrack>[]) {
        await pc.addTrack(t, _lokal!);
      }
      pc.onIceCandidate = (c) {
        if (c.candidate == null) return;
        _kirim(u, 'ice', {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex});
      };
      pc.onTrack = (e) async {
        if (e.streams.isEmpty) return;
        var r = _jauh[u];
        if (r == null) {
          r = RTCVideoRenderer();
          await r.initialize();
          _jauh[u] = r;
        }
        r.srcObject = e.streams.first;
        if (mounted) setState(() {});
      };
      pc.onConnectionState = (s) {
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _terhubung.add(u);
          _batasDering?.cancel();
          if (_mulaiBicara == null) {
            _mulaiBicara = DateTime.now();
            _detik = Timer.periodic(const Duration(seconds: 1), (_) {
              if (mounted) setState(() {});
            });
          }
        } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _terhubung.remove(u);
        }
        if (mounted) setState(() {});
      };
      return pc;
    }();
  }

  Future<void> _putus(String u) async {
    final pc = await _peer.remove(u);
    await pc?.close();
    final r = _jauh.remove(u);
    r?.srcObject = null;
    await r?.dispose();
    _terhubung.remove(u);
    _remoteSiap.remove(u);
    _iceTertunda.remove(u);
    if (mounted) setState(() {});
  }

  Future<void> _kirim(String ke, String jenis, Map<String, dynamic> data) {
    return _sinyal.add({
      'dari': widget.me,
      'ke': ke,
      'jenis': jenis,
      ...data,
      'ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _terimaSinyal(Map<String, dynamic> d) async {
    if (_selesai) return;
    final dari = d['dari'] as String?;
    if (dari == null || dari == widget.me) return;
    final pc = await _sambungan(dari);
    switch (d['jenis']) {
      case 'offer':
        await pc.setRemoteDescription(RTCSessionDescription(d['sdp'] as String?, 'offer'));
        await _pakaiIceTertunda(dari, pc);
        final jawaban = await pc.createAnswer();
        await pc.setLocalDescription(jawaban);
        await _kirim(dari, 'answer', {'sdp': jawaban.sdp, 'type': jawaban.type});
      case 'answer':
        await pc.setRemoteDescription(RTCSessionDescription(d['sdp'] as String?, 'answer'));
        await _pakaiIceTertunda(dari, pc);
      case 'ice':
        final c = RTCIceCandidate(
          d['candidate'] as String?,
          d['sdpMid'] as String?,
          (d['sdpMLineIndex'] as num?)?.toInt(),
        );
        if (_remoteSiap.contains(dari)) {
          await pc.addCandidate(c);
        } else {
          (_iceTertunda[dari] ??= []).add(c);
        }
    }
  }

  Future<void> _pakaiIceTertunda(String dari, RTCPeerConnection pc) async {
    _remoteSiap.add(dari);
    for (final c in _iceTertunda.remove(dari) ?? const <RTCIceCandidate>[]) {
      await pc.addCandidate(c);
    }
  }

  Future<void> _akhiri({String? pesan, bool sudahSelesai = false}) async {
    if (_selesai) return;
    _selesai = true;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);
    if (!sudahSelesai && _siap) {
      try {
        await _layanan.keluar(widget.callId, widget.me);
      } catch (_) {}
    }
    await _bersihkan();
    if (mounted) {
      nav.pop();
      if (pesan != null) messenger?.showSnackBar(SnackBar(content: Text(pesan)));
    }
  }

  bool _dibersihkan = false;

  Future<void> _bersihkan() async {
    if (_dibersihkan) return;
    _dibersihkan = true;
    _detik?.cancel();
    _batasDering?.cancel();
    await _subSinyal?.cancel();
    await _subPanggilan?.cancel();
    for (final u in _peer.keys.toList()) {
      await _putus(u);
    }
    for (final t in _lokal?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _lokal?.dispose();
    _lokal = null;
    _rendererLokal.srcObject = null;
  }

  @override
  void dispose() {
    if (!_selesai && _siap) _layanan.keluar(widget.callId, widget.me).catchError((Object _) {});
    _bersihkan();
    _rendererLokal.dispose();
    if (_layanan.sedangDibuka == widget.callId) _layanan.sedangDibuka = null;
    _tampilDiAtasKunci(false);
    super.dispose();
  }

  void _gantiMic() {
    setState(() => _mic = !_mic);
    for (final t in _lokal?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = _mic;
    }
  }

  void _gantiKamera() {
    setState(() => _kamera = !_kamera);
    for (final t in _lokal?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = _kamera;
    }
  }

  Future<void> _balikKamera() async {
    final t = _lokal?.getVideoTracks().firstOrNull;
    if (t != null) await Helper.switchCamera(t);
  }

  Future<void> _gantiSpeaker() async {
    setState(() => _speaker = !_speaker);
    await Helper.setSpeakerphoneOn(_speaker);
  }

  /// Paling banyak orang dalam satu panggilan.
  static const _maksPeserta = 8;

  /// Mengajak teman, atau memanggil ulang anggota chat yang belum mengangkat.
  Future<void> _tambahOrang() async {
    final p = _p;
    if (p == null) return;
    final teman = await FriendRepository.instance.watchFriends(widget.me).first.catchError((Object _) => <String>[]);
    if (!mounted) return;
    final panggilLagi = p.anggota.where((u) => u != widget.me && !p.ikut.contains(u) && !p.tolak.contains(u)).toList();
    final ajak = teman.where((u) => !p.anggota.contains(u)).toList();
    final penuh = p.anggota.length >= _maksPeserta;
    final dipilih = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Tambah ke panggilan', style: theme.textTheme.titleMedium),
              ),
              if (panggilLagi.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('Belum mengangkat')),
                for (final u in panggilLagi)
                  ListTile(
                    leading: UserAvatar(uid: u),
                    title: UserName(uid: u),
                    trailing: const Icon(Icons.ring_volume_rounded),
                    onTap: () => Navigator.pop(ctx, u),
                  ),
              ],
              const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('Teman')),
              if (penuh)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text('Panggilan sudah penuh ($_maksPeserta orang).'),
                )
              else if (ajak.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text('Semua temanmu sudah ada di panggilan ini.'),
                )
              else
                for (final u in ajak)
                  ListTile(
                    leading: UserAvatar(uid: u),
                    title: UserName(uid: u),
                    trailing: const Icon(Icons.add_call),
                    onTap: () => Navigator.pop(ctx, u),
                  ),
            ],
          ),
        );
      },
    );
    if (dipilih == null || !mounted) return;
    final terbaru = _p ?? p;
    try {
      await _layanan.undang(terbaru, widget.me, dipilih);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memanggil…')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  String get _status {
    final p = _p;
    final mulai = _mulaiBicara;
    if (mulai != null) {
      final d = DateTime.now().difference(mulai);
      final jam = d.inHours;
      final menit = (d.inMinutes % 60).toString().padLeft(2, '0');
      final detik = (d.inSeconds % 60).toString().padLeft(2, '0');
      return jam > 0 ? '$jam:$menit:$detik' : '$menit:$detik';
    }
    if (!_siap || p == null) return 'Menyiapkan…';
    if (p.ikut.length <= 1) return _pemanggil ? 'Memanggil…' : 'Menunggu…';
    return 'Menghubungkan…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoJauh = widget.video ? _jauh.entries.where((e) => _terhubung.contains(e.key)).toList() : const [];
    final lainIkut = (_p?.ikut ?? const <String>[]).where((u) => u != widget.me).toList();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _akhiri();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _LatarPanggilan(
          child: Stack(
            children: [
              // Video teman (satu = layar penuh, lebih = kotak-kotak).
              if (videoJauh.isNotEmpty)
                Positioned.fill(
                  child: videoJauh.length == 1
                      ? RTCVideoView(
                          videoJauh.first.value,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 3 / 4,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final e in videoJauh)
                              RTCVideoView(e.value, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                          ],
                        ),
                )
              else
                Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 96),
                        if (lainIkut.length <= 1)
                          _Denyut(
                            aktif: _mulaiBicara == null,
                            child: lainIkut.isEmpty
                                ? _AvatarChat(chatId: widget.chatId, me: widget.me)
                                : UserAvatar(uid: lainIkut.first, radius: 60),
                          )
                        else
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final u in lainIkut)
                                Column(
                                  children: [
                                    UserAvatar(uid: u, radius: 36),
                                    const SizedBox(height: 4),
                                    UserName(
                                      uid: u,
                                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              // Judul dan status di atas.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      children: [
                        _JudulPanggilan(
                          chatId: widget.chatId,
                          me: widget.me,
                          cadangan: _p?.dari,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            shadows: const [Shadow(blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _status,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            shadows: const [Shadow(blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tambah orang (panggilan video: di pojok kiri atas).
              if (widget.video && _p != null)
                Positioned(
                  left: 8,
                  top: 0,
                  child: SafeArea(
                    child: IconButton(
                      tooltip: 'Tambah orang',
                      color: Colors.white,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      onPressed: _tambahOrang,
                    ),
                  ),
                ),
              // Kamera sendiri (kecil di pojok).
              if (widget.video && _siap && _kamera)
                Positioned(
                  right: 16,
                  top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 72),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 110,
                          height: 150,
                          child: RTCVideoView(
                            _rendererLokal,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Tombol-tombol.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TombolKecil(
                          ikon: _mic ? Icons.mic_rounded : Icons.mic_off_rounded,
                          aktif: !_mic,
                          label: _mic ? 'Bisukan' : 'Bisu',
                          onTap: _gantiMic,
                        ),
                        if (widget.video) ...[
                          _TombolKecil(
                            ikon: _kamera ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                            aktif: !_kamera,
                            label: 'Kamera',
                            onTap: _gantiKamera,
                          ),
                          _TombolKecil(ikon: Icons.cameraswitch_rounded, label: 'Balik', onTap: _balikKamera),
                        ],
                        _TombolKecil(
                          ikon: _speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                          aktif: _speaker,
                          label: 'Speaker',
                          onTap: _gantiSpeaker,
                        ),
                        if (_p != null && !widget.video)
                          _TombolKecil(ikon: Icons.person_add_alt_1_rounded, label: 'Tambah', onTap: _tambahOrang),
                        _TombolBulat(
                          warna: const Color(0xFFDC2626),
                          ikon: Icons.call_end_rounded,
                          label: 'Akhiri',
                          onTap: () => _akhiri(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto grup atau lawan bicara saat belum ada yang mengangkat.
class _AvatarChat extends StatelessWidget {
  const _AvatarChat({required this.chatId, required this.me});
  final String chatId;
  final String me;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoom?>(
      stream: ChatRepository.instance.watchRoom(chatId),
      builder: (context, snap) {
        final room = snap.data;
        if (room == null) return const CircleAvatar(radius: 60);
        return room.isGroup ? GroupAvatar(room: room, radius: 60) : UserAvatar(uid: room.otherMember(me), radius: 60);
      },
    );
  }
}

/// Lingkaran berdenyut di belakang foto (saat berdering).
class _Denyut extends StatefulWidget {
  const _Denyut({required this.child, this.aktif = true});
  final Widget child;
  final bool aktif;

  @override
  State<_Denyut> createState() => _DenyutState();
}

class _DenyutState extends State<_Denyut> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = widget.aktif ? _c.value : 0.0;
        return Container(
          padding: EdgeInsets.all(10 + 14 * t),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: widget.aktif ? 0.18 * (1 - t) : 0),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _TombolBulat extends StatelessWidget {
  const _TombolBulat({required this.warna, required this.ikon, required this.label, required this.onTap});
  final Color warna;
  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: warna,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(18), child: Icon(ikon, color: Colors.white, size: 32)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _TombolKecil extends StatelessWidget {
  const _TombolKecil({required this.ikon, required this.label, required this.onTap, this.aktif = false});
  final IconData ikon;
  final String label;
  final VoidCallback onTap;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: aktif ? Colors.white : Colors.white.withValues(alpha: 0.18),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(ikon, color: aktif ? Colors.black87 : Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
