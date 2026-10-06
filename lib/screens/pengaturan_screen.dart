import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/bahasa.dart';
import '../theme/hanary_theme.dart';
import '../theme/pengaturan_tampilan.dart';
import '../widgets/hanary_widgets.dart';
import 'kebijakan_privasi_screen.dart';
import 'pengaturan/pengaturan_chat_screen.dart';

/// Halaman Pengaturan: tampilan (mode gelap/terang, tema latar), chat & privasi,
/// dan tentang aplikasi.
class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  Future<void> _pilihBahasa(BuildContext context) async {
    final sekarang = PengaturanBahasa.instance.bahasa;
    final dipilih = await showModalBottomSheet<Bahasa>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: RadioGroup<Bahasa>(
          groupValue: sekarang,
          onChanged: (b) => Navigator.pop(ctx, b),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final b in Bahasa.values) RadioListTile<Bahasa>(value: b, title: Text(b.nama)),
            ],
          ),
        ),
      ),
    );
    if (dipilih != null) await PengaturanBahasa.instance.setBahasa(dipilih);
  }

  @override
  Widget build(BuildContext context) {
    final pengaturan = PengaturanTampilan.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Pengaturan'))),
      body: ListenableBuilder(
        listenable: Listenable.merge([pengaturan, PengaturanBahasa.instance]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _JudulBagian('Bahasa'),
            MunculBertahap(
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(tr('Bahasa aplikasi')),
                  subtitle: Text(PengaturanBahasa.instance.bahasa.nama),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pilihBahasa(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _JudulBagian('Tampilan'),
            MunculBertahap(
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Mode'), style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(tr('Otomatis')),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(tr('Terang')),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(tr('Gelap')),
                            ),
                          ],
                          selected: {pengaturan.mode},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => pengaturan.setMode(s.first),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('Otomatis mengikuti pengaturan HP-mu.'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Text(tr('Tema latar'), style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9,
                        children: [
                          for (final tema in TemaLatar.values)
                            _PilihanTema(
                              tema: tema,
                              dipilih: pengaturan.tema == tema,
                              onTap: () => pengaturan.setTema(tema),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (uid != null) ...[
              const _JudulBagian('Chat & privasi'),
              MunculBertahap(
                urutan: 1,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: PengaturanChatBagian(uid: uid, shrinkWrap: true),
                ),
              ),
            ],
            const _JudulBagian('Tentang'),
            MunculBertahap(
              urutan: 2,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(tr('Kebijakan privasi')),
                      subtitle: Text(tr('Data apa yang disimpan dan bagaimana dilindungi')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const KebijakanPrivasiScreen(),
                      )),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(tr('Tentang Hanary')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          icon: const LogoHanary(ukuran: 56, bayangan: false),
                          title: const Text('Hanary'),
                          content: Text(
                            '${tr('Catat tugas & deadline, kerjakan bareng teman.')}\n\n© 2026 hanseougun',
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Tutup'))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian(this.teks);
  final String teks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        tr(teks).toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PilihanTema extends StatelessWidget {
  const _PilihanTema({required this.tema, required this.dipilih, required this.onTap});
  final TemaLatar tema;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Ketuk(
      onTap: onTap,
      radius: 18,
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.all(dipilih ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dipilih ? tema.benih : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tema.gradasi,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedScale(
                  scale: dipilih ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tema.namaTr,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: dipilih ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
