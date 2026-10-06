import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/chat_room.dart';
import 'package:tugasku/screens/chat/riwayat_panggilan.dart';
import 'package:tugasku/services/obrolan_saya.dart';
import 'package:tugasku/services/panggilan_service.dart';

ChatRoom grup({String? admin, List<String> members = const ['ani', 'budi', 'cici']}) =>
    ChatRoom(id: 'g1', isGroup: true, members: members, keys: const {}, admin: admin);

Panggilan panggilan({
  String dari = 'ani',
  List<String> anggota = const ['ani', 'budi'],
  List<String> ikut = const [],
  List<String> tolak = const [],
  List<String> pernah = const ['ani'],
  StatusPanggilan status = StatusPanggilan.selesai,
  DateTime? dibuat,
  DateTime? mulai,
  DateTime? selesai,
}) =>
    Panggilan(
      id: 'c1',
      chatId: 'p_ani_budi',
      dari: dari,
      video: false,
      grup: false,
      anggota: anggota,
      ikut: ikut,
      tolak: tolak,
      status: status,
      dibuat: dibuat ?? DateTime.now(),
      pernah: pernah,
      mulai: mulai,
      selesai: selesai,
    );

void main() {
  group('Pemilik grup', () {
    test('pemilik adalah admin jika masih anggota', () {
      expect(grup(admin: 'budi').pemilik, 'budi');
      expect(grup(admin: 'budi').isPemilik('budi'), isTrue);
      expect(grup(admin: 'budi').isPemilik('ani'), isFalse);
    });

    test('pemilik yang sudah keluar digantikan anggota pertama', () {
      expect(grup(admin: 'dodi').pemilik, 'ani');
      expect(grup().pemilik, 'ani');
    });

    test('chat pribadi tidak punya pemilik', () {
      const room = ChatRoom(id: 'p_a_b', isGroup: false, members: ['a', 'b'], keys: {});
      expect(room.pemilik, isNull);
      expect(room.isPemilik('a'), isFalse);
    });
  });

  group('Hapus obrolan', () {
    final dihapus = DateTime(2026, 10, 6, 12);
    final status = StatusObrolan(hapusSebelum: dihapus);

    test('chat tersembunyi sampai ada pesan baru', () {
      expect(status.tersembunyi(dihapus), isTrue);
      expect(status.tersembunyi(null), isTrue);
      expect(status.tersembunyi(dihapus.add(const Duration(seconds: 1))), isFalse);
      expect(StatusObrolan.kosong.tersembunyi(dihapus), isFalse);
    });

    test('pesan lama ikut terhapus, pesan baru dan yang belum terkirim tidak', () {
      expect(status.pesanTerhapus(dihapus.subtract(const Duration(minutes: 1))), isTrue);
      expect(status.pesanTerhapus(dihapus.add(const Duration(minutes: 1))), isFalse);
      expect(status.pesanTerhapus(null), isFalse);
    });
  });

  group('Riwayat panggilan', () {
    test('jenis panggilan dari sudut pandang saya', () {
      expect(jenisRiwayat(panggilan(), 'ani'), JenisRiwayat.keluar);
      expect(jenisRiwayat(panggilan(pernah: ['ani', 'budi']), 'budi'), JenisRiwayat.masuk);
      expect(jenisRiwayat(panggilan(), 'budi'), JenisRiwayat.takTerjawab);
      expect(jenisRiwayat(panggilan(tolak: ['budi']), 'budi'), JenisRiwayat.ditolak);
      // Panggilan lama tanpa daftar "pernah".
      expect(jenisRiwayat(panggilan(pernah: []), 'budi'), JenisRiwayat.masuk);
    });

    test('keterangan memuat lama bicara', () {
      final mulai = DateTime(2026, 10, 6, 10);
      final p = panggilan(pernah: ['ani', 'budi'], mulai: mulai, selesai: mulai.add(const Duration(seconds: 185)));
      expect(keteranganRiwayat(p, 'budi'), 'Masuk · 3:05');
      expect(keteranganRiwayat(panggilan(), 'ani'), 'Tidak dijawab');
      expect(keteranganRiwayat(panggilan(), 'budi'), 'Tak terjawab');
    });

    test('panggilan dengan lebih dari dua orang diperlakukan seperti grup', () {
      expect(panggilan().ramai, isFalse);
      expect(panggilan(anggota: ['ani', 'budi', 'eka']).ramai, isTrue);
    });
  });

  group('Orang yang diajak ke panggilan', () {
    final lama = DateTime.now().subtract(const Duration(minutes: 10));
    final p = panggilan(
      anggota: ['ani', 'budi', 'eka'],
      ikut: ['ani', 'budi'],
      status: StatusPanggilan.berlangsung,
      dibuat: lama,
    );

    test('panggilan lama bisa berdering lagi jika baru diajak', () {
      expect(p.bisaDiangkat('eka'), isFalse);
      expect(p.bisaDiangkat('eka', dipanggil: DateTime.now()), isTrue);
    });

    test('yang sudah ikut atau bukan anggota tidak berdering', () {
      expect(p.bisaDiangkat('budi', dipanggil: DateTime.now()), isFalse);
      expect(p.bisaDiangkat('cici', dipanggil: DateTime.now()), isFalse);
    });
  });
}
