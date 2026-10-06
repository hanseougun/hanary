import 'package:flutter/material.dart';

import '../models/app_user.dart';

/// Halaman utama. Daftar tugas akan diisi pada tahap berikutnya.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key, required this.user});
  final AppUser user;

  String _salam() {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Selamat pagi';
    if (jam < 15) return 'Selamat siang';
    if (jam < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_salam()},', style: theme.textTheme.titleMedium),
          Text(
            user.sebutan,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: _StatCard(label: 'Belum', value: 0, icon: Icons.radio_button_unchecked)),
              SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Dikerjakan', value: 0, icon: Icons.timelapse)),
              SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Selesai', value: 0, icon: Icons.check_circle_outline)),
            ],
          ),
          const SizedBox(height: 32),
          Icon(Icons.inbox_outlined, size: 64, color: colors.outline),
          const SizedBox(height: 12),
          Text(
            'Belum ada tugas',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Fitur mencatat tugas dan deadline segera hadir.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text('$value', style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
