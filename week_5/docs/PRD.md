# PRD.MD — LyricWave

## 1. Product Overview

### Product Name

**LyricWave**

### Platform

```text
Flutter
Android
iOS
```

### Product Type

Music lyrics discovery application.

### Product Description

LyricWave merupakan aplikasi mobile untuk mencari dan melihat informasi lagu serta lirik secara mudah.

Pengguna dapat mencari lagu berdasarkan judul, artis, atau album kemudian membuka detail lagu untuk melihat:

* Judul
* Artis
* Cover
* Album
* Tahun rilis
* Genre
* Durasi
* Lirik
* Informasi lainnya

Aplikasi menggunakan dark theme dengan warna biru gelap dan hitam.

---

# 2. Problem Statement

Pengguna sering harus berpindah antara aplikasi musik dan website untuk mengetahui lirik sebuah lagu.

Beberapa situs lirik juga mempunyai masalah:

* terlalu banyak iklan;
* UI tidak nyaman;
* informasi lagu tidak terstruktur;
* navigasi kurang mobile friendly;
* pengalaman membaca lirik kurang fokus.

LyricWave bertujuan menyediakan pengalaman pencarian dan membaca lirik yang cepat, minimal, dan nyaman.

---

# 3. Product Goal

Menghasilkan aplikasi Flutter yang memungkinkan pengguna untuk:

1. Mencari lagu.
2. Menampilkan metadata lagu.
3. Membaca lirik.
4. Menyimpan lagu favorit.
5. Melihat histori lagu.
6. Menjelajahi lagu berdasarkan artis atau kategori.

---

# 4. Target Users

Target utama:

```text
Usia: 15–35 tahun
```

Karakteristik:

* sering mendengarkan musik;
* ingin mengetahui lirik;
* mencari lagu berdasarkan artis atau judul;
* menggunakan smartphone sebagai perangkat utama.

---

# 5. MVP Scope

## Included

### Authentication

* Login
* Register
* Logout
* Persistent session

Authentication dapat dibuat opsional jika MVP ingin lebih sederhana.

---

### Home

Menampilkan:

* Recently viewed
* Popular songs
* Recommended songs
* Popular artists

---

### Search

Pengguna dapat mencari berdasarkan:

```text
Song
Artist
Album
```

---

### Song Detail

Menampilkan:

```text
Cover
Title
Artist
Album
Lyrics
Duration
Genre
Release year
```

---

### Favorite

Pengguna dapat:

```text
Add Favorite
Remove Favorite
View Favorite
```

---

### History

Aplikasi menyimpan lagu yang terakhir dibuka.

---

### Artist

Artist detail:

```text
Artist Name
Photo
Popular Songs
Albums
```

---

# 6. Out of Scope MVP

Tidak termasuk:

* Full music streaming
* Upload lagu
* Download MP3
* Social feed
* Chat
* Podcast
* Music marketplace
* Karaoke recording
* AI song generation

Fitur tersebut dapat dipertimbangkan pada versi selanjutnya.

---

# 7. User Flow

## Search Song

```text
Open App
    ↓
Home
    ↓
Search
    ↓
Input keyword
    ↓
Search result
    ↓
Select Song
    ↓
Song Detail
    ↓
Read Lyrics
```

---

# 8. Favorite Flow

```text
Song Detail
    ↓
Tap Heart
    ↓
Save Favorite
    ↓
Favorites
```

---

# 9. Functional Requirements

## FR-001 Home

Sistem harus dapat menampilkan daftar lagu.

Acceptance Criteria:

```text
Home dapat dibuka.
Daftar lagu tampil.
User dapat membuka lagu.
```

---

## FR-002 Search

Sistem harus menyediakan pencarian lagu.

Input:

```text
Song title
Artist
Album
```

Acceptance Criteria:

```text
Search <= 2 seconds pada kondisi jaringan normal.
Search bersifat case insensitive.
Empty result memiliki UI khusus.
```

---

## FR-003 Song Detail

Sistem harus menampilkan informasi lagu.

Required fields:

```text
id
title
artist
album
cover
lyrics
```

Optional:

```text
duration
genre
releaseYear
```

---

## FR-004 Lyrics

Sistem harus dapat mengambil dan menampilkan lirik.

Jika lirik tidak tersedia:

```text
Lyrics are currently unavailable.
```

---

## FR-005 Favorites

