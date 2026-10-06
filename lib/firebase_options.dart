// Konfigurasi Firebase proyek `hanary-b3341` (diambil dari google-services.json).
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase baru dikonfigurasi untuk Android. '
      'Platform lain perlu didaftarkan dulu di Firebase.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhz0ol9NBhAX5BnH7LiOgd1uZRSRfHY1w',
    appId: '1:777249753274:android:faa54352ed24da98739a83',
    messagingSenderId: '777249753274',
    projectId: 'hanary-b3341',
    storageBucket: 'hanary-b3341.firebasestorage.app',
  );
}
