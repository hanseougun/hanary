import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/tugas.dart';

/// Menyimpan gambar/file lampiran tugas di folder aplikasi di HP.
class LampiranService {
  LampiranService._();
  static final instance = LampiranService._();

  Directory? _folder;

  Future<Directory> _folderLampiran() async {
    if (_folder != null) return _folder!;
    final dok = await getApplicationDocumentsDirectory();
    final folder = Directory('${dok.path}/lampiran');
    await folder.create(recursive: true);
    return _folder = folder;
  }

  Future<File> fileDari(Lampiran l) async => File('${(await _folderLampiran()).path}/${l.berkas}');

  Future<bool> ada(Lampiran l) async => (await fileDari(l)).exists();

  /// Memilih satu atau beberapa file (PDF, Word, gambar, dll.) dari HP.
  Future<List<Lampiran>> pilihFile() async {
    final hasil = await FilePicker.pickFiles();
    return [
      for (final f in hasil) await _simpan(f.name, f.readAsByteStream()),
    ];
  }

  /// Memotret tugas dengan kamera.
  Future<Lampiran?> ambilFoto() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (foto == null) return null;
    final nama = 'Foto ${DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ')}.jpg';
    return _simpan(nama, foto.openRead());
  }

  Future<Lampiran> _simpan(String nama, Stream<List<int>> isi) async {
    final folder = await _folderLampiran();
    final aman = nama.replaceAll(RegExp(r'[^\w.\- ]'), '_');
    final berkas = '${DateTime.now().microsecondsSinceEpoch}_$aman';
    final file = File('${folder.path}/$berkas');
    final sink = file.openWrite();
    await sink.addStream(isi);
    await sink.close();
    return Lampiran(nama: nama, berkas: berkas, ukuran: await file.length());
  }

  /// Membuka lampiran dengan aplikasi yang cocok (galeri, pembaca PDF, dll.).
  /// Mengembalikan pesan kesalahan, atau null jika berhasil.
  Future<String?> buka(Lampiran l) async {
    final file = await fileDari(l);
    if (!await file.exists()) return 'File ini tidak ada di HP ini.';
    final hasil = await OpenFilex.open(file.path);
    return hasil.type == ResultType.done ? null : 'Tidak ada aplikasi untuk membuka file ini.';
  }

  Future<void> hapus(Lampiran l) async {
    final file = await fileDari(l);
    if (await file.exists()) await file.delete();
  }
}
