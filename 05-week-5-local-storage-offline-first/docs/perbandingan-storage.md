# Perbandingan storage

| Pilihan | Data dan query | Pemakaian praktikum | Pertimbangan |
|---|---|---|---|
| SharedPreferences | Key-value bool, angka, string, daftar string | Tema, waktu sesi sebelumnya | Tidak memiliki query SQL/transaksi tabel dan tidak cocok untuk data kritis. |
| SQLite melalui sqflite | Tabel, SQL, indeks, transaksi dan migrasi | Catatan, tombstone dan cache bacaan | Mendukung filter dirty, urutan updated_at, conditional ACK, penggantian cache atomik. UI diperbarui melalui Riverpod. |
| Drift | Lapisan SQLite dengan query bertipe dan stream | Alternatif jika perlu query reaktif lebih luas | Pola deklaratif lazim memakai generated code; praktikum memilih SQL langsung sesuai ketentuan sqflite. |
| File JSON | Serialisasi objek ke file | Ekspor/backup sederhana | Locking, mutasi per baris, query dan penulisan atomik perlu dibuat sendiri. |

Keputusan final: SharedPreferences untuk dark_mode dan last_opened_at, SQLite untuk notes dan cached_posts, Riverpod untuk state/injeksi dependency. API SharedPreferences legacy dipertahankan dari project awal dengan satu isolate/engine; dokumentasi kini menganjurkan Async/WithCache untuk penggunaan baru. Preferensi yang disimpan bukan data kritis.

Sumber resmi diperiksa 5 Oktober 2026: [SharedPreferences](https://pub.dev/packages/shared_preferences), [sqflite](https://pub.dev/packages/sqflite), [Drift](https://drift.simonbinder.eu/), [Flutter file persistence](https://docs.flutter.dev/cookbook/persistence/reading-writing-files).
