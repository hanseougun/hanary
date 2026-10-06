import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/hanary_theme.dart';

/// Logo Hanary (kotak membulat bergradasi) dengan bayangan lembut.
class LogoHanary extends StatelessWidget {
  const LogoHanary({super.key, this.ukuran = 96, this.bayangan = true});
  final double ukuran;
  final bool bayangan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ukuran * 0.22),
        boxShadow: bayangan
            ? [
                BoxShadow(
                  color: WarnaHanary.ungu.withValues(alpha: 0.35),
                  blurRadius: ukuran * 0.3,
                  offset: Offset(0, ukuran * 0.1),
                ),
              ]
            : null,
      ),
      child: Image.asset('assets/images/logo.png', width: ukuran, height: ukuran),
    );
  }
}

/// Memunculkan [child] dengan efek geser dan pudar, berurutan sesuai [urutan].
/// Dipakai agar daftar dan kartu muncul satu per satu dengan halus.
class MunculBertahap extends StatefulWidget {
  const MunculBertahap({
    super.key,
    required this.child,
    this.urutan = 0,
    this.jeda = const Duration(milliseconds: 60),
    this.geser = const Offset(0, 24),
  });

  final Widget child;
  final int urutan;
  final Duration jeda;
  final Offset geser;

  @override
  State<MunculBertahap> createState() => _MunculBertahapState();
}

class _MunculBertahapState extends State<MunculBertahap> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _kurva = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Batasi jeda agar daftar panjang tidak menunggu terlalu lama.
    final urutan = widget.urutan.clamp(0, 8);
    _timer = Timer(widget.jeda * urutan, () => _c.forward());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _kurva,
      builder: (context, child) {
        final t = _kurva.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: widget.geser * (1 - t), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Mengecil sedikit saat ditekan, memberi rasa "membal" yang interaktif.
class Ketuk extends StatefulWidget {
  const Ketuk({super.key, required this.child, this.onTap, this.onLongPress, this.radius = 20});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;

  @override
  State<Ketuk> createState() => _KetukState();
}

class _KetukState extends State<Ketuk> {
  bool _ditekan = false;

  void _set(bool v) {
    if (_ditekan != v) setState(() => _ditekan = v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _ditekan ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Latar halaman utama: warna dasar tema dengan dua cahaya gradasi lembut
/// di pojok, mengikuti tema latar yang dipilih di Pengaturan.
class LatarHanary extends StatelessWidget {
  const LatarHanary({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gelap = theme.brightness == Brightness.dark;
    final tema = GayaHanary.dari(context);
    final kuat = gelap ? 0.22 : 0.16;
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: _Cahaya(warna: tema.gradasi.last.withValues(alpha: kuat), ukuran: 360),
          ),
          Positioned(
            top: 120,
            left: -160,
            child: _Cahaya(warna: tema.gradasi.first.withValues(alpha: kuat), ukuran: 340),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Cahaya extends StatelessWidget {
  const _Cahaya({required this.warna, required this.ukuran});
  final Color warna;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [warna, warna.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Teks berwarna gradasi tema, untuk judul yang ingin menonjol.
class TeksGradasi extends StatelessWidget {
  const TeksGradasi(this.teks, {super.key, this.style, this.gradasi, this.textAlign});
  final String teks;
  final TextStyle? style;
  final Gradient? gradasi;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final g = gradasi ?? GayaHanary.dari(context).gradasiUtama;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => g.createShader(rect),
      child: Text(teks, style: style, textAlign: textAlign),
    );
  }
}
