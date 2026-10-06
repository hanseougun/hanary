import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/hanary_theme.dart';
import '../widgets/hanary_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  late final _melayang = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _melayang.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final gaya = GayaHanary.dari(context);
    return Scaffold(
      body: LatarHanary(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: AnimatedBuilder(
                    animation: _melayang,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, -10 * Curves.easeInOut.transform(_melayang.value)),
                      child: child,
                    ),
                    child: const LogoHanary(ukuran: 112),
                  ),
                ),
                const SizedBox(height: 28),
                MunculBertahap(
                  urutan: 1,
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Selamat datang di\n'),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: TeksGradasi(
                          'Hanary',
                          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ]),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                MunculBertahap(
                  urutan: 2,
                  child: Text(
                    'Catat semua tugasmu, atur deadline, dan dapatkan pengingat '
                    'sebelum terlambat. Kerjakan bareng teman lewat chat dan grup.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 28),
                for (final (i, ikon, teks) in const [
                  (0, Icons.checklist_rounded, 'Catat tugas beserta file atau gambarnya'),
                  (1, Icons.notifications_active_rounded, 'Pengingat harian sampai deadline'),
                  (2, Icons.groups_rounded, 'Chat dengan teman dan buat grup'),
                ])
                  MunculBertahap(
                    urutan: 3 + i,
                    jeda: const Duration(milliseconds: 120),
                    geser: const Offset(-24, 0),
                    child: _Feature(icon: ikon, text: teks, warna: gaya.gradasi[i.isEven ? 0 : 1]),
                  ),
                const Spacer(flex: 2),
                MunculBertahap(
                  urutan: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gaya.gradasiUtama,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gaya.gradasi.first.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded),
                      label: const Text('Masuk dengan Google'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                      ),
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

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text, required this.warna});
  final IconData icon;
  final String text;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: warna, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
