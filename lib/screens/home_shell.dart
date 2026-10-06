import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../widgets/hanary_widgets.dart';
import 'beranda_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

/// Kerangka utama dengan navigasi bawah: Beranda, Chat, Profil.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final AppUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      BerandaScreen(user: widget.user),
      ChatScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
    return Scaffold(
      body: LatarHanary(
        // Halaman di dalam tab dibuat transparan agar latar tema terlihat.
        child: Theme(
          data: theme.copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: theme.appBarTheme.copyWith(backgroundColor: Colors.transparent),
          ),
          child: Stack(
            children: [
              for (var i = 0; i < pages.length; i++)
                // Semua tab tetap hidup (seperti IndexedStack), tetapi
                // perpindahannya memudar dan sedikit bergeser.
                IgnorePointer(
                  ignoring: i != _index,
                  child: TickerMode(
                    enabled: i == _index,
                    child: AnimatedOpacity(
                      opacity: i == _index ? 1 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      child: AnimatedSlide(
                        offset: i == _index ? Offset.zero : const Offset(0, 0.02),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        child: pages[i],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
