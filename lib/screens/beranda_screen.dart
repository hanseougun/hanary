import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/kalimat_penyemangat.dart';
import '../models/app_user.dart';
import '../models/tugas.dart';
import '../services/notifikasi_service.dart';
import '../services/tugas_repository.dart';
import '../theme/hanary_theme.dart';
import '../widgets/hanary_widgets.dart';
import 'tugas_form_screen.dart';

/// Pilihan saring daftar tugas di Beranda.
enum _Saring { aktif, belum, dikerjakan, selesai, semua }

/// Warna khas tiap status tugas.
Color warnaStatus(StatusTugas s, ColorScheme c) => switch (s) {
      StatusTugas.belum => const Color(0xFFF59E0B),
      StatusTugas.dikerjakan => c.primary,
      StatusTugas.selesai => const Color(0xFF16A34A),
    };

IconData ikonStatus(StatusTugas s) => switch (s) {
      StatusTugas.belum => Icons.radio_button_unchecked_rounded,
      StatusTugas.dikerjakan => Icons.timelapse_rounded,
      StatusTugas.selesai => Icons.check_circle_rounded,
    };

/// "Terlambat", "Hari ini 23:59", "Besok 07:00", "3 hari lagi", ...
String sisaWaktu(DateTime deadline, DateTime sekarang) {
  final jam = DateFormat('HH:mm').format(deadline);
  final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
  final hariDeadline = DateTime(deadline.year, deadline.month, deadline.day);
  final selisih = hariDeadline.difference(hariIni).inDays;
  if (deadline.isBefore(sekarang)) return 'Terlambat';
  if (selisih == 0) return 'Hari ini $jam';
  if (selisih == 1) return 'Besok $jam';
  return '$selisih hari lagi';
}

/// Warna label mata pelajaran, selalu sama untuk nama yang sama.
Color warnaMapel(String mapel) {
  const palet = [
    Color(0xFF8E2ECE),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFE11D48),
  ];
  var h = 0;
  for (final c in mapel.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return palet[h % palet.length];
}

