# Audio lagu penuh

Letakkan MP3 sesuai nama berikut:

| Lagu | File |
| --- | --- |
| Hindia — Everything U Are | `everything-u-are.mp3` |
| .Feast — Nina | `nina.mp3` |
| .Feast — Peradaban | `peradaban.mp3` |
| Payung Teduh — Akad | `akad.mp3` |

`everything-u-are.mp3` disalin dari aset proyek week_4. File lainnya ditambahkan oleh pengguna.

Jalankan ulang `flutter run` setelah menambah file agar asset manifest diperbarui. Durasi pemutar dibaca dari MP3, tidak dibatasi cuplikan atau angka durasi pada katalog. Lagu tanpa file menampilkan “Audio lagu belum tersedia”.

Pemetaan file ada di `lib/shared/data/song_audio_sources.dart`. Audio tersedia lewat package music lokal pada Android, iOS, dan web. Desktop native belum didukung.
