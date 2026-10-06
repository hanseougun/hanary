import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/bahasa.dart';
import '../models/tugas.dart';
import '../services/drive_service.dart';
import '../services/lampiran_service.dart';
import '../services/tugas_repository.dart';
import 'chat/bagikan_tugas_screen.dart';

/// Form tambah/edit tugas: judul, mapel, deadline, status, catatan, dan lampiran.
class TugasFormScreen extends StatefulWidget {
  const TugasFormScreen({super.key, required this.uid, this.tugas});

  final String uid;

  /// Null untuk tugas baru.
  final Tugas? tugas;

  @override
  State<TugasFormScreen> createState() => _TugasFormScreenState();
}

class _TugasFormScreenState extends State<TugasFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _judul = TextEditingController(text: widget.tugas?.judul);
  late final _mapel = TextEditingController(text: widget.tugas?.mapel);
  late final _catatan = TextEditingController(text: widget.tugas?.catatan);
  late DateTime _deadline = widget.tugas?.deadline ?? _deadlineAwal();
  late StatusTugas _status = widget.tugas?.status ?? StatusTugas.belum;
  late final List<Lampiran> _lampiran = [...?widget.tugas?.lampiran];

  /// Lampiran yang baru ditambahkan di form ini (dihapus lagi jika batal).
  final _lampiranBaru = <Lampiran>[];

  /// Lampiran lama yang dibuang (file-nya dihapus setelah disimpan).
  final _lampiranDibuang = <Lampiran>[];
  bool _saving = false;
  bool _mengunggah = false;
  bool _tersimpan = false;

  bool get _isBaru => widget.tugas == null;

  static DateTime _deadlineAwal() {
    final besok = DateTime.now().add(const Duration(days: 3));
    return DateTime(besok.year, besok.month, besok.day, 23, 59);
  }

  @override
  void dispose() {
    for (final c in [_judul, _mapel, _catatan]) {
      c.dispose();
    }
    if (!_tersimpan) {
      for (final l in _lampiranBaru) {
        LampiranService.instance.hapus(l, dariDrive: false);
      }
    }
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final tanggal = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: tr('Tanggal deadline'),
    );
    if (tanggal == null) return;
    setState(() {
      _deadline = DateTime(tanggal.year, tanggal.month, tanggal.day, _deadline.hour, _deadline.minute);
    });
  }

  Future<void> _pilihJam() async {
    final jam = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
      helpText: tr('Jam deadline'),
    );
    if (jam == null) return;
    setState(() {
      _deadline = DateTime(_deadline.year, _deadline.month, _deadline.day, jam.hour, jam.minute);
    });
  }

  Future<void> _tambahLampiran(Future<List<Lampiran>> Function() ambil) async {
    try {
      final baru = await ambil();
      if (!mounted || baru.isEmpty) return;
      setState(() {
        _lampiran.addAll(baru);
        _lampiranBaru.addAll(baru);
      });
    } catch (e) {
      _pesan(tr('Gagal menambah lampiran: {galat}', {'galat': e}));
    }
  }

  void _buangLampiran(Lampiran l) {
    setState(() {
      _lampiran.remove(l);
      if (_lampiranBaru.remove(l)) {
        LampiranService.instance.hapus(l, dariDrive: false);
      } else {
        _lampiranDibuang.add(l);
      }
    });
  }

  Future<void> _bukaLampiran(Lampiran l) async {
    final error = await LampiranService.instance.buka(l);
    if (error != null) _pesan(error);
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      var lampiran = _lampiran;
      String? peringatan;
      if (_lampiran.any((l) => l.driveId == null)) {
        setState(() => _mengunggah = true);
        final (hasil, error) = await LampiranService.instance.unggahSemua(_lampiran);
        if (mounted) setState(() => _mengunggah = false);
        lampiran = hasil;
        if (error != null) {
          peringatan = error is DriveException
              ? tr('Lampiran hanya tersimpan di HP ini. {galat}', {'galat': error})
              : tr('Lampiran belum terunggah ke Google Drive, hanya tersimpan di HP ini.');
        }
      }
      final tugas = (widget.tugas ?? Tugas(id: '', judul: '', deadline: _deadline)).copyWith(
        judul: _judul.text,
        mapel: _mapel.text,
        catatan: _catatan.text,
        deadline: _deadline,
        status: _status,
        lampiran: lampiran,
      );
      await TugasRepository.instance.save(widget.uid, tugas);
      _tersimpan = true;
      for (final l in _lampiranDibuang) {
        await LampiranService.instance.hapus(l);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      _pesan(peringatan ?? (_isBaru ? tr('Tugas ditambahkan') : tr('Tugas disimpan')));
    } catch (e) {
      _pesan(tr('Gagal menyimpan: {galat}', {'galat': e}));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hapus() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Hapus tugas?')),
        content: Text(tr('"{judul}" dan lampirannya akan dihapus.', {'judul': widget.tugas!.judul})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Batal'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Hapus'))),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await TugasRepository.instance.delete(widget.uid, widget.tugas!.id);
      for (final l in widget.tugas!.lampiran) {
        await LampiranService.instance.hapus(l);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      _pesan(tr('Tugas dihapus'));
    } catch (e) {
      _pesan(tr('Gagal menghapus: {galat}', {'galat': e}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tanggal = DateFormat('EEEE, d MMMM y', kodeTanggal).format(_deadline);
    final jam = DateFormat('HH:mm').format(_deadline);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isBaru ? tr('Tugas baru') : tr('Edit tugas')),
        actions: [
          if (!_isBaru)
            IconButton(
              tooltip: tr('Bagikan ke teman atau grup'),
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => BagikanTugasScreen(me: widget.uid, tugas: widget.tugas!),
              )),
            ),
          if (!_isBaru)
            IconButton(
              tooltip: tr('Hapus tugas'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _hapus,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _judul,
                decoration: InputDecoration(labelText: tr('Judul tugas *')),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? tr('Wajib diisi') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mapel,
                decoration: InputDecoration(labelText: tr('Mata pelajaran / kuliah')),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              Text(tr('Deadline'), style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: _pilihTanggal,
                      icon: const Icon(Icons.event),
                      label: Text(tanggal, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(onPressed: _pilihJam, child: Text(jam)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr('Kamu diingatkan tiap hari jam 12.00 & 18.00, lalu 1 jam, 30, 15, dan 5 menit sebelum deadline.'),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text(tr('Status'), style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<StatusTugas>(
                segments: [
                  ButtonSegment(value: StatusTugas.belum, label: Text(tr('Belum'))),
                  ButtonSegment(value: StatusTugas.dikerjakan, label: Text(tr('Dikerjakan'))),
                  ButtonSegment(value: StatusTugas.selesai, label: Text(tr('Selesai'))),
                ],
                selected: {_status},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _catatan,
                decoration: InputDecoration(
                  labelText: tr('Catatan'),
                  hintText: tr('Detail tugas, halaman buku, dll.'),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              Text(tr('Lampiran'), style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final l in _lampiran)
                _LampiranTile(
                  lampiran: l,
                  onTap: () => _bukaLampiran(l),
                  onHapus: () => _buangLampiran(l),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _tambahLampiran(() async {
                        final foto = await LampiranService.instance.ambilFoto();
                        return [if (foto != null) foto];
                      }),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(tr('Foto')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _tambahLampiran(LampiranService.instance.pilihFile),
                      icon: const Icon(Icons.attach_file),
                      label: Text(tr('Gambar / file')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _simpan,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _saving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          if (_mengunggah) ...[
                            const SizedBox(width: 12),
                            Text(tr('Mengunggah ke Google Drive...')),
                          ],
                        ],
                      )
                    : Text(tr('Simpan')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LampiranTile extends StatelessWidget {
  const _LampiranTile({required this.lampiran, required this.onTap, required this.onHapus});

  final Lampiran lampiran;
  final VoidCallback onTap;
  final VoidCallback onHapus;

  String _ukuran(int byte) {
    if (byte >= 1024 * 1024) return '${(byte / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(byte / 1024).ceil()} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: FutureBuilder<File>(
            future: LampiranService.instance.fileDari(lampiran),
            builder: (context, snap) {
              final file = snap.data;
              if (lampiran.isGambar && file != null && file.existsSync()) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(file, fit: BoxFit.cover, cacheWidth: 144),
                );
              }
              return Icon(lampiran.isGambar ? Icons.image_outlined : Icons.description_outlined);
            },
          ),
        ),
        title: Text(lampiran.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_ukuran(lampiran.ukuran)} · ${lampiran.driveId != null ? tr('di Google Drive') : tr('belum diunggah')}',
        ),
        trailing: IconButton(
          tooltip: tr('Buang lampiran'),
          icon: const Icon(Icons.close),
          onPressed: onHapus,
        ),
      ),
    );
  }
}
