# Campus Notification App

Aplikasi Flutter untuk menerima pengumuman kampus lewat Firebase Cloud
Messaging. Dibuat untuk codelab Minggu 6 (Authentication, Security & FCM):
<https://jti-polinema.github.io/flutter-codelab/06-minggu-6-authentication-security-fcm/index.html>.

## Tujuan

Menerapkan alur autentikasi berbasis token dengan penyimpanan aman, refresh
otomatis saat 401, serta FCM dengan deep link ke `/pengumuman/:id` pada tiga
app state (foreground, background, terminated).

## Fitur utama

- Guard route: pengguna yang belum login selalu diarahkan ke `/login`. Selama
  token masih dibaca, router menahan pengguna di `/splash` agar form login tidak
  berkedip untuk sesi yang masih valid.
- Access dan refresh token hanya disimpan lewat `TokenStore` di
  `flutter_secure_storage` (Keystore/Keychain), tidak pernah di SharedPreferences.
- Dio interceptor memperbarui access token satu kali saat 401 lalu mengulang
  request. Bila refresh gagal, token dihapus dan pengguna dipaksa login ulang.
- FCM: izin notifikasi, `getToken`, `onTokenRefresh` yang benar-benar mengirim
  token baru ke `POST /devices`, serta langganan topik `pengumuman-kampus`.
- Payload gabungan `notification + data`. Klik banner membuka `/pengumuman/:id`
  pada foreground (`flutter_local_notifications`), background
  (`onMessageOpenedApp`), dan terminated (`getInitialMessage`).
- Layar **Debug push**: status izin, token terpotong 12 karakter, token yang
  sudah terkirim ke backend, topik aktif, deep link terakhir, dan log peristiwa.
  Ada tombol banner uji, kirim ulang token, dan subscribe/unsubscribe topik.
- Rute tertunda: bila notifikasi diklik saat pengguna belum login, tujuan
  disimpan lalu dibuka setelah login berhasil.

## Stack

- Flutter 3.41 / Dart 3.11
- `flutter_riverpod` 2.6 (state, `NotifierProvider`)
- `go_router` 17 (routing, guard, deep link)
- `dio` 5 (HTTP client, interceptor refresh)
- `flutter_secure_storage` 11 (token)
- `firebase_core`, `firebase_messaging`, `flutter_local_notifications` (FCM)

## Struktur folder

```
lib/
├── main.dart                     # bootstrap FCM, router, guard, rute tertunda
├── routes.dart                   # konstanta rute + validasi id pengumuman
├── data/
│   ├── auth_repository.dart      # mock login + refresh (titik ganti Firebase Auth)
│   ├── token_store.dart          # satu-satunya pintu token
│   ├── api_client.dart           # Dio + refresh sekali saat 401
│   ├── api_errors.dart           # DioException -> pesan siap tampil
│   └── device_registrar.dart     # POST /devices
├── providers/
│   ├── auth_provider.dart        # sesi login + provider Dio
│   └── push_provider.dart        # status push untuk layar debug
├── messaging/
│   ├── push_service.dart         # permission, token, tiga handler, topik
│   └── message_route.dart        # RemoteMessage.data -> route (fungsi murni)
└── pages/
    ├── login_page.dart
    ├── home_page.dart
    ├── announcement_page.dart
    └── debug_page.dart
test/
├── message_route_test.dart       # parsing route + pemetaan error
├── session_test.dart             # TokenStore, refresh 401, retry
└── auth_push_test.dart           # test dasar codelab
docs/
├── ai-challenge.md               # prompt, output awal AI, perbaikan manual
├── refactoring.md                # tiga refactor wajib + alasan
├── fcm-test-matrix.md            # bukti uji tiga app state
└── fcm-send.md                   # cara kirim pesan uji lewat HTTP v1
tools/
└── send-test-push.ps1
screenshots/
```

## Cara menjalankan

```bash
flutter pub get

# Backend /devices. Tanpa --dart-define, aplikasi memakai alamat contoh dan
# registrasi token akan gagal (kegagalan itu terlihat di layar Debug).
flutter run --dart-define=API_BASE_URL=https://api.kampus.example

flutter analyze
flutter test
```

FCM butuh `android/app/google-services.json` dengan package
`com.example.campus_notify`. Plugin `com.google.gms.google-services` sudah aktif
di `android/settings.gradle.kts` dan `android/app/build.gradle.kts`.

Android 13+ meminta izin `POST_NOTIFICATIONS` saat runtime; manifest sudah
mendeklarasikannya. iOS butuh APNs key di Firebase Console dan capability Push
di Xcode.

## Hasil yang dicapai

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter analyze` | 0 issue |
| `flutter test` | 23 test lulus (3 file) |
| Uji tiga app state | Lihat `docs/fcm-test-matrix.md` |

Detail pengujian, termasuk yang belum bisa dibuktikan, ada di
`docs/fcm-test-matrix.md` dan `docs/ai-challenge.md`. Dokumen itu menandai
"belum diuji" secara eksplisit, bukan mengklaim lulus dari inspeksi kode.
