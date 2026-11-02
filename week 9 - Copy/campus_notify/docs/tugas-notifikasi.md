# Tugas: login API, kotak masuk notifikasi, badge angka, suara

Dokumen ini mencatat keempat butir tugas, cara kerjanya, dan bukti yang bisa
diperiksa. Butir yang belum bisa dibuktikan ditandai apa adanya.

## 1. Login dari API

**Sebelum:** `AuthRepository.login` hanya `Future.delayed` lalu mengembalikan
token `mock-access-for-<email>`. Tidak ada HTTP sama sekali, sehingga kata sandi
apa pun yang panjangnya 6 karakter diterima.

**Sekarang:** `HttpAuthRepository` di
`lib/domain/auth/auth_repository.dart`.

| Aspek | Perilaku |
| --- | --- |
| Endpoint | `POST {API_BASE_URL}/auth/login` dengan body `email`, `password` |
| Respons | `access_token` + `refresh_token` (camelCase dan `token` juga diterima) |
| Penyimpanan | Kedua token masuk `flutter_secure_storage` lewat `TokenStore` |
| 401 saat login | Diterjemahkan menjadi "Email atau kata sandi salah.", bukan "sesi berakhir" |
| Server mati | Diterjemahkan lewat `mapDioException` menjadi pesan yang bisa ditampilkan |
| Refresh | `POST /auth/refresh`, dipicu otomatis sekali saat request lain kena 401 |

`AuthRepository` sekarang abstrak, dengan dua implementasi:

- `HttpAuthRepository` — jalur default.
- `MockAuthRepository` — hanya aktif dengan `--dart-define=USE_MOCK_AUTH=true`,
  supaya build rilis tidak diam-diam menerima kredensial palsu.

Dio untuk login (`authDioProvider`) sengaja terpisah dari `apiClientProvider`.
Kalau memakai Dio yang sama, percobaan login yang gagal akan memicu interceptor
refresh, dan pesan "kata sandi salah" berubah menjadi "sesi berakhir".

## 2. Notifikasi masuk daftar, dibaca lalu hilang

| Bagian | Berkas |
| --- | --- |
| Model | `lib/domain/inbox/inbox_item.dart` |
| Kontrak + operasi | `lib/domain/inbox/inbox_repository.dart` |
| Penyimpanan | `lib/data/inbox/inbox_store.dart` (`shared_preferences`) |
| State | `lib/presentation/inbox/inbox_controller.dart` |
| Tampilan | `lib/presentation/inbox/inbox_page.dart` |

Alur:

1. Pesan diterima → `InboxItemModel.fromMessage` membentuk butir (id, judul, isi,
   rute yang sudah divalidasi, waktu).
2. `AddInboxItem` dan `InboxRepositoryImpl` menyisipkan di paling atas, mengganti butir ber-id sama,
   dan memotong daftar ke 50 butir.
3. Butir tampil di `/notifikasi` beserta waktu relatif (`09:30` hari ini,
   `01/11 09:30` selain itu).
4. Mengetuk butir = membacanya: butir dihapus dari daftar, badge berkurang, lalu
   pengumuman dibuka.

Tiga jalur masuk pesan ditangani:

| App state | Yang menyimpan |
| --- | --- |
| Foreground | `listenForeground` → `inboxProvider.add` |
| Background | `firebaseMessagingBackgroundHandler` → `InboxRepositoryImpl.add` (isolate terpisah, tanpa Riverpod) |
| Terminated + klik banner | `initialItemFromNotification` → butir langsung ditandai dibaca |

Id yang sama tidak digandakan, jadi pesan yang dikirim ulang tidak membuat badge
naik dua kali. Saat logout daftar dikosongkan agar pengumuman sesi sebelumnya
tidak terbaca oleh pengguna lain di perangkat yang sama.

## 3. Angka di ikon

| Tempat | Implementasi |
| --- | --- |
| Lonceng di AppBar | `NotificationBell` (`lib/presentation/inbox/inbox_page.dart`), `Badge` Material 3 |
| Ikon aplikasi | `LauncherBadgeSink` (`lib/data/push/app_badge.dart`) lewat `app_badge_plus` |

Angka berasal dari satu sumber: `unreadCountProvider`, yang diturunkan dari
`inboxProvider`. Badge tidak pernah dihitung terpisah, jadi tidak mungkin
menampilkan angka berbeda dari isi daftar. Nol berarti badge disembunyikan, dan
angka di atas 99 diringkas menjadi `99+`.

Badge ikon aplikasi bergantung pada launcher. Bila launcher tidak mendukung
(umum pada launcher stok AOSP), kegagalan diabaikan dan lonceng di dalam
aplikasi tetap akurat.

## 4. Suara notifikasi

| Aspek | Nilai |
| --- | --- |
| Id kanal | `pengumuman_v2` |
| `playSound` | `true` |
| `enableVibration` | `true` |
| Suara | Bawaan sistem (tanpa file `res/raw`) |
| iOS | `DarwinNotificationDetails(presentSound: true)` |

Id kanal dinaikkan dari `pengumuman` ke `pengumuman_v2` karena Android menyimpan
setelan kanal selamanya: mengubah `sound` pada id lama tidak berpengaruh pada
perangkat yang sudah memasang aplikasi.

Untuk notifikasi yang datang saat aplikasi **tidak** di foreground, banner
digambar sistem Android, bukan `flutter_local_notifications`. Karena itu payload
FCM harus menyebut `android.notification.channel_id = "pengumuman_v2"`; tanpa
field itu FCM memakai kanal cadangannya sendiri yang bisa senyap. Contoh payload
lengkap ada di `docs/fcm-send.md` dan `tools/send-test-push.ps1`.

## Bukti

```text
flutter analyze  -> No issues found!
flutter test     -> 55 test lulus (4 file)
```

Test yang menutup keempat butir:

| Butir | Test |
| --- | --- |
| Login API | `test/session_test.dart` → grup `HttpAuthRepository` (7 kasus) |
| Daftar + dibaca hilang | `test/inbox_test.dart` → grup `InboxRepository`, `InboxNotifier + badge` |
| Angka badge | `test/auth_push_test.dart` → grup `NotificationBell` (3 kasus) |
| Suara | Tidak ada test otomatis (butuh perangkat). Dibuktikan manual lewat banner uji di layar Debug |

Yang **belum** dibuktikan di mesin ini:

- Build APK — Android SDK tidak tersedia, jadi aplikasi belum pernah dijalankan
  di perangkat/emulator dari sesi ini.
- Bunyi notifikasi dan badge launcher — keduanya hanya bisa diamati di perangkat
  sungguhan.
- Login terhadap backend kampus — URL dan bentuk respons backend belum
  diketahui, jadi kontrak di atas adalah asumsi yang perlu dicocokkan.
