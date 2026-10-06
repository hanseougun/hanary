import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/tugas.dart';
import '../services/notifikasi_service.dart';
import '../services/tugas_repository.dart';
import 'tugas_form_screen.dart';

/// Pilihan saring daftar tugas di Beranda.
enum _Saring { aktif, belum, dikerjakan, selesai, semua }

/// Halaman utama: ringkasan status dan daftar tugas urut deadline terdekat.
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

  String _salam() {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Selamat pagi';
    if (jam < 15) return 'Selamat siang';
    if (jam < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  void _bukaForm([Tugas? tugas]) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TugasFormScreen(uid: widget.user.uid, tugas: tugas),
    ));
  }

  Future<void> _ubahStatus(Tugas t, StatusTugas status) async {
    try {
      await TugasRepository.instance.setStatus(widget.user.uid, t.id, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah status: $e')));
    }
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
      appBar: AppBar(title: const Text('Beranda')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaForm,
        icon: const Icon(Icons.add),
        label: const Text('Tugas'),
      ),
      body: StreamBuilder<List<Tugas>>(
        stream: _tugas,
        builder: (context, snap) {
          final semua = snap.data ?? const <Tugas>[];
          int hitung(StatusTugas s) => semua.where((t) => t.status == s).length;
          final tampil = semua.where(_lolos).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('${_salam()},', style: theme.textTheme.titleMedium),
              Text(
                widget.user.sebutan,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Belum',
                      value: hitung(StatusTugas.belum),
                      icon: Icons.radio_button_unchecked,
                      onTap: () => setState(() => _saring = _Saring.belum),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Dikerjakan',
                      value: hitung(StatusTugas.dikerjakan),
                      icon: Icons.timelapse,
                      onTap: () => setState(() => _saring = _Saring.dikerjakan),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Selesai',
                      value: hitung(StatusTugas.selesai),
                      icon: Icons.check_circle_outline,
                      onTap: () => setState(() => _saring = _Saring.selesai),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
              const SizedBox(height: 8),
              if (snap.hasError)
                _Kosong(
                  icon: Icons.cloud_off,
                  judul: 'Gagal memuat tugas',
                  keterangan: '${snap.error}',
                )
              else if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (tampil.isEmpty)
                _Kosong(
                  icon: Icons.inbox_outlined,
                  judul: semua.isEmpty ? 'Belum ada tugas' : 'Tidak ada tugas di sini',
                  keterangan: semua.isEmpty
                      ? 'Tekan tombol "+ Tugas" untuk mencatat tugas pertamamu.'
                      : 'Coba pilih saringan lain.',
                )
              else
                for (final t in tampil)
                  _TugasTile(
                    tugas: t,
                    onTap: () => _bukaForm(t),
                    onStatus: (s) => _ubahStatus(t, s),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _TugasTile extends StatelessWidget {
  const _TugasTile({required this.tugas, required this.onTap, required this.onStatus});

  final Tugas tugas;
  final VoidCallback onTap;
  final ValueChanged<StatusTugas> onStatus;

  static IconData ikon(StatusTugas s) => switch (s) {
        StatusTugas.belum => Icons.radio_button_unchecked,
        StatusTugas.dikerjakan => Icons.timelapse,
        StatusTugas.selesai => Icons.check_circle,
      };

  /// "Terlambat", "Hari ini 23:59", "Besok 07:00", "3 hari lagi", ...
  static String sisaWaktu(DateTime deadline, DateTime sekarang) {
    final jam = DateFormat('HH:mm').format(deadline);
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final hariDeadline = DateTime(deadline.year, deadline.month, deadline.day);
    final selisih = hariDeadline.difference(hariIni).inDays;
    if (deadline.isBefore(sekarang)) return 'Terlambat';
    if (selisih == 0) return 'Hari ini $jam';
    if (selisih == 1) return 'Besok $jam';
    return '$selisih hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sekarang = DateTime.now();
    final selesai = tugas.status == StatusTugas.selesai;
    final mendesak = !selesai && tugas.deadline.difference(sekarang) < const Duration(days: 1);
    final warnaWaktu = selesai
        ? colors.onSurfaceVariant
        : mendesak
            ? colors.error
            : colors.primary;
    final tanggal = DateFormat('EEE, d MMM y · HH:mm', 'id_ID').format(tugas.deadline);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.only(left: 4, right: 16),
        leading: PopupMenuButton<StatusTugas>(
          tooltip: 'Ubah status',
          icon: Icon(ikon(tugas.status), color: selesai ? colors.primary : null),
          initialValue: tugas.status,
          onSelected: onStatus,
          itemBuilder: (_) => [
            for (final s in StatusTugas.values)
              PopupMenuItem(
                value: s,
                child: Row(
                  children: [Icon(ikon(s), size: 20), const SizedBox(width: 12), Text(s.label)],
                ),
              ),
          ],
        ),
        title: Text(
          tugas.judul,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: selesai
              ? TextStyle(decoration: TextDecoration.lineThrough, color: colors.onSurfaceVariant)
              : null,
        ),
        subtitle: Text(
          [
            if (tugas.mapel.isNotEmpty) tugas.mapel,
            tanggal,
            if (tugas.status == StatusTugas.dikerjakan) 'Sedang dikerjakan',
          ].join('\n'),
        ),
        isThreeLine: tugas.mapel.isNotEmpty || tugas.status == StatusTugas.dikerjakan,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              selesai ? 'Selesai' : sisaWaktu(tugas.deadline, sekarang),
              style: theme.textTheme.labelMedium?.copyWith(color: warnaWaktu, fontWeight: FontWeight.w600),
            ),
            if (tugas.lampiran.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file, size: 14, color: colors.onSurfaceVariant),
                    Text('${tugas.lampiran.length}', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.icon, required this.judul, required this.keterangan});
  final IconData icon;
  final String judul;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: colors.outline),
          const SizedBox(height: 12),
          Text(judul, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            keterangan,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, this.onTap});
  final String label;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text('$value', style: theme.textTheme.headlineSmall),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
