# Mock API untuk login

Backend tiruan supaya aplikasi bisa login lewat HTTP sungguhan tanpa menunggu
backend kampus. Satu berkas, tanpa dependency: cukup Node.js.

```
tools/mock-api/server.js
```

## Menjalankan

```bash
node tools/mock-api/server.js
# Mock API Campus Notify berjalan di http://0.0.0.0:8080
```

Variabel lingkungan yang bisa diubah:

| Variabel | Default | Guna |
| --- | --- | --- |
| `PORT` | `8080` | Port server |
| `HOST` | `0.0.0.0` | Alamat bind |
| `ACCESS_TTL` | `3600` | Umur access token (detik) |
| `REFRESH_TTL` | `86400` | Umur refresh token (detik) |
| `MOCK_API_SECRET` | nilai demo | Kunci tanda tangan token |

Akun demo:

| Email | Password |
| --- | --- |
| `mhs@polinema.ac.id` | `rahasia1` |
| `admin@polinema.ac.id` | `admin123` |

## Endpoint

| Method | Path | Auth | Keterangan |
| --- | --- | --- | --- |
| `GET` | `/health` | — | Cek server hidup, daftar akun, jumlah perangkat |
| `POST` | `/auth/login` | — | `{email, password}` → `{access_token, refresh_token, user}` |
| `POST` | `/auth/refresh` | — | `{refresh_token}` → access baru; token lama diputar (mati setelah dipakai) |
| `POST` | `/auth/logout` | Bearer | Mencabut access + refresh token |
| `POST` | `/devices` | Bearer | `{fcm_token, platform}` → mendaftarkan token FCM |
| `GET` | `/devices` | Bearer | Daftar token milik pengguna (hanya 12 karakter pertama) |
| `GET` | `/pengumuman/:id` | — | Isi pengumuman untuk halaman deep link |

Token ditandatangani HMAC-SHA256 dan punya masa berlaku, jadi kedaluwarsa bisa
diuji, bukan string acak yang selalu diterima. Setiap token juga dicatat di
daftar aktif, sehingga token yang sudah dicabut (logout atau refresh yang sudah
diputar) langsung ditolak walau tanda tangannya masih sah.

## Menghubungkan aplikasi

Cara termudah: **atur langsung dari layar login**. Ketuk panel `Server: ...` di
atas kolom email, isi alamat, lalu tekan **Simpan**. Alamat tersimpan di
perangkat, jadi cukup sekali dan tidak perlu menjalankan ulang dengan flag.

Kalau alamat masih alamat contoh (`example-campus-api.test`), panel otomatis
terbuka dan diberi peringatan merah, karena login tidak akan pernah berhasil.

Alamat yang perlu diisi:

| Situasi | Alamat |
| --- | --- |
| Emulator Android, backend di laptop | `http://10.0.2.2:8080` |
| HP fisik, backend di laptop (WiFi sama) | `http://192.168.1.5:8080` (IP laptop) |
| Backend di sandbox ini | `https://8080-<nama>.instabox.tech` |

Cara lama (masih didukung) — mengisi lewat flag saat menjalankan aplikasi:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Nilai dari flag hanya menjadi **default awal**; alamat yang disimpan lewat layar
login menang atasnya. Tombol **Reset** mengembalikan ke nilai flag.

### Kalau memakai HTTP biasa (bukan HTTPS)

Android 9+ memblokir koneksi tanpa enkripsi. Untuk build **debug**, izin ini
sudah aktif lewat `android/app/src/debug/AndroidManifest.xml`
(`usesCleartextTraffic="true"`), jadi `http://10.0.2.2:8080` langsung jalan
tanpa mengubah apa pun. Build **release** tetap menolak cleartext.

Kalau tetap gagal, tekan **Tes koneksi ke server** di layar login: hasilnya
menyebut URL yang dipakai dan penyebabnya.

## Diagnosa saat login gagal

Layar login menampilkan dua hal yang membuat masalah langsung terlihat:

1. Panel `Server: <url>` di atas kolom email. Ketuk untuk membuka dan
   **mengubah alamat tanpa rebuild**. Kalau isinya
   `https://example-campus-api.test`, berarti alamat belum pernah diatur.
2. Tombol **Tes koneksi ke server** yang menembak `GET /health` dan melaporkan
   hasilnya: terjangkau beserta waktunya, atau penyebab kegagalan yang spesifik
   (alamat salah, port tertutup, firewall, sertifikat, path 404).

| Gejala di layar | Arti | Perbaikan |
| --- | --- | --- |
| Peringatan merah "alamat contoh belum diganti" | Alamat belum diatur | Ketuk panel Server, isi alamat, Simpan |
| "Tidak bisa terhubung" + alamat `10.0.2.2` | Dijalankan di HP fisik | Ganti ke IP laptop di WiFi yang sama |
| "Tidak bisa terhubung" + `localhost` | Emulator tidak mengenal localhost laptop | Ganti ke `10.0.2.2` |
| "menjawab 404" | Alamat benar, path salah | Isi alamat tanpa `/auth/login` di belakangnya |
| "menolak kredensial (kode 401)" | Server terjangkau, akun salah | Cek email/password di tabel akun demo |
| "tidak menjawab dalam batas waktu" | Diblokir firewall | Buka port atau matikan firewall sementara |

## Uji cepat dengan curl

```bash
curl -X POST http://127.0.0.1:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mhs@polinema.ac.id","password":"rahasia1"}'
```

## Uji integrasi dari Dart

`test/live_api_check.dart` memanggil mock API memakai `HttpAuthRepository`
aplikasi, bukan curl. Berkas ini sengaja tidak berakhiran `_test.dart` supaya
tidak ikut `flutter test` biasa (butuh server hidup).

```bash
node tools/mock-api/server.js &
flutter test test/live_api_check.dart
```

Yang diperiksa: login berhasil, password salah ditolak dengan pesan yang tepat,
refresh menghasilkan access baru, `POST /devices` memakai Bearer token,
`/devices` tanpa token ditolak 401, dan server mati menghasilkan pesan koneksi.

Catatan penting: `flutter_test` memasang `HttpOverrides` yang membalas HTTP 400
untuk semua request. Tanpa `HttpOverrides.global = null` di `setUpAll`, test
integrasi akan terlihat lulus padahal tidak pernah menghubungi server.

## Batasan

- Data disimpan di memori. Server di-restart = token perangkat dan sesi hilang.
- Password dibandingkan sebagai teks biasa dan disimpan di kode. Ini alat demo,
  bukan contoh implementasi autentikasi produksi.
- Tidak ada rate limit, HTTPS, maupun penyimpanan pengumuman.
