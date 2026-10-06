import 'package:flutter/material.dart';

import '../l10n/bahasa.dart';

/// Warna merek Hanary, diambil dari logo.
abstract final class WarnaHanary {
  static const ungu = Color(0xFF8E2ECE);
  static const oranye = Color(0xFFFB7260);
  static const biruTua = Color(0xFF0A3D74);

  /// Latar gelap layar pembuka (sama dengan layar pembuka bawaan Android).
  static const latarPembuka = Color(0xFF140B2E);
}

/// Pilihan tema latar yang bisa dipilih pengguna di Pengaturan.
enum TemaLatar {
  hanary('Hanary', WarnaHanary.ungu, [WarnaHanary.ungu, WarnaHanary.oranye]),
  samudra('Samudra', Color(0xFF0284C7), [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
  hutan('Hutan', Color(0xFF059669), [Color(0xFF10B981), Color(0xFF0EA5E9)]),
  sakura('Sakura', Color(0xFFDB2777), [Color(0xFFEC4899), Color(0xFFF59E0B)]),
  senja('Senja', Color(0xFFEA580C), [Color(0xFFF97316), Color(0xFFE11D48)]),
  malam('Malam', Color(0xFF4F46E5), [Color(0xFF1E3A8A), Color(0xFF7C3AED)]);

  const TemaLatar(this.nama, this.benih, this.gradasi);

  final String nama;

  /// [nama] dalam bahasa yang dipilih, untuk ditampilkan.
  String get namaTr => tr(nama);

  /// Warna dasar untuk seluruh skema warna aplikasi.
  final Color benih;

  /// Dua warna gradasi untuk kartu sorotan dan latar halaman.
  final List<Color> gradasi;

  static TemaLatar dari(String? nama) =>
      TemaLatar.values.firstWhere((t) => t.name == nama, orElse: () => TemaLatar.hanary);
}

/// Warna gradasi tema latar yang sedang dipakai, dibaca lewat
/// `GayaHanary.dari(context)` agar ikut berubah saat tema diganti.
class GayaHanary extends ThemeExtension<GayaHanary> {
  const GayaHanary({required this.gradasi});
  final List<Color> gradasi;

  LinearGradient get gradasiUtama => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradasi,
      );

  static GayaHanary dari(BuildContext context) =>
      Theme.of(context).extension<GayaHanary>() ?? GayaHanary(gradasi: TemaLatar.hanary.gradasi);

  @override
  GayaHanary copyWith({List<Color>? gradasi}) => GayaHanary(gradasi: gradasi ?? this.gradasi);

  @override
  GayaHanary lerp(GayaHanary? other, double t) {
    if (other == null) return this;
    return GayaHanary(gradasi: [
      for (var i = 0; i < gradasi.length; i++) Color.lerp(gradasi[i], other.gradasi[i], t)!,
    ]);
  }
}

/// Membuat [ThemeData] Hanary untuk tema latar dan mode terang/gelap tertentu.
ThemeData buatTema(TemaLatar tema, Brightness brightness) {
  final gelap = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: tema.benih,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final latar = Color.alphaBlend(
    tema.gradasi.first.withValues(alpha: gelap ? 0.06 : 0.035),
    scheme.surface,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    brightness: brightness,
  );
  final teks = base.textTheme.copyWith(
    headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
  final bentuk = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    textTheme: teks,
    extensions: [GayaHanary(gradasi: tema.gradasi)],
    scaffoldBackgroundColor: latar,
    appBarTheme: AppBarTheme(
      backgroundColor: latar,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: teks.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: gelap ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: gelap ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: bentuk,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'PlusJakartaSans'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: bentuk)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: gelap ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: bentuk),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
