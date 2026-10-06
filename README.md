# Tugasku

Aplikasi pengingat tugas dan deadline (Flutter + Firebase).

**Tahap 1 (sudah ada):** halaman selamat datang, login Google, isi profil
(nama lengkap, sebutan, sekolah, kelas, bio) yang disimpan di Firestore,
Beranda, dan navigasi bawah Beranda / Chat / Profil.

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
    chat_screen.dart         placeholder (tahap 3)
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
