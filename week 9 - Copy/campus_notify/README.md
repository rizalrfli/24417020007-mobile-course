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
- **Login lewat API**: `POST /auth/login` mengirim `email` + `password` dan
  menerima `access_token` + `refresh_token`. Token disimpan di secure storage,
  dan setiap 401 memicu satu kali refresh otomatis.
- **Kotak masuk notifikasi**: setiap notifikasi yang masuk (foreground,
  background, maupun terminated) disimpan ke daftar lokal yang bertahan setelah
  aplikasi ditutup. Membuka satu butir berarti membacanya: butir dihapus dari
  daftar dan angka badge ikut berkurang.
- **Badge angka**: ikon lonceng di AppBar menampilkan jumlah belum dibaca
  (disembunyikan saat nol, diringkas `99+`), dan angka yang sama dikirim ke
  badge ikon aplikasi lewat `app_badge_plus` bila launcher mendukung.
- **Suara notifikasi**: kanal `pengumuman_v2` dibuat dengan `playSound: true`
  dan `enableVibration: true`, sehingga notifikasi berbunyi tanpa perlu file
  audio tambahan.

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
├── data/
│   ├── api_client.dart                 # Dio + refresh sekali saat 401
│   ├── api_error_mapper.dart           # DioException -> Failure
│   ├── token_store.dart                # secure storage token
│   ├── auth/
│   │   ├── auth_dependencies.dart
│   │   ├── auth_diagnostics.dart
│   │   ├── auth_repository.dart         # HTTP/mock adapter
│   │   └── server_config.dart
│   ├── inbox/
│   │   ├── inbox_item_model.dart        # JSON/FCM mapping ke entity
│   │   ├── inbox_repository_impl.dart
│   │   └── inbox_store.dart
│   └── push/
│       ├── app_badge.dart
│       ├── device_registrar.dart       # POST /devices
│       ├── notification_payload.dart
│       └── push_debug_gateway.dart
│           # push_service.dart: permission, token, handler, topik
├── domain/
│   ├── api_errors.dart                # transport-independent Failure
│   ├── failures.dart
│   ├── auth/auth_repository.dart      # kontrak auth
│   ├── inbox/
│   │   ├── inbox_item.dart             # model notifikasi
│   │   ├── inbox_repository.dart       # kontrak inbox
│   │   └── usecases/
│   │       ├── add_inbox_item.dart
│   │       └── get_inbox.dart
│   └── push/message_route.dart         # validasi route murni
└── presentation/
    ├── main.dart                       # composition root, app bootstrap
    ├── routes.dart                     # path dan validasi rute
    ├── auth/
    │   ├── auth_controller.dart
    │   ├── home_page.dart
    │   └── login_page.dart
    ├── inbox/
    │   ├── announcement_page.dart
    │   ├── inbox_controller.dart
    │   └── inbox_page.dart
    └── push/
        ├── debug_page.dart
        └── push_controller.dart
test/
├── message_route_test.dart       # parsing route + pemetaan error
├── session_test.dart             # TokenStore, login API, refresh 401, retry
├── inbox_test.dart               # daftar notifikasi, batas, persistensi, badge
└── auth_push_test.dart           # payload, badge, aksi "dibaca = hilang"
docs/
├── ai-challenge.md               # prompt, output awal AI, perbaikan manual
├── refactoring.md                # tiga refactor wajib + alasan
├── fcm-test-matrix.md            # bukti uji tiga app state
├── fcm-send.md                   # cara kirim pesan uji lewat HTTP v1
├── tugas-notifikasi.md           # login API, kotak masuk, badge, suara
└── mock-api.md                   # backend tiruan untuk login lewat HTTP
tools/
├── send-test-push.ps1
└── mock-api/
    └── server.js                 # mock API tanpa dependency
