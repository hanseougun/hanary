import 'package:flutter/material.dart';

import '../widgets/hanary_widgets.dart';

/// Kebijakan privasi Hanary dalam bahasa yang mudah dipahami.
class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  static const _bagian = [
    (
      Icons.person_outline_rounded,
      'Data akun dan profil',
      'Saat kamu masuk dengan Google, Hanary menyimpan email, nama, dan foto akun Google-mu, '
          'serta data profil yang kamu isi (nama lengkap, sebutan, sekolah, kelas, dan bio). '
          'Profil ini bisa dilihat pengguna Hanary lain agar mereka bisa menemukan dan menambahkanmu sebagai teman.',
    ),
    (
      Icons.checklist_rounded,
      'Tugas dan deadline',
      'Judul, mata pelajaran, catatan, deadline, dan status tugas disimpan di server Firebase (Google) '
          'agar tidak hilang saat ganti HP. Hanya kamu yang bisa membaca tugasmu, kecuali kamu sendiri yang membagikannya.',
    ),
    (
      Icons.add_to_drive_rounded,
      'Lampiran di Google Drive',
      'Gambar dan file lampiran disimpan di HP-mu dan di Google Drive milikmu sendiri. '
          'Hanary hanya meminta izin "drive.file", artinya Hanary hanya bisa melihat file yang dibuat oleh Hanary, '
          'bukan file lain di Drive-mu. Kamu bisa mencabut izin ini kapan saja di myaccount.google.com/permissions.',
    ),
    (
      Icons.lock_outline_rounded,
      'Chat terenkripsi',
      'Isi pesan chat dienkripsi end-to-end di HP pengirim sebelum dikirim. Server hanya menyimpan pesan yang '
          'sudah teracak, sehingga pengembang Hanary maupun Google tidak bisa membaca isinya. '
          'Kunci rahasia untuk membuka pesan tersimpan aman di HP-mu.',
    ),
    (
      Icons.notifications_none_rounded,
      'Notifikasi',
      'Pengingat deadline dijadwalkan langsung di HP-mu. Kamu bisa mematikan notifikasi kapan saja '
          'lewat pengaturan HP.',
    ),
    (
      Icons.tune_rounded,
      'Pengaturan tampilan',
      'Pilihan mode gelap/terang dan tema latar hanya disimpan di HP-mu.',
    ),
    (
      Icons.block_rounded,
      'Yang tidak kami lakukan',
      'Hanary tidak menampilkan iklan, tidak menjual data, dan tidak membagikan datamu ke pihak lain '
          'selain layanan Google (Firebase dan Google Drive) yang dibutuhkan agar aplikasi berjalan.',
    ),
    (
      Icons.delete_outline_rounded,
      'Menghapus data',
      'Kamu bisa menghapus tugas dan lampiran kapan saja dari aplikasi. Untuk menghapus akun beserta seluruh '
          'datanya, hubungi pengembang Hanary. Folder lampiran di Google Drive bisa kamu hapus sendiri.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Kebijakan privasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          MunculBertahap(
            child: Row(
              children: [
                const LogoHanary(ukuran: 52, bayangan: false),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Privasimu penting. Berikut data yang dipakai Hanary dan cara kami menjaganya.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (i, (ikon, judul, isi)) in _bagian.indexed)
            MunculBertahap(
              urutan: i + 1,
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(ikon, size: 20, color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(judul, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              isi,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Terakhir diperbarui: 6 Oktober 2026',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
