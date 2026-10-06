import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

/// Foto profil dan foto grup yang diunggah sendiri.
///
/// Foto diperkecil (maks. 512 px) lalu disimpan langsung di Firestore:
/// `avatars/{uid}` dan `groupAvatars/{chatId}`. Dokumen profil/grup
/// menyimpan nomor versi (`fotoVer`) agar HP lain tahu ada foto baru.
class AvatarService {
  AvatarService._();
  static final instance = AvatarService._();

  final _db = FirebaseFirestore.instance;
  final _cache = <String, Future<Uint8List?>>{};

  Future<Uint8List?> fotoUser(String uid, int ver) => _muat('avatars', uid, ver);
  Future<Uint8List?> fotoGrup(String chatId, int ver) => _muat('groupAvatars', chatId, ver);

  Future<Uint8List?> _muat(String koleksi, String id, int ver) {
    return _cache.putIfAbsent('$koleksi/$id@$ver', () async {
      try {
        final snap = await _db.collection(koleksi).doc(id).get();
        final blob = snap.data()?['data'];
        return blob is Blob ? blob.bytes : null;
      } catch (_) {
        _cache.remove('$koleksi/$id@$ver');
        return null;
      }
    });
  }

  /// Memilih foto dari galeri dan memperkecilnya. Null jika batal.
  Future<Uint8List?> pilihFoto() async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (foto == null) return null;
    final bytes = await foto.readAsBytes();
    if (bytes.length > 400 * 1024) throw StateError('Foto terlalu besar, coba foto lain.');
    return bytes;
  }

  Future<void> simpanFotoUser(String uid, Uint8List bytes) async {
    final ver = DateTime.now().millisecondsSinceEpoch;
    _cache['avatars/$uid@$ver'] = Future.value(bytes);
    await _db.collection('avatars').doc(uid).set({'data': Blob(bytes), 'ver': ver});
    await _db.collection('users').doc(uid).update({'fotoVer': ver});
  }

  Future<void> hapusFotoUser(String uid) async {
    await _db.collection('users').doc(uid).update({'fotoVer': FieldValue.delete()});
    await _db.collection('avatars').doc(uid).delete();
  }

  Future<void> simpanFotoGrup(String chatId, Uint8List bytes) async {
    final ver = DateTime.now().millisecondsSinceEpoch;
    _cache['groupAvatars/$chatId@$ver'] = Future.value(bytes);
    await _db.collection('groupAvatars').doc(chatId).set({'data': Blob(bytes), 'ver': ver});
    await _db.collection('chats').doc(chatId).update({'fotoVer': ver});
  }
}
