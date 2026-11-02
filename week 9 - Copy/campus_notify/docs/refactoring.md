# Refactoring Challenge

Tiga refactor wajib dari codelab, beserta alasan teknisnya.

## 1. Semua string rute di satu tempat

Sebelum: `/login`, `/`, dan `/pengumuman/:id` ditulis sebagai literal di
`main.dart`, `home_page.dart`, dan `announcement_page.dart`. Deep link FCM juga
memakai literal yang sama sekali berbeda, jadi rute bisa berubah di satu tempat
tanpa yang lain.

Sesudah: `lib/presentation/routes.dart` memegang semua path.

```dart
Routes.home                      // '/'
Routes.login                     // '/login'
Routes.announcement('3')         // '/pengumuman/3'
Routes.announcementPattern       // '/pengumuman/:id'
Routes.announcementId('/pengumuman/3')  // '3'
Routes.isKnown('/admin')         // false
```

Router, tombol UI, dan handler notifikasi sekarang memakai konstanta yang sama.
`Routes.isKnown` dipakai sebagai filter sebelum navigasi, sehingga payload yang
menunjuk rute tidak terdaftar tidak membuka layar kosong.

`/debug` sengaja tidak dimasukkan ke `Routes` karena bukan target deep link.
Konstantanya ada di `lib/presentation/push/push_controller.dart` sebagai `debugRoute`.

## 2. Parsing `RemoteMessage` dipisah jadi fungsi murni

`lib/domain/push/message_route.dart`:

```dart
String routeFromMessage(Map<String, dynamic> data)
```

Fungsi ini tidak menyentuh Firebase, `BuildContext`, atau platform channel,
sehingga bisa diuji langsung di `flutter test`. Aturan yang dipegang:

- payload kosong atau bukan String -> `/`
- tanpa slash depan -> ditambah `/`
- URL absolut atau `//host` -> ditolak, kembali ke `/`
- rute yang tidak terdaftar di router -> kembali ke `/`

Alasan menolak URL absolut: `data` datang dari backend atau console, jadi
nilainya tidak boleh dipakai apa adanya untuk navigasi. Tanpa filter, payload
`https://...` bisa dipakai membuka halaman di luar aplikasi.

## 3. Pemetaan `DioException` ke pesan ramah pengguna

`lib/domain/api_errors.dart` mengubah exception menjadi `ApiFailure` berisi
`message` dan `isRetryable`. UI hanya menerima teks, bukan exception mentah.

| Kondisi | Pesan | Bisa diulang |
| --- | --- | --- |
| timeout | Koneksi lambat. Coba lagi sebentar. | ya |
| connection error | Tidak ada koneksi internet. Periksa jaringan Anda. | ya |
| 401 | Sesi berakhir. Silakan masuk kembali. | tidak |
| 403 | Akun ini tidak punya akses ke data tersebut. | tidak |
| 404 | Data yang diminta tidak ditemukan. | tidak |
| 5xx | Server kampus sedang bermasalah. Coba lagi nanti. | ya |

`HttpDeviceRegistrar` memakai pemetaan ini saat `POST /devices` gagal, lalu
layar Debug menampilkan pesan hasilnya. Dengan begitu kegagalan backend terlihat
sebagai kalimat, bukan `DioException [bad response]: ...`.

## Tambahan di luar tiga refactor wajib

- **Endpoint tidak di-hardcode.** `API_BASE_URL` dibaca dari
  `String.fromEnvironment`, jadi alamat backend diganti lewat `--dart-define`
  tanpa menyentuh kode.
- **Refresh token tidak disimpan ulang setelah refresh.** Interceptor menulis
  `save(access: renewed, refresh: refresh)`, mempertahankan refresh token lama.
  Kalau server merotasi refresh token, bagian ini yang harus diubah.
- **Kegagalan registrasi token tidak lagi ditelan diam-diam.** Versi awal
  membungkus `POST /devices` dengan `try/catch` kosong, sehingga token basi
  tidak pernah terlihat. Sekarang hasilnya masuk ke status di layar Debug.
- **Rute tertunda setelah login.** Klik notifikasi saat belum login disimpan di
  `pendingRouteProvider`, lalu dibuka setelah status login menjadi true.