screenshots/
```

Entry point berada di `lib/presentation/main.dart`, sehingga tingkat atas
`lib/` hanya berisi folder `data/`, `domain/`, dan `presentation/`.

## Bukti dependency rule

Verifikasi sumber pada 2 November 2026:

| Pemeriksaan | Hasil |
| --- | --- |
| Presentation tidak mengimpor Dio, storage, atau parsing JSON | Catatan: Riverpod composition `auth_controller.dart` memakai tipe Dio untuk provider; widget tidak membuat Dio dan delegasi konstruktor ada di data |
| Domain hanya bergantung pada Dart/domain | PASS, `rg` untuk Flutter, Dio, SharedPreferences, Firebase, dan JSON pada `lib/domain` kosong |
| Entity inbox tidak berisi serialisasi atau parsing payload | PASS, mapping berada di `data/inbox/inbox_item_model.dart` |
| Analisis dan test | PASS, `flutter analyze` bersih; seluruh test lulus |

Perintah pemeriksaan:

```bash
rg "package:flutter|package:dio|SharedPreferences|FlutterSecureStorage|jsonDecode|Firebase" lib/presentation
rg "package:flutter|package:dio|shared_preferences|package:firebase|jsonDecode|toJson|fromJson" lib/domain
flutter analyze
flutter test
```

Use case inbox memakai `InboxRepository` palsu di `test/inbox_test.dart` untuk
menguji hasil sukses dan failure tanpa SharedPreferences.

## Cara menjalankan

```bash
flutter pub get

# Login memakai API sungguhan. Alamat backend wajib diisi lewat --dart-define;
# tanpa itu aplikasi memakai alamat contoh dan login akan gagal dengan pesan
# "Gagal menghubungi server".
flutter run -t lib/presentation/main.dart --dart-define=API_BASE_URL=https://api.kampus.example

# Demo tanpa backend (login tiruan, bukan jalur default):
flutter run -t lib/presentation/main.dart --dart-define=USE_MOCK_AUTH=true

# Backend tiruan yang benar-benar lewat HTTP (lihat docs/mock-api.md):
node tools/mock-api/server.js
flutter run -t lib/presentation/main.dart --dart-define=API_BASE_URL=http://10.0.2.2:8080

flutter analyze
flutter test
```

`flutter test` menjalankan 75 unit/widget test. Uji integrasi ke mock API
dipisah karena butuh server hidup:

```bash
flutter test test/live_api_check.dart   # HttpAuthRepository vs server nyata
flutter test test/login_flow_check.dart # alur login penuh di layar
```

Alamat backend juga bisa diatur langsung dari layar login (ketuk panel
`Server: ...`), tanpa perlu menjalankan ulang dengan `--dart-define`.

### Kontrak API yang dipakai

| Endpoint | Body | Respons sukses |
| --- | --- | --- |
| `POST /auth/login` | `{"email": "...", "password": "..."}` | `{"access_token": "...", "refresh_token": "..."}` |
| `POST /auth/refresh` | `{"refresh_token": "..."}` | `{"access_token": "..."}` |
| `POST /devices` | `{"fcm_token": "...", "platform": "android"}` | 2xx |

`accessToken` / `refreshToken` (camelCase) dan `token` juga diterima, supaya
backend yang sedikit berbeda tidak memaksa kode Dart diubah. Bila backend tidak
menerbitkan refresh token, isi `refresh_token` dengan string kosong: interceptor
akan melewati proses refresh dan langsung meminta login ulang.

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
| `flutter test` | 75 test lulus (5 file) |
| `flutter build apk --debug` | Berhasil (`app-debug.apk`) |
| Uji integrasi mock API | 6 test lulus (`flutter test test/live_api_check.dart`) |
| Uji alur login penuh | 5 test lulus (`flutter test test/login_flow_check.dart`) |
| Uji tiga app state | Lihat `docs/fcm-test-matrix.md` |

Detail pengujian, termasuk yang belum bisa dibuktikan, ada di
`docs/fcm-test-matrix.md` dan `docs/ai-challenge.md`. Dokumen itu menandai
"belum diuji" secara eksplisit, bukan mengklaim lulus dari inspeksi kode.
