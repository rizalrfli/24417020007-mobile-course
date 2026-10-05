# Perbandingan Storage: SharedPreferences, Hive, sqflite, Drift

> **Proyek:** `week5_offline_notes`
> **Penguji:** 24417020007

---

## AI Prompt yang Digunakan

**Prompt dikirim ke AI:**
> Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
> Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
> untuk dua kebutuhan ini. Requirements:
> - Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
>   type-safety, ukuran boilerplate, dan kemudahan testing.
> - Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
>   beserta alasannya dalam 1 tabel.
> - Tunjukkan skema tabel/kotak untuk 1000+ catatan.
> - Jelaskan trade-off setiap pilihan.

---

## Tabel Perbandingan Kriteria (Hasil Verifikasi)

| Kriteria | SharedPreferences | Hive | sqflite | Drift |
|---|---|---|---|---|
| **Kompleksitas query** | Tidak mendukung query; hanya key-value | Tidak ada SQL; hanya iterasi/filter manual di Dart | SQL penuh: WHERE, ORDER BY, COUNT, INDEX | SQL aman via DSL Dart; compile-time checked |
| **Dukungan relasi** | Tidak ada | Tidak ada relasi native | Mendukung foreign key & JOIN | Mendukung relasi + type-safe references |
| **Reaktivitas (stream)** | Tidak ada stream; baca satu kali | `Box.watch()` stream tersedia | Tidak ada stream native; update via `ref.invalidate()` | `watch()` / `watchSingle()` stream bawaan |
| **Type-safety** | Dynamic — cast manual `as String?` | Adapters yang di-generate; semi type-safe | Raw `Map<String, Object?>`; cast manual di `fromMap` | Sepenuhnya type-safe via kode yang di-generate |
| **Ukuran boilerplate** | Sangat kecil (5–10 baris) | Sedang (adapter + `flutter pub run build_runner`) | Sedang (schema SQL + repository ~75 baris) | Besar (schema class + DAO + build_runner + migration) |
| **Kemudahan testing** | Mudah: `SharedPreferences.setMockInitialValues({})` | Sedang: perlu `Hive.init` atau in-memory box | Sangat mudah: `FakeNoteRepository` override, 0 dependency native | Mudah: `inMemoryDatabase()` bawaan untuk test |

---

## Tabel Rekomendasi Final

| Kriteria | SharedPreferences | Hive | sqflite | Drift |
|---|---|---|---|---|
| **Cocok untuk preferensi?** | **Ya — pilihan terbaik** | Bisa, namun berlebihan | Berlebihan untuk key-value | Berlebihan untuk key-value |
| **Cocok untuk 1000+ catatan?** | **Tidak** — JSON blob tidak scalable, tidak ada query, tidak ada dirty-flag per-item | Bisa jika data sederhana; filter manual lambat | **Ya — pilihan terbaik** untuk proyek ini | Ya, lebih baik jika dibutuhkan stream reaktif otomatis |
| **Keputusan & alasan** | Preferensi tema (`isDark`, `lastOpened`): simpel, zero boilerplate, official | Bukan pilihan utama | Catatan: SQL real, dirty-flag, testing mudah | Alternatif future jika butuh stream |

**Keputusan Final: `SharedPreferences` untuk preferensi + `sqflite` untuk catatan.**

---

## Skema Tabel untuk 1000+ Catatan

```sql
-- lib/data/local/db.dart
CREATE TABLE notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT    NOT NULL DEFAULT '',
  body       TEXT    NOT NULL DEFAULT '',
  updated_at TEXT    NOT NULL,   -- ISO 8601, untuk last-write-wins
  dirty      INTEGER NOT NULL DEFAULT 1  -- 0 = synced, 1 = pending sync
);

CREATE INDEX idx_notes_dirty   ON notes (dirty);
CREATE INDEX idx_notes_updated ON notes (updated_at DESC);
```

### Mengapa skema ini mendukung 1000+ catatan:

| Fitur skema | Alasan |
|---|---|
| `AUTOINCREMENT` | Id unik deterministik — aman untuk GoRouter `/note/:id` |
| `updated_at TEXT` | Memungkinkan `ORDER BY updated_at DESC` dan aturan konflik **last-write-wins** |
| `dirty INTEGER` | Antrean sync: `SELECT COUNT(*) WHERE dirty = 1` dalam O(1) dengan index |
| Index ganda | `ORDER BY updated_at DESC` + `WHERE dirty = 1` tetap cepat di 1000+ baris |

