package com.tugasku.tugasku

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Pengaturan nada notifikasi (memilih nada dari HP, memakai file suara
// sendiri, memutar contoh nada) dan layar panggilan di atas layar kunci.
// Dipanggil dari lib/services/pengaturan_notif.dart dan panggilan_screen.dart.
class MainActivity : FlutterActivity() {
    private var hasilPilih: MethodChannel.Result? = null
    private var contoh: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hanary/nada").setMethodCallHandler { call, result ->
            when (call.method) {
                "pilih" -> pilih(call.argument<String>("uri"), result)
                "bisaSimpanFile" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                "simpanFile" -> simpanFile(call.argument<String>("path")!!, call.argument<String>("nama")!!, result)
                "putar" -> {
                    putar(call.argument<String>("uri"))
                    result.success(null)
                }
                "tampilDiAtasKunci" -> {
                    tampilDiAtasKunci(call.argument<Boolean>("aktif") == true)
                    result.success(null)
                }
                "berhenti" -> {
                    contoh?.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pilih(sekarang: String?, result: MethodChannel.Result) {
        hasilPilih?.success(null)
        hasilPilih = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Pilih nada notifikasi")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, false)
            if (sekarang != null && sekarang.startsWith("content://")) {
                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(sekarang))
            }
        }
        try {
            startActivityForResult(intent, KODE_PILIH)
        } catch (e: Exception) {
            hasilPilih = null
            result.error("tidak_ada", "HP ini tidak punya daftar nada.", null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != KODE_PILIH) return
        val result = hasilPilih ?: return
        hasilPilih = null
        val uri: Uri? = if (resultCode == Activity.RESULT_OK && data != null) {
            if (Build.VERSION.SDK_INT >= 33) {
                data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
            }
        } else null
        if (uri == null) {
            result.success(null)
        } else {
            result.success(mapOf("uri" to uri.toString(), "judul" to judul(uri)))
        }
    }

    private fun judul(uri: Uri): String = try {
        RingtoneManager.getRingtone(this, uri)?.getTitle(this) ?: "Nada pilihan"
    } catch (e: Exception) {
        "Nada pilihan"
    }

    // Menyalin file suara ke folder Notifications agar sistem Android bisa
    // memutarnya sebagai nada notifikasi.
    private fun simpanFile(path: String, nama: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("versi", "Butuh Android 10 ke atas.", null)
            return
        }
        Thread {
            try {
                val ext = nama.substringAfterLast('.', "").lowercase()
                val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "audio/mpeg"
                val values = ContentValues().apply {
                    put(MediaStore.Audio.Media.DISPLAY_NAME, nama)
                    put(MediaStore.Audio.Media.MIME_TYPE, mime)
                    put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_NOTIFICATIONS)
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
                    put(MediaStore.Audio.Media.IS_PENDING, 1)
                }
                val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("Tidak bisa menyimpan file suara.")
                contentResolver.openOutputStream(uri).use { keluar ->
                    File(path).inputStream().use { masuk -> masuk.copyTo(keluar!!) }
                }
                values.clear()
                values.put(MediaStore.Audio.Media.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
                runOnUiThread { result.success(uri.toString()) }
            } catch (e: Exception) {
                runOnUiThread { result.error("gagal", e.message, null) }
            }
        }.start()
    }

    private fun putar(uri: String?) {
        contoh?.stop()
        val alamat = if (uri.isNullOrEmpty()) {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        } else {
            Uri.parse(uri)
        }
        contoh = try {
            RingtoneManager.getRingtone(this, alamat)?.also { it.play() }
        } catch (e: Exception) {
            null
        }
    }

    // Selama panggilan, layar aplikasi boleh tampil di atas layar kunci
    // dan menyalakan layar (seperti aplikasi telepon).
    private fun tampilDiAtasKunci(aktif: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(aktif)
            setTurnScreenOn(aktif)
        } else {
            val flag = android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            @Suppress("DEPRECATION")
            if (aktif) window.addFlags(flag) else window.clearFlags(flag)
        }
    }

    companion object {
        private const val KODE_PILIH = 7301
    }
}
