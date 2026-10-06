import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../l10n/bahasa.dart';
import '../../services/notifikasi_service.dart';
import '../../services/pengaturan_notif.dart';
import '../chat/chat_widgets.dart';

/// Mengatur nada, getar, dan durasi untuk satu jenis notifikasi.
class SuaraNotifScreen extends StatefulWidget {
  const SuaraNotifScreen({super.key, required this.jenis});
  final JenisNotif jenis;

  @override
  State<SuaraNotifScreen> createState() => _SuaraNotifScreenState();
}

class _SuaraNotifScreenState extends State<SuaraNotifScreen> {
  SetelanNotif? _s;
  bool _bisaFile = false;

  static const _pilihanTampil = <int, String>{
    0: 'Sampai dihapus',
    1: '{n} menit',
    5: '{n} menit',
    30: '{n} menit',
    60: '1 jam',
  };

  @override
  void initState() {
    super.initState();
    PengaturanNotif.baca(widget.jenis).then((s) {
      if (mounted) setState(() => _s = s);
    });
    NadaHp.bisaSimpanFile().then((v) {
      if (mounted) setState(() => _bisaFile = v);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    NadaHp.berhenti().catchError((Object _) {});
    super.dispose();
  }

  Future<void> _simpan(SetelanNotif baru) async {
    setState(() => _s = baru);
    try {
      await PengaturanNotif.simpan(widget.jenis, baru);
      await NotifikasiService.instance.terapkanSetelan(widget.jenis);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _pilihNada() async {
    final s = _s!;
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(tr('Bawaan HP')),
              trailing: s.suara == SetelanNotif.suaraBawaan ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, 'bawaan'),
            ),
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: Text(tr('Pilih dari nada HP')),
              subtitle: Text(tr('Daftar nada notifikasi yang ada di HP')),
              trailing: s.nadaSendiri ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, 'hp'),
            ),
            if (_bisaFile)
              ListTile(
                leading: const Icon(Icons.audio_file_outlined),
                title: Text(tr('Pilih file suara sendiri')),
                subtitle: Text(tr('Lagu atau rekaman (mp3, m4a, ogg, wav)')),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: Text(tr('Tanpa suara')),
              trailing: s.suara == SetelanNotif.suaraSenyap ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, 'senyap'),
            ),
          ],
        ),
      ),
    );
    if (pilihan == null || !mounted) return;
    try {
      switch (pilihan) {
        case 'bawaan':
          await _simpan(s.copyWith(suara: SetelanNotif.suaraBawaan, namaSuara: ''));
        case 'senyap':
          await _simpan(s.copyWith(suara: SetelanNotif.suaraSenyap, namaSuara: ''));
        case 'hp':
          final hasil = await NadaHp.pilih(sekarang: s.nadaSendiri ? s.suara : null);
          if (hasil == null) return;
          await _simpan(s.copyWith(suara: hasil.$1, namaSuara: hasil.$2));
          await NadaHp.putar(hasil.$1);
        case 'file':
          final hasil = await FilePicker.pickFiles(type: FileType.audio);
          final f = hasil.firstOrNull;
          if (f == null) return;
          if ((await f.length() ?? 0) > 5 * 1024 * 1024) {
            throw StateError(tr('File suara terlalu besar (maks. 5 MB). Pilih suara yang pendek.'));
          }
          // Salin dulu ke folder sementara aplikasi, lalu ke folder Notifications HP.
          final sementara =
              File('${(await getTemporaryDirectory()).path}/nada_${DateTime.now().millisecondsSinceEpoch}');
          await sementara.writeAsBytes(await f.xFile.readAsBytes());
          final uri = await NadaHp.simpanFile(sementara.path, f.name);
          await sementara.delete().catchError((Object _) => sementara);
          if (uri == null) return;
          final nama = f.name.contains('.') ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name;
          await _simpan(s.copyWith(suara: uri, namaSuara: nama));
          await NadaHp.putar(uri);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final theme = Theme.of(context);
    final judul = tr(widget.jenis == JenisNotif.chat ? 'Notifikasi pesan' : 'Notifikasi pengingat tugas');
    return Scaffold(
      appBar: AppBar(title: Text(judul)),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child:
                      Text(tr('Suara'), style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                ),
                ListTile(
                  leading: const Icon(Icons.music_note_outlined),
                  title: Text(tr('Nada notifikasi')),
                  subtitle: Text(s.labelSuara),
                  trailing: s.suara == SetelanNotif.suaraSenyap
                      ? null
                      : IconButton(
                          tooltip: tr('Dengarkan'),
                          icon: const Icon(Icons.play_circle_outline),
                          onPressed: () => NadaHp.putar(s.nadaSendiri ? s.suara : null),
                        ),
                  onTap: _pilihNada,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: Text(tr('Getar')),
                  value: s.getar,
                  onChanged: (v) => _simpan(s.copyWith(getar: v)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child:
                      Text(tr('Durasi'), style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                ),
                RadioGroup<bool>(
                  groupValue: s.berulang,
                  onChanged: (v) => _simpan(s.copyWith(berulang: v)),
                  child: Column(
                    children: [
                      RadioListTile(
                        value: false,
                        title: Text(tr('Bunyi sekali')),
                        subtitle: Text(tr('Seperti notifikasi biasa')),
                      ),
                      RadioListTile(
                        value: true,
                        title: Text(tr('Bunyi terus sampai dilihat')),
                        subtitle: Text(tr('Nada diulang sampai kamu membuka atau menggeser notifikasinya')),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(tr('Notifikasi tampil selama')),
                  subtitle: Text(tr(_pilihanTampil[s.tampilMenit] ?? '{n} menit', {'n': s.tampilMenit})),
                  trailing: DropdownButton<int>(
                    value: _pilihanTampil.containsKey(s.tampilMenit) ? s.tampilMenit : 0,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final e in _pilihanTampil.entries)
                        DropdownMenuItem(value: e.key, child: Text(tr(e.value, {'n': e.key}))),
                    ],
                    onChanged: (v) => _simpan(s.copyWith(tampilMenit: v)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Text(
                    tr('Jika suara belum berubah, pastikan mode senyap/Jangan Ganggu di HP mati. Pengaturan ini juga bisa diubah lewat Pengaturan HP → Aplikasi → Hanary → Notifikasi.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
    );
  }
}
