import 'package:flutter/material.dart';

import '../l10n/bahasa.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../theme/hanary_theme.dart';
import '../widgets/hanary_widgets.dart';
import 'chat/chat_widgets.dart';
import 'chat/lihat_foto.dart';
import 'pengaturan_screen.dart';
import 'profile_form_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});
  final AppUser user;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Keluar dari akun?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Batal'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Keluar'))),
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
            if (user.fotoVer != null || user.fotoUrl != null)
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded),
                title: Text(tr('Lihat foto')),
                onTap: () => Navigator.pop(ctx, 'lihat'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(tr('Pilih foto dari galeri')),
              onTap: () => Navigator.pop(ctx, 'galeri'),
            ),
            if (user.fotoVer != null)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: Text(tr(user.fotoUrl != null ? 'Pakai foto akun Google' : 'Hapus foto')),
                onTap: () => Navigator.pop(ctx, 'hapus'),
              ),
          ],
        ),
      ),
    );
    if (pilihan == null || !context.mounted) return;
    if (pilihan == 'lihat') {
      lihatFotoUser(context, user.uid);
      return;
    }
    try {
      if (pilihan == 'hapus') {
        await AvatarService.instance.hapusFotoUser(user.uid);
        return;
      }
      final foto = await AvatarService.instance.pilihFoto(context);
      if (foto == null) return;
      await AvatarService.instance.simpanFotoUser(user.uid, foto);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Foto profil diganti'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('Gagal mengganti foto: {error}', {'error': e}))));
      }
    }
  }

  void _buka(BuildContext context, Widget halaman) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => halaman));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gaya = GayaHanary.dari(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Profil')),
        actions: [
          IconButton(
            tooltip: tr('Pengaturan'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _buka(context, const PengaturanScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          MunculBertahap(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: gaya.gradasiUtama,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: gaya.gradasi.first.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: GestureDetector(
                      onTap: () => _fotoProfil(context),
                      child: Stack(
                        children: [
                          UserAvatar(uid: user.uid, radius: 46),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: theme.colorScheme.primary,
                              child: Icon(Icons.photo_camera_rounded, size: 16, color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.sebutan,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '"${user.bio}"',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => _buka(context, ProfileFormScreen(user: user)),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(tr('Edit profil')),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          MunculBertahap(
            urutan: 1,
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoTile(icon: Icons.badge_outlined, label: tr('Nama lengkap'), value: user.namaLengkap),
                  _InfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: tr('Username'),
                    value: user.username.isEmpty ? '' : '@${user.username}',
                  ),
                  if (user.peran != null)
                    _InfoTile(icon: Icons.interests_outlined, label: tr('Kegiatan'), value: tr(user.peran!.label)),
                  _InfoTile(
                    icon: user.peran == Peran.pekerja ? Icons.business_outlined : Icons.school_outlined,
                    label: tr(user.labelTempat),
                    value: user.sekolah,
                  ),
                  _InfoTile(
                    icon: user.peran == Peran.pekerja ? Icons.work_outline_rounded : Icons.class_outlined,
                    label: tr(user.labelPosisi),
                    value: user.kelas,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MunculBertahap(
            urutan: 2,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const _IkonBulat(icon: Icons.palette_outlined),
                    title: Text(tr('Pengaturan')),
                    subtitle: Text(tr('Mode gelap, tema latar, privasi')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _buka(context, const PengaturanScreen()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          MunculBertahap(
            urutan: 3,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(tr('Keluar')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IkonBulat extends StatelessWidget {
  const _IkonBulat({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
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
      leading: _IkonBulat(icon: icon),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value.isEmpty ? '-' : value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
