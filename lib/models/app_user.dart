import 'package:cloud_firestore/cloud_firestore.dart';

/// Data profil pengguna yang disimpan di Firestore: `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.namaLengkap = '',
    this.sebutan = '',
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
  final String sekolah;
  final String kelas;
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

  /// Profil dianggap lengkap jika nama lengkap dan sebutan sudah diisi.
  bool get isComplete => namaLengkap.trim().isNotEmpty && sebutan.trim().isNotEmpty;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      namaLengkap: data['namaLengkap'] as String? ?? '',
      sebutan: data['sebutan'] as String? ?? '',
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
    String? sekolah,
    String? kelas,
    String? bio,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      sebutan: sebutan ?? this.sebutan,
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
