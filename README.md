# Hanary

Aplikasi pengingat tugas dan deadline (Flutter + Firebase).

**Tahap 1 (sudah ada):** halaman selamat datang, login Google, isi profil
(nama lengkap, sebutan, sekolah, kelas, bio) yang disimpan di Firestore,
Beranda, dan navigasi bawah Beranda / Chat / Profil.

**Tahap 2 (sudah ada):** catat tugas (judul, mapel, catatan), deadline tanggal + jam,
status Belum / Sedang dikerjakan / Selesai, lampiran foto/gambar/file, dan notifikasi
pengingat tiap hari jam 12.00 & 18.00 dan menjelang deadline (1 jam, 30, 15, 5 menit), plus pemberitahuan jika deadline terlewat. Daftar tugas tampil di Beranda.

**Tahap 3 (chat):** tambah teman (cari sebutan/email, kirim permintaan, terima/tolak),
chat pribadi, grup (buat, tambah anggota, keluar), dengan enkripsi end-to-end.

## Struktur

```
lib/
  main.dart                  inisialisasi Firebase
  app.dart                   tema dan halaman awal
  firebase_options.dart      SEMENTARA, diganti oleh `flutterfire configure`
  models/app_user.dart       data profil (koleksi `users/{uid}`)
  services/auth_service.dart login/logout Google
  services/user_repository.dart  baca/simpan profil
  models/tugas.dart          data tugas (`users/{uid}/tugas/{id}`)
  services/tugas_repository.dart     baca/simpan tugas
  services/notifikasi_service.dart   notifikasi lokal terjadwal (jadwalnya di jadwal_pengingat.dart)
  services/lampiran_service.dart     lampiran: salinan di HP + Google Drive
  services/drive_service.dart        upload/download Google Drive
  screens/
    auth_gate.dart           belum login → Selamat datang, profil kosong → isi profil, selain itu → Beranda
    welcome_screen.dart
    profile_form_screen.dart isi/edit profil
    home_shell.dart          navigasi bawah
    beranda_screen.dart      ringkasan + daftar tugas
    tugas_form_screen.dart   tambah/edit tugas
    chat_screen.dart         tab Chat: daftar obrolan dan teman
    chat/                    ruang chat, info grup, buat grup, cari teman
  services/chat_crypto.dart  enkripsi (X25519 + HKDF-SHA256 + AES-256-GCM)
  services/chat_keys.dart    kunci privat di penyimpanan aman HP, kunci publik di Firestore
  services/chat_repository.dart  ruang chat dan pesan
  services/friend_repository.dart  pertemanan
    profile_screen.dart
firestore.rules              aturan keamanan Firestore
```

## Langkah setup (sekali saja)

### 1. Siapkan alat
- Install Flutter: https://docs.flutter.dev/get-started/install
- Install Node.js, lalu Firebase CLI: `npm install -g firebase-tools`
- Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- Login: `firebase login`

### 2. Buat proyek Firebase
1. Buka https://console.firebase.google.com → **Add project**, beri nama mis. `tugasku`.
2. **Build → Authentication → Get started → Sign-in method → Google → Enable**, isi email dukungan, Save.
3. **Build → Firestore Database → Create database**, pilih lokasi `asia-southeast2 (Jakarta)`, mulai dalam *production mode*.
4. Di tab **Rules** Firestore, tempel isi file `firestore.rules`, lalu **Publish**.

### 3. Hubungkan aplikasi ke Firebase
Di folder proyek ini:
```
flutter pub get
flutterfire configure
```
Pilih proyek Firebase tadi dan platform **android** (dan **web** jika ingin).
Perintah ini membuat ulang `lib/firebase_options.dart` dan `android/app/google-services.json`.

### 4. Daftarkan SHA-1 (wajib agar login Google di Android jalan)
```
cd android
./gradlew signingReport
```
Salin nilai **SHA1** dari varian `debug`. Di Firebase Console → ⚙️ Project settings → aplikasi Android →
**Add fingerprint**, tempel SHA-1 tadi. Lalu jalankan lagi `flutterfire configure` agar
`google-services.json` ikut diperbarui.

> Nanti saat rilis ke Play Store, SHA-1 dari kunci rilis dan dari Play App Signing juga perlu ditambahkan.

### 5. Jalankan
```
flutter run
```

### (Opsional) iOS
Butuh Mac + Xcode. Setelah `flutterfire configure` untuk iOS, buka `ios/Runner/Info.plist` dan
tambahkan `CFBundleURLTypes` berisi `REVERSED_CLIENT_ID` dari `GoogleService-Info.plist`
(lihat dokumentasi paket `google_sign_in`).

## Data di Firestore

`users/{uid}`: `email`, `namaLengkap`, `sebutan`, `sebutanLower` (untuk pencarian teman nanti),
`sekolah`, `kelas`, `bio`, `fotoUrl`, `createdAt`, `updatedAt`.

`users/{uid}/tugas/{id}`: `judul`, `mapel`, `catatan`, `deadline` (Timestamp),
`status` (`belum` | `dikerjakan` | `selesai`), `lampiran` (daftar `{nama, berkas, ukuran, driveId}`),
`createdAt`, `updatedAt`.

