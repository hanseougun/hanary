import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../theme/hanary_theme.dart';
import '../../widgets/hanary_widgets.dart';
import 'chat_widgets.dart';
import 'lihat_foto.dart';

/// Membuka profil orang lain (foto, nama, bio, sekolah, kelas).
void bukaProfil(BuildContext context, String uid, {VoidCallback? onKirimPesan}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ProfilOrangScreen(uid: uid, onKirimPesan: onKirimPesan),
  ));
}

/// Profil orang lain yang dibuka dari chat, daftar teman, atau anggota grup.
class ProfilOrangScreen extends StatelessWidget {
  const ProfilOrangScreen({super.key, required this.uid, this.onKirimPesan});
  final String uid;

  /// Jika diisi, tampil tombol "Kirim pesan".
  final VoidCallback? onKirimPesan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gaya = GayaHanary.dari(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: UserBuilder(
        uid: uid,
        builder: (context, user) {
          if (user == null) return const Center(child: CircularProgressIndicator());
          final nama = user.sebutan.isNotEmpty ? user.sebutan : user.namaLengkap;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              MunculBertahap(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    gradient: gaya.gradasiUtama,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: GestureDetector(
                          onTap: () => lihatFotoUser(context, uid),
                          child: UserAvatar(uid: uid, radius: 46),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nama,
                        textAlign: TextAlign.center,
                        style:
                            theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      PresenceText(
                        uid: uid,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '"${user.bio}"',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (onKirimPesan != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onKirimPesan!();
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Kirim pesan'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.22),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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
                      _Baris(icon: Icons.badge_outlined, label: 'Nama lengkap', nilai: user.namaLengkap),
                  _Baris(
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    nilai: user.username.isEmpty ? '' : '@${user.username}',
                  ),
                  if (user.peran != null)
                    _Baris(icon: Icons.interests_outlined, label: 'Kegiatan', nilai: user.peran!.label),
                      _Baris(
                    icon: user.peran == Peran.pekerja ? Icons.business_outlined : Icons.school_outlined,
                    label: user.labelTempat,
                    nilai: user.sekolah,
                  ),
                      _Baris(
                    icon: user.peran == Peran.pekerja ? Icons.work_outline_rounded : Icons.class_outlined,
                    label: user.labelPosisi,
                    nilai: user.kelas,
                  ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.icon, required this.label, required this.nilai});
  final IconData icon;
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
      ),
      title: Text(label, style: theme.textTheme.bodySmall),
      subtitle: Text(
        nilai.isEmpty ? '-' : nilai,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
