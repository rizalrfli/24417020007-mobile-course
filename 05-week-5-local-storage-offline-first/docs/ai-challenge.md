# AI Challenge

## Prompt aktual

```text
Kembangkan project praktikum (atau buat baru) dengan ketentuan berikut:
1. Preferensi: toggle tema gelap/terang + waktu terakhir dibuka melalui SharedPreferences.
2. CRUD catatan persisten melalui SQLite (sqflite) dengan repository lokal + Riverpod; daftar diurutkan updated_at terbaru.
3. Offline-first: cache-first untuk data bacaan, dirty flag + syncNotes untuk tulisan, dan aturan konflik eksplisit yang didokumentasikan.
4. Bukti mode pesawat: screenshot daftar catatan saat offline dan badge dirty sebelum/sesudah sync.
5. Testing: minimal 2 test lulus (1 unit test model + 1 test provider dengan repository palsu).
6. AI Challenge: dokumentasikan prompt, tabel perbandingan storage, keputusan final, serta alasan teknis di docs/.
7. Repository: push ke repository portfolio pada folder 05-week-5-local-storage-offline-first/ dengan struktur lib/, test/, docs/, README.md, dan screenshots/.
README minimal memuat: tujuan, fitur utama, stack teknologi, cara menjalankan, hasil yang dicapai, aturan konflik yang dipilih, dan temuan verifikasi AI.
```

Isi prompt disalin dengan penomoran/spasi dinormalisasi. Pengguna kemudian menambahkan empat pertanyaan refleksi yang dijawab di refleksi.md. Ini prompt yang benar-benar digunakan bersama Codex, bukan eksperimen prompt kedua. Project dasar `week5_offline_notes` diperiksa sebelum dikembangkan.

## Keputusan final dan verifikasi AI

| Temuan | Keputusan dan bukti |
|---|---|
| Sync lama hanya menunggu lalu membersihkan semua dirty | Ditolak. PUT HTTP ke server demo menggantikannya; server commit SQLite sebelum ACK. |
| markAllSynced dapat menghapus edit baru | Conditional ACK mencocokkan snapshot yang dikirim. Test fake dan SQLite memeriksa edit selama upload. |
| Hapus langsung menghilangkan baris | Tombstone persisten masuk antrean dirty dan disembunyikan dari daftar. |
| Konflik hanya helper terpisah dari sync | Server menerapkan LWW UTC dalam transaksi dan mengembalikan pemenang. |
| Waktu sesi dicatat baru ketika Pengaturan dibuka | Root aplikasi mengamati lastOpenedProvider sejak awal sesi. |
| Dokumen lama menyebut cache SharedPreferences | Dikoreksi berdasarkan kode: bacaan berada di tabel SQLite cached_posts. |
| Timestamp pecahan detik tidak seragam | Serialisasi enam digit UTC agar urutan string benar. Diuji di SQLite. |
| Screenshot lama berasal dari sync simulasi | Bukti versi HTTP diambil ulang pada emulator; screenshot lama tidak dianggap verifikasi versi baru. |

SQLite dipilih untuk transaksi, indeks dan conditional UPDATE. Riverpod menyediakan injeksi repository fake dan invalidasi state setelah mutasi/sync, termasuk kegagalan parsial. SharedPreferences hanya untuk preferensi kecil. [Perbandingan storage](perbandingan-storage.md) dan [refleksi](refleksi.md) menjelaskan alasan final.

Alur baca/tulis mengikuti [panduan offline-first Flutter](https://docs.flutter.dev/app-architecture/design-patterns/offline-first). Test provider memakai override sesuai [panduan Riverpod](https://riverpod.dev/docs/how_to/testing). Bukan klaim bahwa sqflite selalu lebih cepat dari alternatif, atau demo sudah siap untuk sinkronisasi banyak perangkat.

19 test unit/provider/repository/widget lulus. Hasil akhir dicatat dalam [uji-offline.md](uji-offline.md) dengan log sebenarnya.
