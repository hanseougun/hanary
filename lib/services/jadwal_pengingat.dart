import '../l10n/bahasa.dart';
import '../models/tugas.dart';

/// Jenis pengingat deadline.
enum JenisPengingat {
  /// Pengingat harian jam 12.00 dan 18.00 selama tugas belum selesai.
  harian,

  /// 1 jam, 30, 15, dan 5 menit sebelum deadline.
  menjelang,

  /// Saat deadline lewat dan tugas belum ditandai Selesai.
  terlewat,
}

/// Satu notifikasi pengingat yang akan dijadwalkan.
class Pengingat {
  const Pengingat({
    required this.kunci,
    required this.waktu,
    required this.jenis,
    required this.tugas,
    this.menitSebelum = 0,
  });

  /// Kunci unik (dipakai untuk membuat id notifikasi).
  final String kunci;
  final DateTime waktu;
  final JenisPengingat jenis;

  /// Tugas yang diingatkan. Pengingat harian bisa berisi beberapa tugas
  /// sekaligus (urut deadline terdekat); jenis lain selalu satu tugas.
  final List<Tugas> tugas;

  /// Untuk jenis [JenisPengingat.menjelang]: berapa menit sebelum deadline.
  final int menitSebelum;
}

/// Jam pengingat harian.
const jamPengingatHarian = [12, 18];

/// Menit sebelum deadline untuk pengingat menjelang.
const menitPengingatMenjelang = [60, 30, 15, 5];

/// Pengingat harian dijadwalkan paling jauh sekian hari ke depan.
/// Jadwal diperbarui setiap kali aplikasi dibuka atau tugas berubah.
const batasHariPengingatHarian = 14;

/// Android membatasi jumlah alarm per aplikasi, jadi total pengingat dibatasi.
const batasJumlahPengingat = 150;

/// Menghitung semua pengingat yang perlu dijadwalkan dari daftar tugas.
/// Tugas berstatus Selesai tidak diingatkan lagi.
List<Pengingat> hitungPengingat(List<Tugas> semua, DateTime sekarang) {
  final aktif = semua.where((t) => t.id.isNotEmpty && t.status != StatusTugas.selesai).toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));
  final hasil = <Pengingat>[];

  for (final t in aktif) {
    for (final menit in menitPengingatMenjelang) {
      final waktu = t.deadline.subtract(Duration(minutes: menit));
      if (!waktu.isAfter(sekarang)) continue;
      hasil.add(Pengingat(
        kunci: '${t.id}:$menit',
        waktu: waktu,
        jenis: JenisPengingat.menjelang,
        tugas: [t],
        menitSebelum: menit,
      ));
    }
    if (t.deadline.isAfter(sekarang)) {
      hasil.add(Pengingat(
        kunci: '${t.id}:lewat',
        waktu: t.deadline,
        jenis: JenisPengingat.terlewat,
        tugas: [t],
      ));
    }
  }

  final berjalan = aktif.where((t) => t.deadline.isAfter(sekarang)).toList();
  if (berjalan.isNotEmpty) {
    final terakhir = berjalan.last.deadline;
    for (var hari = 0; hari <= batasHariPengingatHarian; hari++) {
      for (final jam in jamPengingatHarian) {
        final waktu = DateTime(sekarang.year, sekarang.month, sekarang.day + hari, jam);
        if (!waktu.isAfter(sekarang) || !waktu.isBefore(terakhir)) continue;
        final daftar = berjalan.where((t) => t.deadline.isAfter(waktu)).toList();
        if (daftar.isEmpty) continue;
        hasil.add(Pengingat(
          kunci: 'harian:${waktu.year}-${waktu.month}-${waktu.day}-$jam',
          waktu: waktu,
          jenis: JenisPengingat.harian,
          tugas: daftar,
        ));
      }
    }
  }

  hasil.sort((a, b) => a.waktu.compareTo(b.waktu));
  return hasil.length > batasJumlahPengingat ? hasil.sublist(0, batasJumlahPengingat) : hasil;
}

/// "2 hari 3 jam", "5 jam 20 menit", "15 menit".
String teksSisa(Duration sisa) {
  final menitTotal = (sisa.inSeconds / 60).ceil();
  final hari = menitTotal ~/ (24 * 60);
  final jam = (menitTotal % (24 * 60)) ~/ 60;
  final menit = menitTotal % 60;
  if (hari > 0) {
    return jam > 0 ? tr('{hari} hari {jam} jam', {'hari': hari, 'jam': jam}) : tr('{hari} hari', {'hari': hari});
  }
  if (jam > 0) {
    return menit > 0 ? tr('{jam} jam {menit} menit', {'jam': jam, 'menit': menit}) : tr('{jam} jam', {'jam': jam});
  }
  return tr('{menit} menit', {'menit': menit});
}
