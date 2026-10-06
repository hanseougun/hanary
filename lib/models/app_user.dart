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
    );
  }
}
