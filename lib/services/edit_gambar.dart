import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../l10n/bahasa.dart';

/// Membuka layar edit foto (potong, putar, perbesar) sebelum foto dikirim
/// atau dipasang. Mengembalikan path foto hasil edit, atau null jika batal.
///
/// [persegi] untuk foto profil/grup: bingkai bulat dengan rasio 1:1.
Future<String?> editGambar(
  BuildContext context,
  String path, {
  bool persegi = false,
  int maksSisi = 1600,
  int kualitas = 80,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final hasil = await ImageCropper().cropImage(
    sourcePath: path,
    maxWidth: maksSisi,
    maxHeight: maksSisi,
    compressQuality: kualitas,
    aspectRatio: persegi ? const CropAspectRatio(ratioX: 1, ratioY: 1) : null,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: persegi ? tr('Atur foto') : tr('Edit foto'),
        toolbarColor: scheme.surface,
        toolbarWidgetColor: scheme.onSurface,
        statusBarLight: scheme.brightness == Brightness.light,
        navBarLight: scheme.brightness == Brightness.light,
        backgroundColor: Colors.black,
        activeControlsWidgetColor: scheme.primary,
        cropStyle: persegi ? CropStyle.circle : CropStyle.rectangle,
        lockAspectRatio: persegi,
        initAspectRatio: persegi ? CropAspectRatioPreset.square : CropAspectRatioPreset.original,
        aspectRatioPresets: persegi
            ? const [CropAspectRatioPreset.square]
            : const [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
      ),
    ],
  );
  return hasil?.path;
}
