import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/chat_notifier.dart';
import '../services/notifikasi_service.dart';
import '../services/presence_service.dart';
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

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
    super.dispose();
  }

  /// Notifikasi pesan diketuk: buka chat-nya.
  void _bukaChatDariNotifikasi() {
    final chatId = NotifikasiService.instance.ketukChat.value;
    if (chatId == null || !mounted) return;
    NotifikasiService.instance.ketukChat.value = null;
    setState(() => _index = 1);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatRoomScreen(chatId: chatId, me: widget.user.uid),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BerandaScreen(user: widget.user),
      ChatScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