/// Halaman utama: ringkasan progres, tugas yang segera berakhir,
/// dan daftar tugas urut deadline terdekat.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.user});
  final AppUser user;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  late final Stream<List<Tugas>> _tugas = TugasRepository.instance.watch(widget.user.uid);
  StreamSubscription<List<Tugas>>? _sub;
  _Saring _saring = _Saring.aktif;
  final _kalimat = kalimatAcak();

  @override
  void initState() {
    super.initState();
    NotifikasiService.instance.mintaIzin();
    // Jadwal pengingat selalu mengikuti data tugas terbaru.
    _sub = TugasRepository.instance.watch(widget.user.uid).listen(NotifikasiService.instance.sinkron, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _bukaForm([Tugas? tugas]) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TugasFormScreen(uid: widget.user.uid, tugas: tugas),
    ));
  }

  Future<void> _ubahStatus(Tugas t, StatusTugas status) async {
    if (t.status == status) return;
    HapticFeedback.lightImpact();
    try {
      await TugasRepository.instance.setStatus(widget.user.uid, t.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(status == StatusTugas.selesai
              ? 'Mantap! "${t.judul}" selesai 🎉'
              : '"${t.judul}" ditandai ${status.label.toLowerCase()}'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => TugasRepository.instance.setStatus(widget.user.uid, t.id, t.status),
          ),
        ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah status: $e')));
    }
  }

  Future<void> _pilihStatus(Tugas t) async {
    final colors = Theme.of(context).colorScheme;
    final dipilih = await showModalBottomSheet<StatusTugas>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.judul, style: Theme.of(context).textTheme.titleMedium, maxLines: 2),
              const SizedBox(height: 12),
              for (final s in StatusTugas.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Ketuk(
                    radius: 16,
                    onTap: () => Navigator.pop(context, s),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: warnaStatus(s, colors).withValues(alpha: s == t.status ? 0.18 : 0.07),
                        border: Border.all(
                          color: s == t.status ? warnaStatus(s, colors) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(ikonStatus(s), color: warnaStatus(s, colors)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                          if (s == t.status) Icon(Icons.check_rounded, color: warnaStatus(s, colors)),
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
    if (dipilih != null) await _ubahStatus(t, dipilih);
  }

  bool _lolos(Tugas t) => switch (_saring) {
        _Saring.aktif => t.status != StatusTugas.selesai,
        _Saring.belum => t.status == StatusTugas.belum,
        _Saring.dikerjakan => t.status == StatusTugas.dikerjakan,
        _Saring.selesai => t.status == StatusTugas.selesai,
        _Saring.semua => true,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tugas baru', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<Tugas>>(
        stream: _tugas,
        builder: (context, snap) {
          final semua = snap.data ?? const <Tugas>[];
          final sekarang = DateTime.now();
          int hitung(StatusTugas s) => semua.where((t) => t.status == s).length;
          final aktif = semua.where((t) => t.status != StatusTugas.selesai).toList();
          final segera = aktif.take(6).toList();
          final tampil = semua.where(_lolos).toList();
          return CustomScrollView(
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList.list(children: [
                    MunculBertahap(child: _Header(user: widget.user, sekarang: sekarang)),
                    const SizedBox(height: 20),
                    MunculBertahap(
                      urutan: 1,
                      child: _KartuProgres(
                        total: semua.length,
                        selesai: hitung(StatusTugas.selesai),
                        mendesak: aktif.where((t) => t.deadline.difference(sekarang) < const Duration(days: 1)).length,
                        kalimat: _kalimat,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MunculBertahap(
                      urutan: 2,
                      child: Row(
                        children: [
                          for (final (i, s, saring) in [
                            (0, StatusTugas.belum, _Saring.belum),
                            (1, StatusTugas.dikerjakan, _Saring.dikerjakan),
                            (2, StatusTugas.selesai, _Saring.selesai),
                          ]) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                status: s,
                                value: hitung(s),
                                dipilih: _saring == saring,
                                onTap: () => setState(() => _saring = _saring == saring ? _Saring.aktif : saring),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              if (segera.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _JudulBagian(
                    judul: 'Segera berakhir',
                    ikon: Icons.local_fire_department_rounded,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 150,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: segera.length,
                      separatorBuilder: (context, i) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => MunculBertahap(
                        urutan: 3 + i,
                        geser: const Offset(32, 0),
                        child: _KartuSegera(
                          tugas: segera[i],
                          sekarang: sekarang,
                          onTap: () => _bukaForm(segera[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Row(
                    children: [
                      Text('Daftar tugas', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      Text(
                        '${tampil.length} tugas',
                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (final (s, label) in const [
                        (_Saring.aktif, 'Aktif'),
                        (_Saring.belum, 'Belum'),
                        (_Saring.dikerjakan, 'Dikerjakan'),
                        (_Saring.selesai, 'Selesai'),
                        (_Saring.semua, 'Semua'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _saring == s,
                            onSelected: (_) => setState(() => _saring = s),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (snap.hasError)
                SliverToBoxAdapter(
                  child: _Kosong(
                    icon: Icons.cloud_off_rounded,
                    judul: 'Gagal memuat tugas',
                    keterangan: '${snap.error}',
                  ),
                )
              else if (!snap.hasData)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (tampil.isEmpty)
                SliverToBoxAdapter(
                  child: _Kosong(
                    icon: semua.isEmpty ? Icons.edit_note_rounded : Icons.inbox_rounded,
                    judul: semua.isEmpty ? 'Belum ada tugas' : 'Tidak ada tugas di sini',
                    keterangan: semua.isEmpty
                        ? 'Tekan tombol "Tugas baru" untuk mencatat tugas pertamamu.'
                        : 'Coba pilih saringan lain.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  sliver: SliverList.builder(
                    itemCount: tampil.length,
                    itemBuilder: (context, i) {
                      final t = tampil[i];
                      return MunculBertahap(
                        key: ValueKey('${t.id}-$_saring'),
                        urutan: i,
                        child: _TugasCard(
                          tugas: t,
                          sekarang: sekarang,
                          onTap: () => _bukaForm(t),
                          onStatus: () => _pilihStatus(t),
                          onGeser: (s) => _ubahStatus(t, s),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.sekarang});
  final AppUser user;
  final DateTime sekarang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gaya = GayaHanary.dari(context);
    final foto = user.fotoUrl;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gaya.gradasiUtama),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.surface,
            backgroundImage: foto != null ? NetworkImage(foto) : null,
            child: foto == null
                ? Text(
                    user.sebutan.isNotEmpty ? user.sebutan[0].toUpperCase() : '?',
                    style: theme.textTheme.titleLarge,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${salamWaktu(sekarang)} 👋',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                user.sebutan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('EEE', 'id_ID').format(sekarang).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
              ),
              Text(
                '${sekarang.day}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kartu gradasi berisi cincin progres tugas selesai.
class _KartuProgres extends StatelessWidget {
  const _KartuProgres({
    required this.total,
    required this.selesai,
    required this.mendesak,
    required this.kalimat,
  });

  final int total;
  final int selesai;
  final int mendesak;
  final String kalimat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gaya = GayaHanary.dari(context);
    final rasio = total == 0 ? 0.0 : selesai / total;
    final String judul;
    if (total == 0) {
      judul = 'Siap mulai hari ini?';
    } else if (selesai == total) {
      judul = 'Semua tugas beres! 🎉';
    } else if (mendesak > 0) {
      judul = '$mendesak tugas deadline < 24 jam';
    } else {
      judul = '$selesai dari $total tugas selesai';
    }
    return Container(
      decoration: BoxDecoration(
        gradient: gaya.gradasiUtama,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gaya.gradasi.first.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: _Lingkaran(ukuran: 140, alpha: 0.12),
          ),
          Positioned(
            left: -20,
            bottom: -50,
            child: _Lingkaran(ukuran: 110, alpha: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: rasio),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, nilai, _) => SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: nilai,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                        ),
                        Center(
                          child: Text(
                            '${(nilai * 100).round()}%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROGRES TUGASMU',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        judul,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kalimat,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Lingkaran extends StatelessWidget {
  const _Lingkaran({required this.ukuran, required this.alpha});
  final double ukuran;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.status, required this.value, required this.dipilih, this.onTap});
  final StatusTugas status;
  final int value;
  final bool dipilih;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warna = warnaStatus(status, theme.colorScheme);
    final label = status == StatusTugas.dikerjakan ? 'Dikerjakan' : status.label;
    return Ketuk(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dipilih ? warna.withValues(alpha: 0.16) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dipilih ? warna : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: dipilih ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: warna.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(ikonStatus(status), size: 18, color: warna),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                '${v.round()}',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian({required this.judul, required this.ikon, required this.padding});
  final String judul;
  final IconData ikon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(ikon, size: 22, color: const Color(0xFFF97316)),
          const SizedBox(width: 6),
          Text(judul, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// Kartu kecil di deretan "Segera berakhir".
class _KartuSegera extends StatelessWidget {
  const _KartuSegera({required this.tugas, required this.sekarang, required this.onTap});
  final Tugas tugas;
  final DateTime sekarang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sisa = tugas.deadline.difference(sekarang);
    final mendesak = sisa < const Duration(days: 1);
    final warna = mendesak ? colors.error : (tugas.mapel.isEmpty ? colors.primary : warnaMapel(tugas.mapel));
    // Bilah sisa waktu: penuh jika masih 7 hari atau lebih.
    final sisaRasio = (sisa.inMinutes / const Duration(days: 7).inMinutes).clamp(0.0, 1.0);
    return Ketuk(
      onTap: onTap,
      child: Ink(
        width: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [warna.withValues(alpha: 0.22), warna.withValues(alpha: 0.06)],
          ),
          border: Border.all(color: warna.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(mendesak ? Icons.alarm_rounded : Icons.schedule_rounded, size: 16, color: warna),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sisaWaktu(tugas.deadline, sekarang),
                    style: theme.textTheme.labelMedium?.copyWith(color: warna, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tugas.judul,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (tugas.mapel.isNotEmpty)
              Text(
                tugas.mapel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: max(0.03, sisaRasio),
                minHeight: 5,
                color: warna,
                backgroundColor: warna.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu tugas di daftar. Geser ke kanan untuk menandai selesai,
/// geser ke kiri untuk menandai sedang dikerjakan.
class _TugasCard extends StatelessWidget {
  const _TugasCard({
    required this.tugas,
    required this.sekarang,
    required this.onTap,
    required this.onStatus,
    required this.onGeser,
  });

  final Tugas tugas;
  final DateTime sekarang;
  final VoidCallback onTap;
  final VoidCallback onStatus;
  final ValueChanged<StatusTugas> onGeser;

  Widget _latarGeser(Color warna, IconData ikon, String teks, Alignment align) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: align,
      decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: Colors.white),
          const SizedBox(width: 8),
          Text(teks, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selesai = tugas.status == StatusTugas.selesai;
    final mendesak = !selesai && tugas.deadline.difference(sekarang) < const Duration(days: 1);
    final warnaWaktu = selesai
        ? colors.onSurfaceVariant
        : mendesak
            ? colors.error
            : colors.primary;
    final aksen = selesai ? warnaStatus(StatusTugas.selesai, colors) : (mendesak ? colors.error : warnaStatus(tugas.status, colors));
    final tanggal = DateFormat('EEE, d MMM · HH:mm', 'id_ID').format(tugas.deadline);
    return Dismissible(
      key: ValueKey('geser-${tugas.id}'),
      direction: selesai ? DismissDirection.endToStart : DismissDirection.horizontal,
      confirmDismiss: (arah) async {
        onGeser(arah == DismissDirection.startToEnd
            ? StatusTugas.selesai
            : (selesai || tugas.status == StatusTugas.dikerjakan ? StatusTugas.belum : StatusTugas.dikerjakan));
        return false;
      },
      background: _latarGeser(
        warnaStatus(StatusTugas.selesai, colors),
        Icons.check_rounded,
        'Selesai',
        Alignment.centerLeft,
      ),
      secondaryBackground: _latarGeser(
        tugas.status == StatusTugas.belum ? colors.primary : const Color(0xFFF59E0B),
        tugas.status == StatusTugas.belum ? Icons.timelapse_rounded : Icons.undo_rounded,
        tugas.status == StatusTugas.belum ? 'Kerjakan' : 'Belum',
        Alignment.centerRight,
      ),
      child: Card(
        margin: const EdgeInsets.only(top: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(duration: const Duration(milliseconds: 300), width: 5, color: aksen),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Center(
                    child: IconButton(
                      tooltip: 'Ubah status',
                      onPressed: onStatus,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          ikonStatus(tugas.status),
                          key: ValueKey(tugas.status),
                          size: 28,
                          color: warnaStatus(tugas.status, colors),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: selesai ? TextDecoration.lineThrough : null,
                                  color: selesai ? colors.onSurfaceVariant : colors.onSurface,
                                ),
                                child: Text(tugas.judul, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: warnaWaktu.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                selesai ? 'Selesai' : sisaWaktu(tugas.deadline, sekarang),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: warnaWaktu,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (tugas.mapel.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: warnaMapel(tugas.mapel).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tugas.mapel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: warnaMapel(tugas.mapel),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_rounded, size: 14, color: colors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(tanggal, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                              ],
                            ),
                            if (tugas.lampiran.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.attach_file_rounded, size: 14, color: colors.onSurfaceVariant),
                                  Text('${tugas.lampiran.length}', style: theme.textTheme.bodySmall),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Kosong extends StatefulWidget {
  const _Kosong({required this.icon, required this.judul, required this.keterangan});
  final IconData icon;
  final String judul;
  final String keterangan;

  @override
  State<_Kosong> createState() => _KosongState();
}

class _KosongState extends State<_Kosong> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final gaya = GayaHanary.dari(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 120),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
              child: child,
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [for (final g in gaya.gradasi) g.withValues(alpha: 0.2)],
                ),
              ),
              child: Icon(widget.icon, size: 48, color: colors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.judul, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            widget.keterangan,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
