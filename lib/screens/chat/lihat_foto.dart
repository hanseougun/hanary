import 'package:flutter/material.dart';

import '../../models/chat_room.dart';
import '../../services/avatar_service.dart';
import 'chat_widgets.dart';

/// Membuka foto profil seseorang dalam ukuran besar.
void lihatFotoUser(BuildContext context, String uid) {
  final user = UserFeed.of(uid).last;
  if (user == null) return;
  final judul = user.sebutan.isNotEmpty ? user.sebutan : user.namaLengkap;
  final ver = user.fotoVer;
  if (ver != null) {
    _buka(context, judul, AvatarService.instance.fotoUser(uid, ver).then((b) => b == null ? null : MemoryImage(b)));
  } else if (user.fotoUrl != null) {
    _buka(context, judul, Future.value(NetworkImage(fotoGoogleBesar(user.fotoUrl!))));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$judul belum memasang foto profil.')));
  }
}

/// Membuka foto grup dalam ukuran besar.
void lihatFotoGrup(BuildContext context, ChatRoom room) {
  final ver = room.fotoVer;
  if (ver == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grup ini belum punya foto.')));
    return;
  }
  _buka(
    context,
    room.name,
    AvatarService.instance.fotoGrup(room.id, ver).then((b) => b == null ? null : MemoryImage(b)),
  );
}

/// Foto akun Google biasanya berukuran kecil (mis. `=s96-c`); minta versi besar.
String fotoGoogleBesar(String url) {
  final cocok = RegExp(r'=s\d+(-c)?$').firstMatch(url);
  return cocok == null ? url : '${url.substring(0, cocok.start)}=s1024';
}

void _buka(BuildContext context, String judul, Future<ImageProvider?> gambar) {
  Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    pageBuilder: (_, __, ___) => _LihatFoto(judul: judul, gambar: gambar),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  ));
}

class _LihatFoto extends StatelessWidget {
  const _LihatFoto({required this.judul, required this.gambar});
  final String judul;
  final Future<ImageProvider?> gambar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(judul, style: const TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<ImageProvider?>(
        future: gambar,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final img = snap.data;
          if (img == null) {
            return const Center(
              child: Text('Foto tidak bisa dimuat.', style: TextStyle(color: Colors.white70)),
            );
          }
          return Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: Image(
                image: img,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) =>
                    const Text('Foto tidak bisa dimuat.', style: TextStyle(color: Colors.white70)),
              ),
            ),
          );
        },
      ),
    );
  }
}
