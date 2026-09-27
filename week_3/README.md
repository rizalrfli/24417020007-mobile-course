# week_3

A new Flutter project.

## Pembelajaran widget Hero

Gambar sampul di `lib/main.dart` dan `lib/detail_lagu.dart` dibungkus
dengan widget `Hero` yang memiliki `tag: 'sampul-lagu'` yang sama.
Flutter menggunakan tag tersebut untuk memasangkan gambar pada kedua route.
Tag harus unik di dalam setiap route; jika ada beberapa lagu, gunakan tag
berbeda untuk masing-masing lagu.

Tekan **Detail lagu** untuk melihat gambar bertransisi dari ukuran 200 × 200
ke 280 × 280. Tekan **Kembali** atau tombol kembali pada AppBar untuk melihat
animasi sebaliknya. Perpindahan menggunakan `Navigator.push` dengan
`MaterialPageRoute`, sedangkan kembali menggunakan `Navigator.pop`.

## Pembelajaran DatePicker

Widget `PilihTanggal` di `lib/pilih_tanggal.dart` menggunakan `showDatePicker`
untuk membuka dialog kalender. Tekan **Pilih tanggal**, pilih hari, lalu tekan
**Simpan** untuk menampilkan tanggal dalam format hari/bulan/tahun.
Rentang pilihan adalah 10 tahun sebelum sampai 10 tahun setelah tahun sekarang.

Hasil dialog ditunggu dengan `await`, kemudian disimpan melalui `setState`
agar tampilan diperbarui. **Ubah tanggal** membuka pilihan terakhir.
**Batal** mempertahankan nilai sebelumnya karena dialog mengembalikan `null`.
Pengecekan `mounted` mencegah pembaruan state jika widget sudah dilepas.
Tanggal hanya disimpan selama widget masih aktif, belum ke penyimpanan permanen.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
