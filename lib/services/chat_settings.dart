import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan chat.
///
/// - Notifikasi pesan disimpan di HP (SharedPreferences), karena dibaca
///   juga oleh pemeriksaan latar belakang.
/// - Privasi (status online, tanda dibaca) disimpan di profil `users/{uid}`
///   bagian `privasi`, agar ikut terbawa saat ganti HP.
class ChatSettings {
  ChatSettings._();

  static const kunciNotif = 'notif_chat';

  static Future<bool> notifAktif() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool(kunciNotif) ?? true;
  }

  static Future<void> setNotif(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kunciNotif, aktif);
  }

  static Future<void> setPrivasi(String uid, {bool? online, bool? dibaca}) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'privasi': {
        if (online != null) 'online': online,
        if (dibaca != null) 'dibaca': dibaca,
      },
    }, SetOptions(merge: true));
  }
}