Sistem harus dapat menyimpan dan menghapus favorite.

---

## FR-006 History

Saat detail lagu dibuka, lagu dimasukkan ke history.

History tidak boleh menghasilkan duplicate entry berlebihan.

---

## FR-007 Artist

Pengguna dapat membuka halaman artis dari detail lagu.

---

# 10. Non Functional Requirements

## Performance

Target:

```text
Cold launch < 3 sec
Page navigation < 500 ms
API result target < 2 sec
```

Bergantung kondisi jaringan dan provider API.

---

## Reliability

Aplikasi harus tetap dapat menampilkan state yang benar ketika:

* API timeout
* tidak ada internet
* hasil kosong
* gambar gagal dimuat
* lyrics gagal dimuat

---

## Security

Sensitive configuration tidak boleh disimpan langsung pada repository.

Gunakan:

```text
.env
environment configuration
backend proxy
```

Jangan hardcode secret API key di source code production.

---

# 11. Lyrics Legal Requirement

Lyrics merupakan karya yang dapat dilindungi hak cipta.

Untuk production:

> Gunakan penyedia API atau database lirik yang memberikan izin/lisensi sesuai kebutuhan aplikasi.

Hindari scraping website lirik tanpa memastikan izin dan ketentuan penggunaannya.

Untuk development dapat menggunakan:

* Dummy lyrics
* Public-domain content
* Licensed development API

---

# 12. Data Model

## Song

```dart
class Song {
  String id;
  String title;
  Artist artist;
  Album? album;
  String? coverUrl;
  String? lyrics;
  Duration? duration;
  String? genre;
  int? releaseYear;
}
```

---

## Artist

```dart
class Artist {
  String id;
  String name;
  String? imageUrl;
}
```

---

## Album

```dart
class Album {
  String id;
  String title;
  String? coverUrl;
  int? releaseYear;
}
```

---

# 13. API Requirements

Architecture:

```text
Flutter
   ↓
Repository
   ↓
Lyrics/Music API
```

Lebih aman untuk production:

```text
Flutter
   ↓
Backend API
   ↓
External Music/Lyrics API
```

Tujuannya agar API key tidak terekspos.

---

# 14. API Endpoints

Contoh internal API:

```text
GET /songs/popular

GET /songs/{id}

GET /songs/search?q=

GET /songs/{id}/lyrics

GET /artists/{id}

GET /artists/{id}/songs

GET /favorites

POST /favorites/{songId}

DELETE /favorites/{songId}

GET /history
```

---

# 15. Offline Storage

Gunakan salah satu:

```text
Hive
Isar
Drift
SharedPreferences
```

Rekomendasi:

```text
Drift / Isar → structured local data

SharedPreferences → simple preference
```

Data offline:

* Favorite ID
* History
* Cache metadata
* Settings

---

# 16. State Management

Rekomendasi:

**Riverpod**

Digunakan untuk:

```text
Authentication
Search state
Songs
Favorites
History
Player
Theme/settings
```

State:

```text
initial
loading
success
empty
error
```

---

# 17. Analytics

Event yang dapat dicatat:

```text
app_open
song_open
song_search
artist_open
favorite_add
favorite_remove
lyrics_view
```

Jangan menyimpan data sensitif yang tidak diperlukan.

---

# 18. Future Features

### V1.1

* Synced lyrics
* Share lyrics
* Album detail
* Recently searched

### V1.2

* Audio preview
* Mini player
* Full player

### V2

* User playlist
* Lyrics translation
* Lyrics language detection
* Recommendation engine

### V3

* Lyric synchronization
* Collaborative playlist
* Cross-device synchronization

---

# 19. Success Metrics

Untuk MVP:

```text
Search success rate > 95%

Crash-free session > 99%

Successful lyrics page rendering > 95%

Favorite operation success > 99%
```

UX target:

```text
User dapat menemukan sebuah lagu dan membuka lirik dalam <= 4 interaction.
```

---

# 20. Definition of Done

Fitur dianggap selesai jika:

* Requirement terpenuhi.
* UI sesuai DESIGN.MD.
* Tidak terdapat critical bug.
* Unit test lulus.
* Widget test terkait lulus.
* Loading/error/empty state tersedia.
* Tidak terdapat secret dalam repository.
* Code sudah diformat.
* Analyzer tidak menghasilkan error.
