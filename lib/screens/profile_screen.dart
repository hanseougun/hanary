import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/hanary_theme.dart';
import '../widgets/hanary_widgets.dart';
import 'pengaturan_screen.dart';
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

  void _buka(BuildContext context, Widget halaman) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => halaman));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gaya = GayaHanary.dari(context);
    final foto = user.fotoUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
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
                    child: Hero(
                      tag: 'foto-profil',
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: foto != null ? NetworkImage(foto) : null,
                        child: foto == null
                            ? Text(
                                user.sebutan.isNotEmpty ? user.sebutan[0].toUpperCase() : '?',
                                style: theme.textTheme.headlineMedium,
                              )
                            : null,
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
                    label: const Text('Edit profil'),
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
                  _InfoTile(icon: Icons.badge_outlined, label: 'Nama lengkap', value: user.namaLengkap),
                  _InfoTile(icon: Icons.school_outlined, label: 'Sekolah / kampus', value: user.sekolah),
                  _InfoTile(icon: Icons.class_outlined, label: 'Kelas / jurusan', value: user.kelas),
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
                    title: const Text('Pengaturan'),
                    subtitle: const Text('Mode gelap, tema latar, privasi'),
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
              label: const Text('Keluar'),
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