---

## Trade-off Setiap Pilihan

### SharedPreferences

**Pro:** Nol boilerplate, API async bersih, official Flutter package, testing trivial.

**Kontra:** Hanya key-value. Menyimpan `List<Note>` sebagai JSON string = tidak ada query, tidak ada dirty-flag per-item, baca-semua setiap kali.

**Kesimpulan:** Tepat untuk `isDark: bool`, `lastOpened: String`. **Tolak** untuk koleksi catatan.

### Hive

**Pro:** Cepat (binary box), tidak butuh plugin native (murni Dart), mendukung stream via `Box.watch()`.

**Kontra:** Tidak ada SQL, tidak ada relasi, adapter harus di-generate via `build_runner`. Query kompleks (antrean dirty, sorting) harus dilakukan manual di Dart — lambat untuk 1000+ item.

**Kesimpulan:** Pilihan tengah yang baik untuk data sederhana tanpa relasi. Untuk dirty-flag queue, sqflite lebih tepat.

### sqflite (Pilihan untuk Catatan)

**Pro:** SQL penuh (`WHERE dirty = 1`, `COUNT(*)`, `ORDER BY`). Testing mudah via repository pattern + fake. Tidak butuh code generation. Index untuk performa 1000+ baris.

**Kontra:** Tidak ada stream native; UI harus di-invalidate manual via Riverpod `ref.invalidate()`. Tidak mendukung platform web.

**Kesimpulan:** Solusi terbaik untuk offline-first CRUD + dirty-flag queue di proyek ini.

### Drift

**Pro:** Type-safe DSL Dart, stream `watch()` bawaan (reaktivitas otomatis), migrasi terstruktur, `inMemoryDatabase()` untuk test.

**Kontra:** Boilerplate besar (schema class + DAO + generated files). `build_runner` harus dijalankan setiap perubahan schema. Overhead signifikan untuk proyek kecil-menengah.

**Kesimpulan:** Ideal untuk proyek besar yang butuh reactivity otomatis tanpa `ref.invalidate()`. Untuk proyek ini, sqflite + Riverpod sudah cukup.

---

## Verifikasi AI Checklist

| Pertanyaan Verifikasi | Temuan | Status |
|---|---|---|
| Apakah AI menempatkan daftar catatan di SharedPreferences? | Tidak — implementasi memakai sqflite untuk catatan, SharedPreferences hanya untuk `isDark` dan `lastOpened` | Tolak tidak diperlukan |
| Apakah skema mendukung antrean sync (dirty flag / updated_at)? | Ya — kolom `dirty INTEGER DEFAULT 1` dan `updated_at TEXT` ada di skema dan terverifikasi di `NoteRepository` | Benar |
| Apakah klaim "real-time" didukung stream? | sqflite tidak punya stream native; update UI via `ref.invalidate(notesProvider)` setelah mutasi (bukan stream Drift) | Perlu catatan: bukan real-time murni |
| Apakah estimasi boilerplate masuk akal setelah install? | SharedPreferences: ~5 baris ✓. sqflite: ~75 baris repository + schema ✓. go_router: ~30 baris router ✓ | Sesuai |
| Keputusan final berbeda dari AI? | Tidak — SharedPreferences + sqflite sesuai rekomendasi AI dan terverifikasi lewat implementasi nyata dan 7 test | Konsisten |

---

## Hasil Testing

```
flutter test test/note_test.dart --reporter=compact

+7: All tests passed!

  Model Note
    fromMap aman terhadap field yang hilang          LULUS
    flag dirty bertahan pada serialisasi             LULUS

  Provider dengan repository palsu
    notesProvider sukses                             LULUS
    notesProvider error                              LULUS

  Offline-first
    syncNotes membersihkan semua catatan dirty       LULUS
    syncNotes ditolak saat offline dan dirty tetap   LULUS
    resolveConflict memilih updatedAt terbaru        LULUS

flutter analyze
  No issues found!
```
