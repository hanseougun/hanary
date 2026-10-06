import 'package:flutter/material.dart';

import 'screens/intro_screen.dart';
import 'theme/hanary_theme.dart';
import 'theme/pengaturan_tampilan.dart';

class HanaryApp extends StatelessWidget {
  const HanaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pengaturan = PengaturanTampilan.instance;
    return ListenableBuilder(
      listenable: pengaturan,
      builder: (context, _) => MaterialApp(
        title: 'Hanary',
        debugShowCheckedModeBanner: false,
        themeMode: pengaturan.mode,
        theme: buatTema(pengaturan.tema, Brightness.light),
        darkTheme: buatTema(pengaturan.tema, Brightness.dark),
        themeAnimationDuration: const Duration(milliseconds: 400),
        home: const IntroScreen(),
      ),
    );
  }
}
