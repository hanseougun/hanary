// File ini SEMENTARA. Jalankan `flutterfire configure` di folder proyek
// dan file ini akan otomatis diganti dengan konfigurasi Firebase milikmu.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase belum dikonfigurasi. Jalankan `flutterfire configure` '
      'terlebih dahulu (lihat README.md).',
    );
  }
}
