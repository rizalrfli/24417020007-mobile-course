# Minggu 5: Local Storage dan Offline-First

Tujuan praktikum: catatan tetap bisa dibaca, ditambah, diubah dan dihapus tanpa jaringan. Dikembangkan dari project week5_offline_notes pada repository portfolio yang sama.

## Fitur utama

- Tema terang/gelap dan waktu sesi sebelumnya melalui SharedPreferences, dicatat sejak aplikasi dibuka.
- CRUD SQLite melalui repository lokal dan Riverpod. Urutan updated_at terbaru.
- Dirty flag persisten, tombstone untuk penghapusan, sync HTTP dan ACK yang menjaga edit baru tetap dirty.
- Bacaan JSONPlaceholder cache-first melalui tabel SQLite cached_posts, refresh background dan fallback saat jaringan gagal.
- Validasi judul, konfirmasi hapus, loading/error/kosong dan feedback sync.

## Stack

Flutter 3.41.9, Dart 3.11.5, Riverpod 3.3.2, SharedPreferences 2.5.5, sqflite 2.4.2+1, Dio, GoRouter, Python 3 untuk server demo. Versi resolusi ada di pubspec.lock. Target yang diverifikasi adalah Android; test SQLite desktop memakai FFI. Template platform lain belum diverifikasi.

## Cara menjalankan

```powershell
cd 05-week-5-local-storage-offline-first
flutter pub get
python tools/demo_server.py
```

Di terminal kedua dengan Android Emulator aktif:

```powershell
flutter run -d emulator-5554
```

Server port 8080 menyimpan data ke build/demo-server.sqlite. Emulator memakai http://10.0.2.2:8080. Perangkat fisik di LAN memakai IP komputer:

```powershell
flutter run --dart-define=NOTES_API_URL=http://192.168.1.10:8080
```

Ganti IP sesuai komputer. CRUD tidak memerlukan server. Bacaan offline harus pernah dimuat online. Server demo ini hanya satu perangkat/namespace dan tanpa autentikasi. HTTP cleartext diizinkan untuk demo LAN; produksi memerlukan HTTPS, UUID dan autentikasi.

## Hasil dan testing

```powershell
flutter analyze
flutter test --reporter expanded
flutter build apk --debug
```

19 test unit/provider/repository/widget lulus, mencakup model, repository palsu, preferensi, cache-first, CRUD SQLite, tombstone, urutan pecahan detik, konflik, partial failure, edit selama upload, keyboard, ukuran ponsel dan kontras badge pada kedua tema. Log final dan bukti emulator ada di [docs/uji-offline.md](docs/uji-offline.md). Screenshot memiliki sidecar status airplane_mode_on.

Satu skenario integrasi emulator juga lulus, dengan enam screenshot mode pesawat/cache/tema/sync. flutter analyze: No issues found.

## Aturan konflik

Last-write-wins membandingkan updated_at UTC. Timestamp sama memilih lokal yang dikirim. Tombstone mengikuti aturan yang sama. Server commit versi pemenang sebelum ACK; lokal membersihkan dirty hanya jika snapshot belum berubah. Keterbatasan jam perangkat dan namespace dijelaskan di [arsitektur dan konflik](docs/arsitektur-dan-konflik.md).

## Verifikasi AI

Ditolak: sync simulasi yang membersihkan dirty tanpa upload, serta klaim dokumen lama bahwa cache memakai SharedPreferences. Diperbaiki pula antrean hapus, pencatatan waktu pembukaan, conditional ACK dan format UTC. [Prompt dan keputusan](docs/ai-challenge.md), [tabel storage](docs/perbandingan-storage.md), dan [jawaban refleksi](docs/refleksi.md) memuat alasan serta sumber resmi.

## Struktur

lib/ berisi model, SQLite, repository, provider dan UI; test/ berisi test; docs/ berisi dokumentasi; screenshots/ berisi bukti. integration_test/ dan test_driver/ menguji alur emulator. tools/ berisi server demo.
