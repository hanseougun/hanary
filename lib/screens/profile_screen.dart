import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foto = user.fotoUrl;
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
            child: CircleAvatar(
              radius: 48,
              backgroundImage: foto != null ? NetworkImage(foto) : null,
              child: foto == null
                  ? Text(
                      user.sebutan.isNotEmpty ? user.sebutan[0].toUpperCase() : '?',
                      style: theme.textTheme.headlineMedium,
                    )
                  : null,
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
