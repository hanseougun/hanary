import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Upload/download lampiran ke Google Drive milik pengguna, di folder "Hanary".
/// Izin `drive.file` hanya memberi akses ke file yang dibuat aplikasi ini.
class DriveService {
  DriveService._();
  static final instance = DriveService._();

  static const _scope = 'https://www.googleapis.com/auth/drive.file';
  static const _api = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';
  static const _mimeFolder = 'application/vnd.google-apps.folder';

  String? _folderId;

  Future<Map<String, String>> _headers() => AuthService.instance.googleHeaders(const [_scope]);

  Never _gagal(http.BaseResponse res, String body) {
    if (res.statusCode == 403 && body.contains('accessNotConfigured')) {
      throw const DriveException('Google Drive API belum diaktifkan untuk aplikasi ini.');
    }
    throw DriveException('Google Drive menolak (${res.statusCode}).');
  }

  Future<String> _folder(Map<String, String> headers) async {
    if (_folderId != null) return _folderId!;
    final q = "name='Hanary' and mimeType='$_mimeFolder' and trashed=false";
    final cari = await http.get(
      Uri.parse(_api).replace(queryParameters: {'q': q, 'fields': 'files(id)', 'spaces': 'drive'}),
      headers: headers,
    );
    if (cari.statusCode != 200) _gagal(cari, cari.body);
    final ada = (jsonDecode(cari.body)['files'] as List).cast<Map<String, dynamic>>();
    if (ada.isNotEmpty) return _folderId = ada.first['id'] as String;

    final buat = await http.post(
      Uri.parse('$_api?fields=id'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'name': 'Hanary', 'mimeType': _mimeFolder}),
    );
    if (buat.statusCode != 200) _gagal(buat, buat.body);
    return _folderId = jsonDecode(buat.body)['id'] as String;
  }

  /// Mengunggah file dan mengembalikan id file di Drive.
  /// Memakai upload "resumable" agar file besar tidak dimuat sekaligus ke memori.
  Future<String> unggah(File file, String nama) async {
    final headers = await _headers();
    final folder = await _folder(headers);
    final ukuran = await file.length();
    final sesi = await http.post(
      Uri.parse('$_upload?uploadType=resumable&fields=id'),
      headers: {
        ...headers,
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Length': '$ukuran',
      },
      body: jsonEncode({
        'name': nama,
        'parents': [folder],
      }),
    );
    final lokasi = sesi.headers['location'];
    if (sesi.statusCode != 200 || lokasi == null) _gagal(sesi, sesi.body);

    final kirim = http.StreamedRequest('PUT', Uri.parse(lokasi))
      ..headers.addAll(headers)
      ..contentLength = ukuran;
    final respons = kirim.send();
    await kirim.sink.addStream(file.openRead());
    await kirim.sink.close();
    final hasil = await respons;
    final body = await hasil.stream.bytesToString();
    if (hasil.statusCode != 200 && hasil.statusCode != 201) _gagal(hasil, body);
    return jsonDecode(body)['id'] as String;
  }

  /// Mengunduh file dari Drive ke [tujuan].
  Future<void> unduh(String id, File tujuan) async {
    final req = http.Request('GET', Uri.parse('$_api/$id?alt=media'))..headers.addAll(await _headers());
    final client = http.Client();
    try {
      final res = await client.send(req);
      if (res.statusCode != 200) _gagal(res, await res.stream.bytesToString());
      final sementara = File('${tujuan.path}.unduh');
      final sink = sementara.openWrite();
      await sink.addStream(res.stream);
      await sink.close();
      await sementara.rename(tujuan.path);
    } finally {
      client.close();
    }
  }

  Future<void> hapus(String id) async {
    final res = await http.delete(Uri.parse('$_api/$id'), headers: await _headers());
    if (res.statusCode != 204 && res.statusCode != 404) _gagal(res, res.body);
  }
}

class DriveException implements Exception {
  const DriveException(this.pesan);
  final String pesan;

  @override
  String toString() => pesan;
}
