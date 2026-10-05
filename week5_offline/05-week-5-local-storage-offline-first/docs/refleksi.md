# Jawaban refleksi

## 1. Mengapa daftar catatan tidak disimpan di SharedPreferences?

SharedPreferences ditujukan untuk preferensi key-value kecil, seperti tema dan waktu pembukaan. Daftar catatan membutuhkan mutasi per baris, filter dirty, pengurutan updated_at, indeks, dan transaksi yang menjaga konsistensi. SQLite memenuhi kebutuhan itu.

Menyimpan JSON catatan di SharedPreferences secara teknis bisa dilakukan, tetapi setiap edit harus membaca dan menulis ulang seluruh daftar. Dua operasi bersamaan bisa saling menimpa, dirty flag dapat hilang, dan sinkronisasi berisiko membersihkan versi yang belum dikirim. Pengurutan/query menjadi tanggung jawab kode aplikasi. Plugin juga tidak menjamin data sudah tersimpan ke disk ketika operasi kembali, sehingga tidak sesuai untuk data kritis. Bukan berarti semua penyimpanan JSON langsung rusak; kontrak ketahanan dan konsistensi catatan menjadi sulit dipenuhi. [Dokumentasi SharedPreferences](https://pub.dev/packages/shared_preferences).

## 2. Kapan cache-first cukup dan kapan strategi lain diperlukan?

Cache-first cukup untuk data yang tetap berguna walaupun sedikit tertinggal: bacaan, materi praktikum, katalog statis, dan catatan lokal. Cache segera ditampilkan; refresh dapat dilakukan di belakang. Project ini menggunakan strategi tersebut untuk bacaan JSONPlaceholder.

Harga real-time, stok untuk transaksi, dan status pembayaran memerlukan data yang lebih segar. Network-first dapat dipakai dengan timeout dan fallback cache yang diberi waktu pembaruan serta label kedaluwarsa. Untuk transaksi harga/stok tetap perlu validasi server ketika dikonfirmasi. Data streaming mungkin membutuhkan WebSocket, invalidasi push, atau TTL singkat. Network-first saja tidak menjamin data selalu real-time. Pilihan bergantung pada seberapa lama data boleh tertinggal. [Panduan offline-first Flutter](https://docs.flutter.dev/app-architecture/design-patterns/offline-first).

## 3. Bagaimana dirty flag menjadi antrean tanpa memblokir UI? Kapan outbox perlu?

Mutasi segera disimpan ke SQLite dengan dirty=1, lalu provider memperbarui daftar dan badge. syncNotes membaca snapshot `WHERE dirty=1` dan mengirim HTTP secara async. UI tetap bisa menampilkan/mengedit catatan ketika jaringan menunggu. Setelah ACK, conditional UPDATE hanya membersihkan snapshot yang sama; perubahan baru tetap dirty. Timeout atau kegagalan mempertahankan antrean di disk. Tombstone menjaga penghapusan ikut terkirim.

Dirty flag menggabungkan beberapa edit pada satu catatan menjadi versi terakhir. Itu cukup jika server hanya membutuhkan keadaan terakhir. Tabel outbox diperlukan ketika setiap operasi harus dipertahankan beserta urutannya, misalnya pembayaran, audit, dependensi antar-entitas, retry per operasi, backoff, idempotency key, atau pekerjaan background yang perlu mengambil/menandai tugas secara atomik. Perubahan data dan penambahan outbox harus berada dalam transaksi yang sama. Async tidak menghilangkan biaya CPU: serialisasi/batch besar tetap perlu dibatasi atau dipindah ke isolate.

## 4. Rekomendasi AI mana yang ditolak, dan mengapa?

Tidak ada eksperimen rekomendasi AI terpisah yang direkayasa. Yang ditolak dalam audit bantuan AI adalah pendekatan pada project awal: menunggu simulasi lalu menjalankan `markAllSynced()`. Cara itu menyatakan sync berhasil tanpa pengiriman dan dapat menghapus dirty milik perubahan baru. Implementasi final menggunakan HTTP ACK persisten serta conditional UPDATE.

Klaim dokumentasi lama bahwa bacaan disimpan di SharedPreferences juga ditolak karena tidak cocok dengan kode yang menggunakan tabel `cached_posts` di SQLite. Screenshot sync simulasi tidak diterima sebagai bukti sync HTTP versi baru. Drift tidak dipilih sebagai implementasi final karena tugas meminta sqflite dan SQL langsung sudah memenuhi kebutuhan ini; bukan karena Drift dianggap salah. Temuan dan bukti test ada di [AI Challenge](ai-challenge.md).
