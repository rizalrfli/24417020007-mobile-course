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

**Emulator Android** — `10.0.2.2` adalah alias host dari dalam emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**HP fisik di WiFi yang sama** — pakai IP laptop, bukan `localhost`:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8080
```

**Lewat URL publik sandbox** (bila backend dijalankan di mesin ini):

```bash
flutter run --dart-define=API_BASE_URL=https://8080-<nama>.instabox.tech
```

### Kalau memakai HTTP biasa (bukan HTTPS)

Android 9+ memblokir koneksi tanpa enkripsi. Untuk build **debug**, izin ini
sudah aktif lewat `android/app/src/debug/AndroidManifest.xml`
(`usesCleartextTraffic="true"`), jadi `http://10.0.2.2:8080` langsung jalan
tanpa mengubah apa pun. Build **release** tetap menolak cleartext.

Kalau tetap gagal, tekan **Tes koneksi ke server** di layar login: hasilnya
menyebut URL yang dipakai dan penyebabnya.

## Diagnosa saat login gagal

Layar login menampilkan dua hal yang membuat masalah langsung terlihat:

1. Baris `Server: <url>` di bawah tombol. Kalau isinya
   `https://example-campus-api.test`, berarti `--dart-define=API_BASE_URL`
   tidak terbaca dan aplikasi memakai alamat placeholder.
2. Tombol **Tes koneksi ke server** yang menembak `GET /health` dan melaporkan
   hasilnya: terjangkau beserta waktunya, atau penyebab kegagalan yang spesifik
   (alamat salah, port tertutup, firewall, sertifikat, path 404).

| Gejala di layar | Arti | Perbaikan |
| --- | --- | --- |
| `Server: https://example-campus-api.test` | Flag dart-define tidak dipakai | Jalankan ulang `flutter run --dart-define=API_BASE_URL=...` |
| "Tidak bisa terhubung" + alamat `10.0.2.2` | Dijalankan di HP fisik | Ganti ke IP laptop di WiFi yang sama |
| "Tidak bisa terhubung" + `localhost` | Emulator tidak mengenal localhost laptop | Ganti ke `10.0.2.2` |
| "menjawab 404" | Alamat benar, path salah | Periksa `API_BASE_URL` (jangan ada `/auth/login` di belakangnya) |
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
