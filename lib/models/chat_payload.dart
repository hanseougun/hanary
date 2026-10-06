import 'dart:convert';

import 'chat_room.dart';
import 'tugas.dart';

/// Foto atau file yang dikirim di chat. Isinya terenkripsi dan dipecah
/// menjadi beberapa bagian di `chats/{id}/files/{fileId}_{n}`.
class BerkasChat {
  const BerkasChat({
    required this.fileId,
    required this.nama,
    required this.ukuran,
    required this.parts,
    this.durasiMs = 0,
  });

  final String fileId;
  final String nama;
  final int ukuran;
  final int parts;

  /// Lama rekaman untuk pesan suara.
  final int durasiMs;

  factory BerkasChat.fromJson(Map<String, dynamic> j) => BerkasChat(
        fileId: j['fileId'] as String? ?? '',
        nama: j['nama'] as String? ?? 'file',
        ukuran: (j['ukuran'] as num?)?.toInt() ?? 0,
        parts: (j['parts'] as num?)?.toInt() ?? 0,
        durasiMs: (j['durasiMs'] as num?)?.toInt() ?? 0,
      );

  BerkasChat denganDurasi(int ms) => BerkasChat(fileId: fileId, nama: nama, ukuran: ukuran, parts: parts, durasiMs: ms);

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'nama': nama,
        'ukuran': ukuran,
        'parts': parts,
        if (durasiMs > 0) 'durasiMs': durasiMs,
      };
}

/// Tugas yang dibagikan ke teman atau grup (tanpa lampiran).
class TugasBagikan {
  const TugasBagikan({
    required this.judul,
    required this.deadline,
    this.mapel = '',
    this.catatan = '',
  });

  final String judul;
  final String mapel;
  final String catatan;
  final DateTime deadline;

  factory TugasBagikan.dariTugas(Tugas t) =>
      TugasBagikan(judul: t.judul, mapel: t.mapel, catatan: t.catatan, deadline: t.deadline);

  /// Salinan untuk disimpan ke daftar tugas penerima.
  Tugas keTugas() => Tugas(id: '', judul: judul, mapel: mapel, catatan: catatan, deadline: deadline);

  factory TugasBagikan.fromJson(Map<String, dynamic> j) => TugasBagikan(
        judul: j['judul'] as String? ?? '',
        mapel: j['mapel'] as String? ?? '',
        catatan: j['catatan'] as String? ?? '',
        deadline: DateTime.fromMillisecondsSinceEpoch((j['deadline'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'mapel': mapel,
        'catatan': catatan,
        'deadline': deadline.millisecondsSinceEpoch,
      };
}

/// Isi pesan setelah dibuka (didekripsi).
class IsiPesan {
  const IsiPesan.teks(this.teks)
      : kind = MessageKind.teks,
        berkas = null,
        tugas = null;
  const IsiPesan.berkas(this.kind, BerkasChat this.berkas, {this.teks = ''}) : tugas = null;
  const IsiPesan.tugas(TugasBagikan this.tugas)
      : kind = MessageKind.tugas,
        teks = '',
        berkas = null;

  final MessageKind kind;

  /// Teks pesan, atau keterangan foto/file.
  final String teks;
  final BerkasChat? berkas;
  final TugasBagikan? tugas;

  /// Teks yang dienkripsi ke dalam `box`.
  String encode() => switch (kind) {
        MessageKind.teks => teks,
        MessageKind.gambar || MessageKind.file || MessageKind.suara => jsonEncode({...berkas!.toJson(), 'teks': teks}),
        MessageKind.tugas => jsonEncode(tugas!.toJson()),
      };

  /// Membaca teks hasil dekripsi. Pesan lama (sebelum ada jenis pesan)
  /// selalu berupa teks biasa.
  static IsiPesan parse(MessageKind kind, String plain) {
    if (kind == MessageKind.teks) return IsiPesan.teks(plain);
    try {
      final j = Map<String, dynamic>.from(jsonDecode(plain) as Map);
      if (kind == MessageKind.tugas) return IsiPesan.tugas(TugasBagikan.fromJson(j));
      return IsiPesan.berkas(kind, BerkasChat.fromJson(j), teks: j['teks'] as String? ?? '');
    } catch (_) {
      return IsiPesan.teks(plain);
    }
  }

  /// Ringkasan satu baris untuk daftar chat dan notifikasi.
  String ringkas() => switch (kind) {
        MessageKind.teks => teks,
        MessageKind.gambar => teks.isEmpty ? '📷 Foto' : '📷 $teks',
        MessageKind.file => '📎 ${berkas!.nama}',
        MessageKind.tugas => '📋 Tugas: ${tugas!.judul}',
        MessageKind.suara => '🎤 Pesan suara (${formatDurasi(berkas!.durasiMs)})',
      };
}

/// Kutipan pesan yang dibalas. Disimpan terenkripsi di field `balas`
/// pada pesan balasan, jadi server tidak bisa membacanya.
class BalasanPesan {
  const BalasanPesan({required this.id, required this.dari, required this.ringkas, this.kind = MessageKind.teks});

  /// Id pesan yang dibalas.
  final String id;

  /// Uid pengirim pesan yang dibalas.
  final String dari;

  /// Ringkasan isi pesan yang dibalas (maks. 120 huruf).
  final String ringkas;
  final MessageKind kind;

  factory BalasanPesan.dariPesan(String id, String dari, IsiPesan isi) {
    final teks = isi.ringkas().replaceAll('\n', ' ');
    return BalasanPesan(
      id: id,
      dari: dari,
      ringkas: teks.length > 120 ? '${teks.substring(0, 119)}…' : teks,
      kind: isi.kind,
    );
  }

  String encode() => jsonEncode({'id': id, 'dari': dari, 'ringkas': ringkas, 'kind': kind.name});

  static BalasanPesan? parse(String plain) {
    try {
      final j = Map<String, dynamic>.from(jsonDecode(plain) as Map);
      return BalasanPesan(
        id: j['id'] as String? ?? '',
        dari: j['dari'] as String? ?? '',
        ringkas: j['ringkas'] as String? ?? '',
        kind: MessageKind.dari(j['kind'] as String?),
      );
    } catch (_) {
      return null;
    }
  }
}

/// "0:07", "1:23".
String formatDurasi(int ms) {
  final detik = (ms / 1000).round();
  return '${detik ~/ 60}:${(detik % 60).toString().padLeft(2, '0')}';
}

/// Penanda `lastKind` ruang chat saat pesan terakhir ditarik.
const lastKindDitarik = 'ditarik';
