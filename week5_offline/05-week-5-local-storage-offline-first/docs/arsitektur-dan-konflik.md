# Arsitektur dan aturan konflik

## Data lokal

notes(id, title, body, updated_at, dirty, deleted) memakai id autoincrement. Timestamp UTC memiliki enam digit pecahan agar perbandingan string SQLite konsisten. Daftar memakai updated_at DESC, id DESC dan menyembunyikan deleted=1. Migrasi versi 1 ke 2 menambah tombstone, indeks dan menormalkan timestamp lama. cached_posts(id, payload, cached_at) menyimpan bacaan dalam transaksi SQLite. SharedPreferences hanya menyimpan preferensi.

## Cache-first

Provider membaca cache terlebih dahulu. Cache terisi langsung tampil, lalu jaringan memperbarui di belakang. Gagal refresh mempertahankan data lama. Cache kosong memerlukan jaringan; kegagalan menampilkan error. Offline paksa melewati jaringan dan menjelaskan bila belum ada cache. Generation guard menghindari refresh lama mengganti state yang sudah berubah atau dibuang.

## Antrean tulisan

Tambah/ubah disimpan terlebih dahulu dengan dirty=1. Update memakai waktu monoton terhadap versi catatan sebelumnya. Hapus menyimpan tombstone deleted=1, dirty=1; badge tetap menghitungnya. syncNotes mengambil snapshot dirty dan melakukan PUT satu per satu secara async.

Server menyelesaikan konflik dalam transaksi SQLite, lalu mengembalikan HTTP 200 setelah commit. Lokal memvalidasi ACK, lalu conditional UPDATE hanya membersihkan dirty jika id, timestamp, judul, isi, deleted dan dirty masih sama dengan snapshot. Edit selama upload tetap dirty. Timeout menghentikan batch; catatan yang telah diakui bersih, sisanya tetap dirty untuk retry. Daftar/detail/badge di-refresh juga pada kegagalan parsial.

Retry PUT versi yang sama aman jika respons sebelumnya hilang setelah commit. Tombstone yang bersih tetap disimpan di server/lokal. Aplikasi melakukan push manual; GET /notes disediakan server untuk inspeksi, bukan pull sync otomatis aplikasi.

## Last-write-wins eksplisit

Bandingkan instant UTC updated_at. Remote lebih baru: remote menang dan hasilnya diterapkan lokal. Lokal lebih baru: lokal menang. Timestamp sama: versi lokal yang dikirim menang. Tombstone mengikuti aturan yang sama; edit lebih baru dapat menghidupkan kembali catatan.

| Lokal | Server | Keputusan |
|---|---|---|
| 10:02 | 10:01 | Lokal |
| 10:01 | 10:02 | Server |
| 10:02 | 10:02 | Lokal yang dikirim |
| Tombstone 10:03 | Catatan 10:02 | Tombstone |
| Edit selama upload 10:04 | ACK snapshot 10:03 | ACK tidak diterapkan; edit tetap dirty |

Keterbatasan: jam perangkat dapat meleset; LWW tidak menggabungkan field dan bisa kehilangan versi kalah. Server demo hanya satu perangkat/namespace. Id autoincrement tidak cocok untuk banyak perangkat atau reinstall dengan server lama. Gunakan database server baru pada praktikum baru. Produksi memerlukan UUID, autentikasi, HTTPS, versi server/CAS dan pull sync lintas perangkat.
