import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/bahasa.dart';

/// Kegiatan utama pengguna; menentukan label isian tempat dan posisi di profil.
enum Peran {
  pelajar('Pelajar', 'Sekolah', 'Kelas'),
  mahasiswa('Mahasiswa', 'Kampus', 'Jurusan'),
  pekerja('Pekerja / kantoran', 'Perusahaan / instansi', 'Jabatan / pekerjaan'),
  lainnya('Lainnya', 'Tempat / komunitas', 'Keterangan');

  const Peran(this.label, this.labelTempat, this.labelPosisi);
  final String label;
  final String labelTempat;
  final String labelPosisi;

  /// Label-label di atas dalam bahasa yang dipilih, untuk ditampilkan.
  String get labelTr => tr(label);
  String get labelTempatTr => tr(labelTempat);
  String get labelPosisiTr => tr(labelPosisi);

  static Peran? dari(String? nama) => Peran.values.where((p) => p.name == nama).firstOrNull;
}

/// Aturan username: 3–20 huruf kecil, angka, titik, atau garis bawah.
final polaUsername = RegExp(r'^[a-z0-9._]{3,20}$');

/// Data profil pengguna yang disimpan di Firestore: `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.namaLengkap = '',
    this.sebutan = '',
    this.username = '',
    this.peran,
    this.sekolah = '',
    this.kelas = '',
    this.bio = '',
    this.fotoUrl,
    this.fotoVer,
    this.online = false,
    this.lastSeen,
    this.tampilOnline = true,
    this.kirimDibaca = true,
  });

  final String uid;
  final String email;
  final String namaLengkap;

  /// Nama panggilan yang dipakai untuk menyapa, mis. "Gun".
  final String sebutan;

  /// Nama unik untuk dicari teman, mis. "gun.hans" (ditampilkan "@gun.hans").
  final String username;

  /// Pelajar, mahasiswa, pekerja, dll. Null untuk profil lama.
  final Peran? peran;

  /// Sekolah / kampus / perusahaan (tergantung [peran]).
  final String sekolah;

  /// Kelas / jurusan / jabatan (tergantung [peran]).
  final String kelas;

  /// Label isian tempat sesuai peran.
  String get labelTempat => peran?.labelTempat ?? 'Sekolah / kampus';

  /// Label isian posisi sesuai peran.
  String get labelPosisi => peran?.labelPosisi ?? 'Kelas / jurusan';

  /// [labelTempat] dalam bahasa yang dipilih, untuk ditampilkan.
  String get labelTempatTr => tr(labelTempat);

  /// [labelPosisi] dalam bahasa yang dipilih, untuk ditampilkan.
  String get labelPosisiTr => tr(labelPosisi);
  final String bio;
  final String? fotoUrl;

  /// Versi foto profil yang diunggah sendiri (`avatars/{uid}`). Jika null,
  /// dipakai foto akun Google ([fotoUrl]).
  final int? fotoVer;

  /// Status online yang ditulis aplikasi. Dianggap kedaluwarsa jika
  /// [lastSeen] sudah lama (mis. aplikasi ditutup paksa).
  final bool online;
  final DateTime? lastSeen;

  /// Pengaturan privasi: tampilkan status online ke orang lain.
  final bool tampilOnline;

  /// Pengaturan privasi: kirim tanda "sudah dibaca".
  final bool kirimDibaca;

  /// Sedang online sekarang?
  bool get sedangOnline =>
      online && lastSeen != null && DateTime.now().difference(lastSeen!) < const Duration(minutes: 5);

  /// Profil dianggap lengkap jika nama lengkap, sebutan, dan username sudah diisi.
  bool get isComplete => namaLengkap.trim().isNotEmpty && sebutan.trim().isNotEmpty && polaUsername.hasMatch(username);

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      namaLengkap: data['namaLengkap'] as String? ?? '',
      sebutan: data['sebutan'] as String? ?? '',
      username: data['username'] as String? ?? '',
      peran: Peran.dari(data['peran'] as String?),
      sekolah: data['sekolah'] as String? ?? '',
      kelas: data['kelas'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      fotoUrl: data['fotoUrl'] as String?,
      fotoVer: (data['fotoVer'] as num?)?.toInt(),
      online: data['online'] == true,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      tampilOnline: (data['privasi'] as Map?)?['online'] != false,
      kirimDibaca: (data['privasi'] as Map?)?['dibaca'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'namaLengkap': namaLengkap.trim(),
      'sebutan': sebutan.trim(),
      'sebutanLower': sebutan.trim().toLowerCase(),
      'username': username,
      if (peran != null) 'peran': peran!.name,
      'sekolah': sekolah.trim(),
      'kelas': kelas.trim(),
      'bio': bio.trim(),
      'fotoUrl': fotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? namaLengkap,
    String? sebutan,
    String? username,
    Peran? peran,
    String? sekolah,
    String? kelas,
    String? bio,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      sebutan: sebutan ?? this.sebutan,
      username: username ?? this.username,
      peran: peran ?? this.peran,
      sekolah: sekolah ?? this.sekolah,
      kelas: kelas ?? this.kelas,
      bio: bio ?? this.bio,
      fotoUrl: fotoUrl,
      fotoVer: fotoVer,
      online: online,
      lastSeen: lastSeen,
      tampilOnline: tampilOnline,
      kirimDibaca: kirimDibaca,
    );
  }
}