Lampiran diunggah ke Google Drive milik pengguna (folder "Tugasku", izin `drive.file`
yang hanya bisa melihat file buatan aplikasi ini) dan disalin di HP. Firebase Storage
tidak dipakai karena butuh paket berbayar Blaze. Syarat: **Google Drive API** harus
diaktifkan untuk proyek Google Cloud `hanary-b3341`:
https://console.cloud.google.com/apis/library/drive.googleapis.com?project=hanary-b3341

`friendRequests/{dari}_{ke}`: `from`, `to`, `createdAt`.
`users/{uid}/teman/{uidTeman}`: `since`.
`publicKeys/{uid}`: `pub` (kunci publik X25519, base64).
`chats/{id}`: `type` (`pribadi`/`grup`), `name`, `admin`, `members`, `keys.{uid}` (kunci ruang
yang dibungkus untuk tiap anggota), `lastBox` (pesan terakhir, terenkripsi), `lastSender`, `updatedAt`.
Chat pribadi memakai id `p_{uidA}_{uidB}` (uid diurutkan).
`chats/{id}/messages/{msgId}`: `senderId`, `box` (isi pesan terenkripsi), `createdAt`.

## Enkripsi chat

- Tiap HP membuat pasangan kunci X25519. Kunci privat disimpan di penyimpanan aman HP
  (`flutter_secure_storage`) dan tidak pernah dikirim. Kunci publik ditaruh di `publicKeys/{uid}`.
- Tiap ruang chat punya kunci AES-256 acak. Kunci itu dibungkus untuk tiap anggota
  (ECDH X25519 dengan kunci sementara + HKDF-SHA256 + AES-GCM) dan disimpan di `chats/{id}.keys`.
- Isi pesan dienkripsi AES-256-GCM dengan kunci ruang (id chat sebagai data tambahan).
- Jika kunci publik anggota berubah (ganti HP/install ulang) atau anggota belum punya kunci,
  anggota lain yang membuka aplikasi otomatis membungkus ulang kunci ruang untuknya.

Batasan: server tetap tahu siapa chat dengan siapa, kapan, dan nama grup; kunci publik tidak
diverifikasi (tidak ada "kode keamanan"), jadi pemilik server secara teori bisa menyisipkan kunci palsu;
satu akun dipakai di satu HP; anggota yang keluar grup masih memegang kunci lama
(tapi aturan Firestore menolak dia membaca pesan baru).

Aturan Firestore diuji dengan Firebase Emulator (pertemanan, kunci publik, chat pribadi, pesan, grup).

`chats/{id}/messages/{msgId}.balas`: kutipan pesan yang dibalas (terenkripsi dengan kunci ruang).
`fcmTokens/{uid}`: `token` FCM HP pengguna (hanya pemiliknya; dibaca server notifikasi).
`panggilan/{id}`: `chatId`, `dari`, `video`, `grup`, `anggota`, `ikut`, `tolak`, `status`
(`berdering`/`berlangsung`/`selesai`); `panggilan/{id}/sinyal/{x}`: sinyal WebRTC antar dua peserta.
`panggilanMasuk/{uid}`: penanda ada yang menelepon (dipantau saat aplikasi terbuka).

## Notifikasi instan (gratis, tanpa kartu)

Firebase Cloud Functions butuh paket Blaze, jadi pengirim notifikasi memakai
**Cloudflare Workers** (paket gratis, 100.000 permintaan/hari) di `server/notif-worker`.
Setelah mengirim pesan atau memulai panggilan, HP pengirim memanggil `POST /kirim` dengan
ID token Firebase. Server memeriksa token dan keanggotaan chat, lalu mengirim pesan FCM
berisi data saja (`jenis`, `chatId`, `callId`). HP penerima membuka sendiri isi pesannya
(tetap end-to-end) dan menampilkan notifikasi.

Rahasia GitHub yang dibutuhkan (Settings → Secrets and variables → Actions):
`CLOUDFLARE_API_TOKEN` (template "Edit Cloudflare Workers"), `CLOUDFLARE_ACCOUNT_ID`, dan
`FIREBASE_SERVICE_ACCOUNT` (isi file JSON dari Firebase Console → Project settings →
Service accounts → Generate new private key). Workflow `deploy-notif.yml` memasang server;
`build-apk.yml` mengisi alamatnya ke APK (`--dart-define=NOTIF_URL=...`). Tanpa rahasia ini
aplikasi tetap jalan dengan pemeriksaan tiap ~15 menit.

## Panggilan suara/video

WebRTC (`flutter_webrtc`) langsung antar HP, terenkripsi DTLS-SRTP. Firestore hanya dipakai
untuk sinyal dan status. Server STUN gratis Google membantu HP saling menemukan; tanpa server
TURN, sebagian kecil jaringan (mis. Wi-Fi kantor/sekolah yang ketat) bisa gagal tersambung.
Grup memakai sambungan antar semua peserta (cocok untuk sekitar 2–6 orang).
