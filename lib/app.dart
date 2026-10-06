import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/bahasa.dart';

import 'screens/intro_screen.dart';
import 'theme/hanary_theme.dart';
import 'theme/pengaturan_tampilan.dart';

class HanaryApp extends StatelessWidget {
  const HanaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pengaturan = PengaturanTampilan.instance;
    final bahasa = PengaturanBahasa.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([pengaturan, bahasa]),
      builder: (context, _) => MaterialApp(
        title: 'Hanary',
        debugShowCheckedModeBanner: false,
        themeMode: pengaturan.mode,
        theme: buatTema(pengaturan.tema, Brightness.light),
        darkTheme: buatTema(pengaturan.tema, Brightness.dark),
        themeAnimationDuration: const Duration(milliseconds: 400),
        locale: bahasa.bahasa.locale,
        supportedLocales: [for (final b in Bahasa.values) b.locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const IntroScreen(),
      ),
    );
  }
}
