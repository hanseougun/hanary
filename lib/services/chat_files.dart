import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_payload.dart';
import 'chat_crypto.dart';

/// Foto dan file di chat.
///
/// File dienkripsi di HP dengan kunci ruang chat, dipotong-potong, lalu
/// disimpan di Firestore `chats/{chatId}/files/{fileId}_{n}`. Hanya anggota
/// chat yang bisa mengunduh dan membukanya. Tidak butuh Firebase Storage
/// (yang mewajibkan paket berbayar), jadi tetap gratis.
class ChatFiles {
  ChatFiles._();
  static final instance = ChatFiles._();

  /// Batas ukuran satu file (kuota gratis Firestore 1 GB untuk semua pengguna).
  static const maxUkuran = 10 * 1024 * 1024;

  /// Ukuran satu potongan (batas satu dokumen Firestore 1 MB).
  static const _potongan = 700 * 1024;

  final _db = FirebaseFirestore.instance;
  final _unduhan = <String, Future<File>>{};
  Directory? _dir;

  CollectionReference<Map<String, dynamic>> _files(String chatId) =>
      _db.collection('chats').doc(chatId).collection('files');

  Future<Directory> _folder() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/chat_files');
    await dir.create(recursive: true);
    return _dir = dir;
  }

  static String _aman(String nama) => nama.replaceAll(RegExp(r'[^\w.\- ]'), '_');

  /// Salinan file di HP ini.
  Future<File> fileLokal(BerkasChat b) async =>
      File('${(await _folder()).path}/${b.fileId}_${_aman(b.nama)}');

  /// Mengenkripsi dan mengunggah file. [onProgress] menerima nilai 0..1.
  Future<BerkasChat> unggah({
    required String chatId,
    required String me,
    required SecretKey key,
    required String nama,
    required Uint8List isi,
    void Function(double)? onProgress,
  }) async {
    if (isi.length > maxUkuran) {
      throw const FileTerlaluBesar();
    }
    final fileId = _files(chatId).doc().id;
    final parts = max(1, (isi.length / _potongan).ceil());
    for (var n = 0; n < parts; n++) {
      final potong = isi.sublist(n * _potongan, min(isi.length, (n + 1) * _potongan));
      final enc = await ChatCrypto.encryptBytes(potong, key, '$chatId|$fileId|$n');
      await _files(chatId).doc('${fileId}_$n').set({
        'data': Blob(Uint8List.fromList(enc)),
        'by': me,
        'createdAt': FieldValue.serverTimestamp(),
      });
      onProgress?.call((n + 1) / parts);
    }
    final berkas = BerkasChat(fileId: fileId, nama: nama, ukuran: isi.length, parts: parts);
    await (await fileLokal(berkas)).writeAsBytes(isi, flush: true);
    return berkas;
  }

  /// Mengunduh dan membuka enkripsi file, atau memakai salinan di HP.
  Future<File> unduh(String chatId, BerkasChat b, SecretKey key) {
    return _unduhan.putIfAbsent(b.fileId, () async {
      try {
        final file = await fileLokal(b);
        if (await file.exists()) return file;
        final hasil = BytesBuilder(copy: false);
        for (var n = 0; n < b.parts; n++) {
          final snap = await _files(chatId).doc('${b.fileId}_$n').get();
          final blob = snap.data()?['data'];
          if (blob is! Blob) throw StateError('Bagian file tidak ditemukan.');
          hasil.add(await ChatCrypto.decryptBytes(blob.bytes, key, '$chatId|${b.fileId}|$n'));
        }
        final tmp = File('${file.path}.part');
        await tmp.writeAsBytes(hasil.takeBytes(), flush: true);
        return await tmp.rename(file.path);
      } catch (_) {
        _unduhan.remove(b.fileId);
        rethrow;
      }
    });
  }

  /// Menghapus potongan file di server dan salinannya di HP
  /// (dipakai saat pesan ditarik). Gagal pun tidak masalah.
  Future<void> hapus(String chatId, BerkasChat b) async {
    final files = _files(chatId);
    for (var n = 0; n < b.parts; n++) {
      await files.doc('${b.fileId}_$n').delete().catchError((Object _) {});
    }
    try {
      final f = await fileLokal(b);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

class FileTerlaluBesar implements Exception {
  const FileTerlaluBesar();

  @override
  String toString() => 'File terlalu besar. Maksimal 10 MB per file.';
}

/// Ukuran file yang mudah dibaca, mis. "1,2 MB".
String formatUkuran(int byte) {
  if (byte < 1024) return '$byte B';
  if (byte < 1024 * 1024) return '${(byte / 1024).toStringAsFixed(0)} KB';
  return '${(byte / 1024 / 1024).toStringAsFixed(1).replaceAll('.', ',')} MB';
}
