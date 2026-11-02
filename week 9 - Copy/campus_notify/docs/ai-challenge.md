# AI Challenge: Refactor `campus_notify`

## Prompt

> Refactor proyek Flutter `campus_notify` yang sudah berjalan ke Clean
> Architecture layer-first. Tingkat atas `lib/` hanya boleh memiliki
> `data/`, `domain/`, dan `presentation/`. Jaga perilaku login, FCM, inbox,
> badge, dan deep link. Pisahkan entity dari model JSON, letakkan kontrak
> repository di domain dan implementasinya di data, gunakan use case inbox
> yang bisa diuji dengan fake repository. Pastikan dependency hanya mengarah
> ke domain, dokumentasikan hasil grep, dan jalankan test.

## Ringkasan usulan AI dan keputusan akhir

| Usulan | Keputusan | Alasan |
| --- | --- | --- |
| Gunakan feature-first `lib/features/<feature>/{data,domain,presentation}` | Ditolak untuk tugas ini; gunakan hanya tiga folder layer-first di `lib/` | Bentuk folder mengikuti instruksi proyek dan slide layer-first untuk contoh kecil |
| Buat use case untuk setiap operasi CRUD | Ditolak | `GetInbox` dan `AddInboxItem` mewakili operasi/alur domain yang perlu diuji; `markRead` dan `clear` sederhana, sehingga repository dipanggil controller dengan alasan tercatat |
| Domain memiliki entity, failure, kontrak repository dan use case | Diterapkan | Domain tidak bergantung pada Flutter atau plugin |
| Model menangani JSON dan payload FCM | Diterapkan pada `InboxItemModel` di data | Entity `InboxItem` tetap bersih dari format penyimpanan dan transport |
| Repository implementasi menangkap error storage dan mengembalikan Failure | Diterapkan di `InboxRepositoryImpl` | Presentation menerima hasil terstruktur, bukan exception plugin |
| Riverpod menyusun repository implementasi, use case, dan controller | Diterapkan di provider pada presentation | Ini titik composition/wiring yang diizinkan; widget tidak membuat repository |
| Push background menyimpan inbox lewat repository | Diterapkan dengan implementasi data dalam isolate background | Tetap bekerja tanpa Riverpod di isolate tersebut |

## Struktur akhir

```text
lib/
├── data/
│   ├── auth/
│   ├── inbox/
│   ├── push/
│   ├── api_client.dart
│   └── token_store.dart
├── domain/
│   ├── auth/
│   ├── inbox/
│   ├── push/
│   └── failures.dart
└── presentation/
    ├── auth/
    ├── inbox/
    ├── push/
    ├── main.dart
    └── routes.dart
```

## Bukti dan test

- `GetInbox` sukses memakai `FakeInboxRepository`.
- `GetInbox` failure mengembalikan `LocalFailure` tanpa melempar exception.
- `AddInboxItem` memanggil kontrak repository melalui fake.
- `flutter analyze`: bersih.
- `flutter test`: seluruh test lulus.
- Screenshot lama ada di `screenshots/`. Screenshot after perlu diambil dari
  emulator/perangkat setelah menjalankan aplikasi dengan backend mock.
