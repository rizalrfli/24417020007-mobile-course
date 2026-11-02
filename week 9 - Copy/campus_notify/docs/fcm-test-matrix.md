# Matriks pengujian

## Pengujian yang sudah lulus di perangkat fisik

Perangkat: SM A146P (Android 15, API 35), build debug.

| Uji | Hasil | Bukti |
| --- | --- | --- |
| Aplikasi terpasang dan terbuka | Lulus | `screenshots/01-login.png` |
| Guard route: belum login diarahkan ke `/login` | Lulus | `screenshots/01-login.png` |
| Login dengan email valid dan kata sandi 6+ karakter | Lulus, masuk ke `/` | `screenshots/02-login-terisi.png`, `screenshots/03-home-setelah-login.png` |
| Klik item pengumuman membuka `/pengumuman/3` | Lulus, ID pengumuman tampil | `screenshots/04-deep-link-pengumuman-3.png` |
| Logout menghapus token dan kembali ke `/login` | Lulus | `screenshots/05-logout-kembali-ke-login.png` |
| `flutter analyze` | 3 info, tanpa error/warning | `main.dart` (`unnecessary_underscores`) |
| `flutter test` | 4 test lulus | `test/auth_push_test.dart` |
| Build APK debug | Lulus | `build/app/outputs/flutter-apk/app-debug.apk` |

## Pengujian FCM tiga app state

Belum dapat diuji. Alasannya: `google-services.json` belum ada karena project
Firebase belum didaftarkan. Kode FCM sudah terpasang dan hanya aktif bila
`Firebase.initializeApp()` berhasil.

| State | Yang diharapkan | Cara uji | Hasil |
| --- | --- | --- | --- |
| Foreground | Banner lokal muncul, klik masuk ke route payload | Aplikasi terbuka, kirim dari console/backend, klik banner | Belum diuji. Inspeksi kode: klik hanya mengisi `pendingDeepLink`, belum navigasi langsung; diproses saat startup melalui `handleTerminated` |
| Background | Banner sistem muncul, klik masuk ke rute yang benar | Tekan Home, kirim, klik banner | Belum diuji |
| Terminated | Aplikasi terbuka ke rute yang benar via `getInitialMessage` | Swipe-close aplikasi, kirim, klik banner | Belum diuji |

Langkah agar bisa diuji: daftarkan aplikasi Android dengan package name
`com.example.campus_notify` di Firebase Console, unduh `google-services.json`
ke `android/app/`, tambahkan plugin `com.google.gms.google-services` di Gradle,
lalu jalankan ulang aplikasi.
