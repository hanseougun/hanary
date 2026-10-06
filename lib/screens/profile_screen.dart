import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import 'chat/chat_widgets.dart';
import 'pengaturan/pengaturan_chat_screen.dart';
import 'profile_form_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});
  final AppUser user;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true) await AuthService.instance.signOut();
  }

  Future<void> _fotoProfil(BuildContext context) async {
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih foto dari galeri'),
              onTap: () => Navigator.pop(ctx, 'galeri'),
            ),
            if (user.fotoVer != null)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: Text(user.fotoUrl != null ? 'Pakai foto akun Google' : 'Hapus foto'),
                onTap: () => Navigator.pop(ctx, 'hapus'),
              ),
          ],
        ),
      ),
    );
    if (pilihan == null) return;
    try {
      if (pilihan == 'hapus') {
        await AvatarService.instance.hapusFotoUser(user.uid);
        return;
      }
      final foto = await AvatarService.instance.pilihFoto();
      if (foto == null) return;
      await AvatarService.instance.simpanFotoUser(user.uid, foto);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil diganti')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengganti foto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Edit profil',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProfileFormScreen(user: user),
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _fotoProfil(context),
              child: Stack(
                children: [
                  UserAvatar(uid: user.uid, radius: 48),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(Icons.photo_camera, size: 16, color: theme.colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.sebutan, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          Text(user.email, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          _InfoTile(icon: Icons.badge_outlined, label: 'Nama lengkap', value: user.namaLengkap),
          _InfoTile(icon: Icons.school_outlined, label: 'Sekolah / kampus', value: user.sekolah),
          _InfoTile(icon: Icons.class_outlined, label: 'Kelas / jurusan', value: user.kelas),
          _InfoTile(icon: Icons.notes_outlined, label: 'Bio', value: user.bio),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: const Text('Chat & privasi'),
            subtitle: const Text('Notifikasi pesan, status online, tanda dibaca'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PengaturanChatScreen(uid: user.uid),
            )),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
  }
}
