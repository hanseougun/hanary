import 'package:flutter/material.dart';

import '../theme/hanary_theme.dart';
import '../theme/pengaturan_tampilan.dart';
import '../widgets/hanary_widgets.dart';
import 'kebijakan_privasi_screen.dart';

/// Halaman Pengaturan: tampilan (mode gelap/terang, tema latar) dan tentang aplikasi.
class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pengaturan = PengaturanTampilan.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListenableBuilder(
        listenable: pengaturan,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _JudulBagian('Tampilan'),
            MunculBertahap(
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mode', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('Otomatis'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Terang'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Gelap'),
                            ),
                          ],
                          selected: {pengaturan.mode},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => pengaturan.setMode(s.first),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Otomatis mengikuti pengaturan HP-mu.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Tema latar', style: TextStyle(fontWeight: FontWeight.w700)),
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
            const _JudulBagian('Tentang'),
            MunculBertahap(
              urutan: 1,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Kebijakan privasi'),
                      subtitle: const Text('Data apa yang disimpan dan bagaimana dilindungi'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const KebijakanPrivasiScreen(),
                      )),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('Tentang Hanary'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Hanary',
                        applicationIcon: const LogoHanary(ukuran: 56, bayangan: false),
                        applicationLegalese: 'Catat tugas & deadline, kerjakan bareng teman.',
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
        teks.toUpperCase(),
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
            tema.nama,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: dipilih ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
