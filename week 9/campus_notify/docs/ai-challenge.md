# AI Challenge dan verifikasi

Dokumen ini mencatat prompt, draf awal AI, perbaikan manual, dan keputusan
teknis. Status tiap butir merujuk bukti yang bisa diperiksa, bukan klaim.

## Prompt yang dipakai

```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## Draf awal AI dan yang ditolak

Draf pertama mengikuti codelab hampir apa adanya. Enam hal diperbaiki sebelum
dipakai, semuanya karena draf itu lolos dari inspeksi sekilas tetapi rusak saat
dipakai.

| Temuan pada draf | Kenapa ditolak | Perbaikan |
| --- | --- | --- |
| Klik banner foreground hanya mengisi `pendingDeepLink`, tidak menavigasi | Pengguna mengklik notifikasi dan tidak terjadi apa pun sampai aplikasi dijalankan ulang. Ini bug yang tidak terlihat dari kode. | `onDidReceiveNotificationResponse` langsung memanggil `onOpen(routeFromMessage(...))` |
| `POST /devices` dibungkus `try/catch` kosong | Token gagal terkirim tetapi aplikasi tampak sehat. Backend menyimpan token basi tanpa ada yang tahu. | Kegagalan masuk ke `PushStatus.backendNote` dan tampil di layar Debug |
| Base URL `https://example-campus-api.test` ditulis di kode | Endpoint backend tidak bisa diganti tanpa mengubah Dart | `String.fromEnvironment('API_BASE_URL')` |
| `message.data['route']` dipakai langsung sebagai rute | Payload dari luar bisa membuka rute apa pun, termasuk URL eksternal | `routeFromMessage` memvalidasi ke `Routes.isKnown`, URL absolut ditolak |
| Payload FCM hanya berisi `route` | Tidak ada pembeda pesan, sehingga dua pengumuman bisa menumpuk atau saling menimpa | `data` membawa `route` + `id`, id notifikasi memakai `messageId` |
| Tidak ada cara melihat token di perangkat | Codelab mewajibkan bukti token terpotong dan token berubah setelah reinstall | Layar Debug push dengan prefix 12 karakter dan status sinkronisasi |

Hal yang dipertahankan dari draf karena sudah benar: background handler
top-level dengan `@pragma('vm:entry-point')`, pemakaian
`flutter_secure_storage` untuk kedua token, dan urutan tiga handler.

## Verifikasi checklist

| Butir | Status | Bukti |
| --- | --- | --- |
| Background handler top-level dengan `@pragma('vm:entry-point')` | Lulus | `lib/messaging/push_service.dart`, `firebaseMessagingBackgroundHandler`. Tidak memakai `BuildContext`, `Ref`, atau router |
| `onTokenRefresh` mengirim token baru ke backend, bukan hanya dicetak | Lulus secara kode, lihat catatan | `initFcmToken` memanggil `onToken` untuk token awal dan setiap refresh; callback di `main.dart` memanggil `deviceRegistrarProvider.register` |
| Foreground memakai local notification manual | Lulus | `listenForeground` -> `showForegroundNotification` -> `_local.show` dengan kanal `pengumuman` |
| Klik foreground masuk ke rute payload | Lulus | `onDidReceiveNotificationResponse` memanggil `onOpen`, `main.dart` meneruskan ke `router.go` |
| Klik background masuk ke rute payload | Lihat matriks | `onMessageOpenedApp` -> `routeFromMessage` -> `router.go` |
| Klik terminated masuk ke rute payload | Lihat matriks | `getInitialMessage` -> rute disimpan di `pendingRouteProvider` -> dibuka setelah login |
| Token tidak di-hardcode, tidak di-log penuh | Lulus | Token hanya di secure storage; layar Debug hanya menampilkan 12 karakter pertama; `debugPrint` tidak pernah memuat token |
| Payload asing tidak membuka layar kosong | Lulus | `test/message_route_test.dart`, 6 kasus termasuk URL eksternal dan `/login` |

Hasil uji perangkat ada di `docs/fcm-test-matrix.md`.

## Bagian yang berbeda antara Android 13+ dan iOS

| Aspek | Android 13+ | iOS |
| --- | --- | --- |
| Izin runtime | `POST_NOTIFICATIONS` diminta lewat `FirebaseMessaging.requestPermission`, didukung deklarasi di `AndroidManifest.xml` | Dialog APNs muncul dari `requestPermission`; butuh APNs key di Firebase Console dan capability Push di Xcode |
| Kanal notifikasi | `AndroidNotificationChannel` wajib dibuat agar prioritas `high` berlaku | Tidak ada konsep kanal |
| Izin ganda | `flutter_local_notifications` tidak meminta izin sendiri | `DarwinInitializationSettings` memakai `requestAlertPermission: false` dan kawan-kawan agar dialog tidak muncul dua kali |
| Banner foreground | Butuh `flutter_local_notifications` | `DarwinNotificationDetails(presentBanner: true)` |
| Token di emulator | Emulator tanpa Google Play Services mengembalikan token null | Simulator iOS tidak menerima push; butuh perangkat fisik |

## Bagian yang tidak boleh mengakses `BuildContext`

- `firebaseMessagingBackgroundHandler`: berjalan di isolate terpisah. Tidak ada
  `BuildContext`, `ProviderContainer`, router, atau `ScaffoldMessenger`. Tugasnya
  hanya mencatat pesan.
- `initLocalNotifications` dan `initFcmToken`: dipanggil sebelum `runApp`, jadi
  belum ada `BuildContext`. Semua callback memakai fungsi yang diterima sebagai
  parameter (`onOpen`, `onToken`), bukan context.
- Navigasi selalu terjadi setelah aplikasi punya router: dari
  `onDidReceiveNotificationResponse`, `onMessageOpenedApp`, atau listener status
  login di `main.dart`.

## Keputusan teknis

1. **`/splash` ditambahkan.** Tanpa ini, `authStateProvider` yang masih
   `AsyncLoading` terbaca `false`, sehingga pengguna dengan token valid sempat
   dilempar ke `/login`. Redirect sekarang menahan di `/splash` selama loading.
2. **Rute dari notifikasi ditahan sampai login.** Kalau notifikasi diklik saat
   sesi sudah mati, guard akan membuang tujuan. Rute disimpan di
   `pendingRouteProvider` dan dibuka setelah login berhasil.
3. **Id notifikasi memakai `messageId`, bukan `hashCode` pesan.** `hashCode`
   objek bisa bertabrakan antar pesan, sehingga pengumuman baru bisa menimpa
   pengumuman lain di tray.
4. **Topik untuk broadcast, token untuk pesan personal.** Topik
   `pengumuman-kampus` dipakai untuk pengumuman angkatan. Nilai, tagihan, atau
   pesan yang menyebut nama mahasiswa harus lewat token perangkat.
