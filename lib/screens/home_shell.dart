import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/chat_notifier.dart';
import '../services/notifikasi_service.dart';
import '../services/presence_service.dart';
import '../widgets/hanary_widgets.dart';
import 'beranda_screen.dart';
import 'chat/chat_room_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

/// Kerangka utama dengan navigasi bawah: Beranda, Chat, Profil.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final AppUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int _index = 0;

  /// Animasi masuk tab yang baru dipilih. Tab lama langsung disembunyikan,
  /// jadi dua halaman tidak pernah tampil bertumpuk.
  late final _masuk = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  late final _pudar = CurvedAnimation(parent: _masuk, curve: Curves.easeOut);
  late final _geser = Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(_pudar);

  void _pilihTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _masuk.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    PresenceService.instance.start(widget.user.uid, tampil: widget.user.tampilOnline);
    ChatNotifier.instance.start(widget.user.uid);
    NotifikasiService.instance.ketukChat.addListener(_bukaChatDariNotifikasi);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bukaChatDariNotifikasi());
  }

  @override
  void didUpdateWidget(covariant HomeShell old) {
    super.didUpdateWidget(old);
    PresenceService.instance.setTampil(widget.user.tampilOnline);
  }

  @override
  void dispose() {
    NotifikasiService.instance.ketukChat.removeListener(_bukaChatDariNotifikasi);
    _pudar.dispose();
    _masuk.dispose();
    super.dispose();
  }

  /// Notifikasi pesan diketuk: buka chat-nya.
  void _bukaChatDariNotifikasi() {
    final chatId = NotifikasiService.instance.ketukChat.value;
    if (chatId == null || !mounted) return;
    NotifikasiService.instance.ketukChat.value = null;
    _pilihTab(1);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatRoomScreen(chatId: chatId, me: widget.user.uid),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      BerandaScreen(user: widget.user),
      ChatScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
    // Bilah judul transparan agar latar tema terlihat, tetapi menjadi
    // pekat saat isi halaman digulir ke bawahnya (agar tidak tumpang tindih).
    final latarBilah = theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    return Scaffold(
      body: LatarHanary(
        // Halaman di dalam tab dibuat transparan agar latar tema terlihat.
        child: Theme(
          data: theme.copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.scrolledUnder) ? latarBilah : Colors.transparent,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < pages.length; i++)
                // Semua tab tetap hidup (isi dan posisi gulir tidak hilang),
                // tetapi hanya tab aktif yang digambar.
                Offstage(
                  offstage: i != _index,
                  child: TickerMode(
                    enabled: i == _index,
                    // Tombol tab tersembunyi tidak ikut "terbang" saat pindah halaman.
                    child: HeroMode(
                      enabled: i == _index,
                      child: FadeTransition(
                        opacity: i == _index ? _pudar : kAlwaysCompleteAnimation,
                        child: SlideTransition(
                          position: i == _index ? _geser : const AlwaysStoppedAnimation(Offset.zero),
                          child: pages[i],
                        ),
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
        onDestinationSelected: _pilihTab,
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
