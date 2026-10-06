# Tugasku

Aplikasi pengingat tugas dan deadline (Flutter + Firebase).

**Tahap 1 (sudah ada):** halaman selamat datang, login Google, isi profil
(nama lengkap, sebutan, sekolah, kelas, bio) yang disimpan di Firestore,
Beranda, dan navigasi bawah Beranda / Chat / Profil.

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
  screens/
    auth_gate.dart           belum login → Selamat datang, profil kosong → isi profil, selain itu → Beranda
    welcome_screen.dart
    profile_form_screen.dart isi/edit profil
    home_shell.dart          navigasi bawah
    beranda_screen.dart
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
