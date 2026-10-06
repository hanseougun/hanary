import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/kalimat_penyemangat.dart';
import '../services/user_repository.dart';
import '../theme/hanary_theme.dart';
import '../widgets/hanary_widgets.dart';
import 'auth_gate.dart';

/// Layar pembuka setiap kali aplikasi dibuka:
/// 1. logo dan nama Hanary muncul dengan animasi,
/// 2. berganti ke sapaan (nama pengguna jika sudah login) dan kalimat penyemangat acak,
/// 3. lalu masuk ke aplikasi.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  static const _nama = 'Hanary';

  /// Tahap 1: logo memantul masuk, cincin cahaya, huruf nama satu per satu.
  late final _logo = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  /// Tahap 2: logo naik ke atas, sapaan dan kalimat penyemangat muncul.
  late final _sapa = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  /// Cahaya yang terus berdenyut di belakang logo.
  late final _denyut = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  final _kalimat = kalimatAcak();
  late final Future<String?> _namaPengguna = _ambilNama();
  String? _sebutan;
  bool _keluar = false;
  Timer? _timerLanjut;

  @override
  void initState() {
    super.initState();
    _jalankan();
  }

  Future<String?> _ambilNama() async {
    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 2), onTimeout: () => FirebaseAuth.instance.currentUser);
      if (user == null) return null;
      final profil = await UserRepository.instance
          .watch(user.uid)
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      final sebutan = profil?.sebutan.trim() ?? '';
      if (sebutan.isNotEmpty) return sebutan;
      final nama = user.displayName?.trim() ?? '';
      return nama.isEmpty ? '' : nama.split(' ').first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _jalankan() async {
    await _logo.forward();
    // Tunggu nama pengguna (biasanya sudah siap selama animasi logo).
    _sebutan = await _namaPengguna;
    if (!mounted) return;
    setState(() {});
    await _sapa.forward();
    if (!mounted) return;
    _timerLanjut = Timer(const Duration(milliseconds: 1600), _masuk);
  }

  void _masuk() {
    if (_keluar || !mounted) return;
    _keluar = true;
    _timerLanjut?.cancel();
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, anim, anim2) => const AuthGate(),
      transitionsBuilder: (context, anim, anim2, child) {
        final kurva = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: kurva,
          child: ScaleTransition(scale: Tween(begin: 1.08, end: 1.0).animate(kurva), child: child),
        );
      },
    ));
  }

  /// Ketuk layar untuk melewati animasi (hanya setelah logo selesai muncul).
  void _lewati() {
    if (_logo.isCompleted && _sapa.value > 0.4) _masuk();
  }

  @override
  void dispose() {
    _timerLanjut?.cancel();
    _logo.dispose();
    _sapa.dispose();
    _denyut.dispose();
    super.dispose();
  }

  Animation<double> _interval(AnimationController c, double a, double b, [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(parent: c, curve: Interval(a, b, curve: curve));

  @override
  Widget build(BuildContext context) {
    final ukuranLayar = MediaQuery.sizeOf(context);
    final logoMasuk = _interval(_logo, 0, 0.45, Curves.elasticOut);
    final logoPudar = _interval(_logo, 0, 0.2);
    final cincin = _interval(_logo, 0.15, 0.6, Curves.easeOutCubic);
    final tagline = _interval(_logo, 0.75, 1);
    final kilau = _interval(_logo, 0.7, 1, Curves.easeInOut);
    final naik = _interval(_sapa, 0, 0.35, Curves.easeInOutCubic);
    final salam = _interval(_sapa, 0.2, 0.45, Curves.easeOutCubic);
    final namaMuncul = _interval(_sapa, 0.3, 0.55, Curves.easeOutBack);
    final ketik = _interval(_sapa, 0.45, 0.95, Curves.linear);

    return Scaffold(
      backgroundColor: WarnaHanary.latarPembuka,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _lewati,
        child: AnimatedBuilder(
          animation: Listenable.merge([_logo, _sapa, _denyut]),
          builder: (context, _) {
            final n = naik.value;
            return Stack(
              children: [
                // Latar gradasi yang perlahan berputar.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                          0.6 * cos(_denyut.value * 2 * pi),
                          -0.4 + 0.3 * sin(_denyut.value * 2 * pi),
                        ),
                        radius: 1.3,
                        colors: [
                          WarnaHanary.ungu.withValues(alpha: 0.55 * logoPudar.value),
                          WarnaHanary.latarPembuka,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  right: -100,
                  child: Opacity(
                    opacity: logoPudar.value,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          WarnaHanary.oranye.withValues(alpha: 0.35),
                          WarnaHanary.oranye.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                ),
                // Logo: di tengah saat tahap 1, lalu naik dan mengecil di tahap 2.
                Align(
                  alignment: Alignment(0, -0.12 - 0.5 * n),
                  child: Transform.scale(
                    scale: (0.2 + 0.8 * logoMasuk.value) * (1 - 0.35 * n),
                    child: Transform.rotate(
                      angle: (1 - logoMasuk.value) * -0.6,
                      child: Opacity(
                        opacity: logoPudar.value,
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Cincin cahaya yang memancar keluar.
                              for (final fase in [0.0, 0.5])
                                _Cincin(
                                  t: (_denyut.value + fase) % 1,
                                  kuat: cincin.value,
                                ),
                              const LogoHanary(ukuran: 120),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Nama aplikasi, huruf demi huruf, dengan kilau melintas.
                Align(
                  alignment: const Alignment(0, 0.32),
                  child: Opacity(
                    opacity: 1 - n,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (rect) => LinearGradient(
                            begin: Alignment(-1.5 + 3.5 * kilau.value - 0.4, 0),
                            end: Alignment(-1.5 + 3.5 * kilau.value + 0.4, 0),
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              WarnaHanary.oranye.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ).createShader(rect),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < _nama.length; i++) _huruf(i),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: tagline.value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - tagline.value)),
                            child: Text(
                              'CATAT TUGAS & DEADLINE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 4,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tahap 2: sapaan dan kalimat penyemangat.
                if (_sapa.value > 0)
                  Align(
                    alignment: const Alignment(0, 0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: salam.value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - salam.value)),
                              child: Text(
                                _sebutan == null
                                    ? 'Hai, selamat datang!'
                                    : '${salamWaktu(DateTime.now())},',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (_sebutan != null && _sebutan!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Transform.scale(
                              scale: namaMuncul.value.clamp(0.0, 1.2),
                              child: Opacity(
                                opacity: namaMuncul.value.clamp(0.0, 1.0),
                                child: TeksGradasi(
                                  '$_sebutan! 👋',
                                  textAlign: TextAlign.center,
                                  gradasi: const LinearGradient(
                                    colors: [Color(0xFFD8B4FE), WarnaHanary.oranye],
                                  ),
                                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          Opacity(
                            opacity: ketik.value > 0 ? 1 : 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFC56B), size: 24),
                                  const SizedBox(height: 8),
                                  // Efek mengetik: huruf muncul sedikit demi sedikit,
                                  // tetapi tempatnya sudah disiapkan agar teks tidak melompat.
                                  Text.rich(
                                    TextSpan(children: [
                                      TextSpan(
                                        text: _kalimat.substring(0, (_kalimat.length * ketik.value).round()),
                                      ),
                                      TextSpan(
                                        text: _kalimat.substring((_kalimat.length * ketik.value).round()),
                                        style: const TextStyle(color: Colors.transparent),
                                      ),
                                    ]),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Petunjuk lewati.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32 + MediaQuery.paddingOf(context).bottom,
                  child: Opacity(
                    opacity: _sapa.value > 0.6 ? 0.6 : 0,
                    child: const Text(
                      'Ketuk untuk lanjut',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1),
                    ),
                  ),
                ),
                // Partikel kecil yang melayang pelan.
                for (var i = 0; i < 12; i++) _partikel(i, ukuranLayar, logoPudar.value),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _huruf(int i) {
    final mulai = 0.3 + i * 0.06;
    final t = _interval(_logo, mulai, (mulai + 0.25).clamp(0, 1), Curves.easeOutBack).value;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 28 * (1 - t)),
        child: Text(
          _nama[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _partikel(int i, Size layar, double muncul) {
    final acak = Random(i * 7919);
    final x = acak.nextDouble() * layar.width;
    final y0 = acak.nextDouble() * layar.height;
    final kecepatan = 0.3 + acak.nextDouble() * 0.7;
    final ukuran = 2.0 + acak.nextDouble() * 4;
    final y = (y0 - _denyut.value * 120 * kecepatan) % layar.height;
    return Positioned(
      left: x,
      top: y,
      child: IgnorePointer(
        child: Opacity(
          opacity: muncul * (0.25 + 0.5 * acak.nextDouble()),
          child: Container(
            width: ukuran,
            height: ukuran,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i.isEven ? Colors.white : WarnaHanary.oranye,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cincin cahaya yang membesar lalu memudar dari belakang logo.
class _Cincin extends StatelessWidget {
  const _Cincin({required this.t, required this.kuat});
  final double t;
  final double kuat;

  @override
  Widget build(BuildContext context) {
    final ukuran = 120 + 100 * t;
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ukuran * 0.3),
        border: Border.all(
          color: Color.lerp(WarnaHanary.ungu, WarnaHanary.oranye, t)!.withValues(alpha: (1 - t) * 0.6 * kuat),
          width: 2,
        ),
      ),
    );
  }
}
