import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'l10n/bahasa.dart';
import 'services/chat_notifier.dart';
import 'services/notifikasi_service.dart';
import 'services/push_service.dart';
import 'theme/pengaturan_tampilan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting();
  await PengaturanBahasa.instance.muat();
  await NotifikasiService.instance.init();
  await PengaturanTampilan.instance.muat();
  await ChatNotifier.daftarLatar();
  // Pesan/panggilan masuk saat aplikasi tertutup (notifikasi instan).
  if (!kIsWeb) FirebaseMessaging.onBackgroundMessage(pushLatar);
  runApp(const HanaryApp());
}
