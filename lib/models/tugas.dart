import 'package:cloud_firestore/cloud_firestore.dart';

/// Status pengerjaan tugas.
enum StatusTugas {
  belum('Belum'),
  dikerjakan('Sedang dikerjakan'),
  selesai('Selesai');

  const StatusTugas(this.label);
  final String label;

  static StatusTugas dari(String? nama) =>
      StatusTugas.values.firstWhere((s) => s.name == nama, orElse: () => StatusTugas.belum);
}

/// File atau gambar yang dilampirkan ke tugas.
/// Isinya disimpan di Google Drive pengguna (folder "Hanary") dan disalin di HP;
/// Firestore hanya menyimpan nama dan id-nya.
class Lampiran {
  const Lampiran({required this.nama, required this.berkas, this.ukuran = 0, this.driveId});

  /// Nama asli file, mis. "soal-matematika.pdf".
  final String nama;

  /// Nama file di folder lampiran aplikasi (unik).
  final String berkas;

  /// Ukuran dalam byte.
  final int ukuran;

  /// Id file di Google Drive, null jika belum terunggah.
  final String? driveId;

  Lampiran denganDriveId(String id) => Lampiran(nama: nama, berkas: berkas, ukuran: ukuran, driveId: id);

  bool get isGambar {
    final n = nama.toLowerCase();
    return const ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp'].any(n.endsWith);
  }

  factory Lampiran.fromMap(Map<String, dynamic> data) => Lampiran(
        nama: data['nama'] as String? ?? '',
        berkas: data['berkas'] as String? ?? '',
        ukuran: (data['ukuran'] as num?)?.toInt() ?? 0,
        driveId: data['driveId'] as String?,
      );

  Map<String, dynamic> toMap() =>
      {'nama': nama, 'berkas': berkas, 'ukuran': ukuran, if (driveId != null) 'driveId': driveId};
}

/// Tugas yang disimpan di Firestore: `users/{uid}/tugas/{id}`.
class Tugas {
  const Tugas({
    required this.id,
    required this.judul,
    required this.deadline,
    this.mapel = '',
    this.catatan = '',
    this.status = StatusTugas.belum,
    this.lampiran = const [],
  });

  /// Kosong untuk tugas baru yang belum disimpan.
  final String id;
  final String judul;

  /// Mata pelajaran / mata kuliah.
  final String mapel;
  final String catatan;
  final DateTime deadline;
  final StatusTugas status;
  final List<Lampiran> lampiran;

  bool terlambat([DateTime? sekarang]) =>
      status != StatusTugas.selesai && deadline.isBefore(sekarang ?? DateTime.now());

  factory Tugas.fromMap(String id, Map<String, dynamic> data) {
    final deadline = data['deadline'];
    return Tugas(
      id: id,
      judul: data['judul'] as String? ?? '',
      mapel: data['mapel'] as String? ?? '',
      catatan: data['catatan'] as String? ?? '',
      deadline: deadline is Timestamp ? deadline.toDate() : DateTime.now(),
      status: StatusTugas.dari(data['status'] as String?),
      lampiran: [
        for (final l in (data['lampiran'] as List?) ?? const [])
          if (l is Map) Lampiran.fromMap(Map<String, dynamic>.from(l)),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
        'judul': judul.trim(),
        'mapel': mapel.trim(),
        'catatan': catatan.trim(),
        'deadline': Timestamp.fromDate(deadline),
        'status': status.name,
        'lampiran': [for (final l in lampiran) l.toMap()],
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Tugas copyWith({
    String? id,
    String? judul,
    String? mapel,
    String? catatan,
    DateTime? deadline,
    StatusTugas? status,
    List<Lampiran>? lampiran,
  }) {
    return Tugas(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      mapel: mapel ?? this.mapel,
      catatan: catatan ?? this.catatan,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      lampiran: lampiran ?? this.lampiran,
    );
  }
}
