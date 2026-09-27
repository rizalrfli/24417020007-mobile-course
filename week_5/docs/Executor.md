# executor.md

## 1. Purpose

Dokumen ini mendefinisikan urutan implementasi aplikasi **LyricWave**.

Executor atau developer harus mengikuti:

```text
PRD.MD
DESIGN.MD
architecture-review.md
qa.md
```

Urutan prioritas:

```text
Correctness
↓
Maintainability
↓
UX Consistency
↓
Performance
↓
Additional Features
```

---

# 2. Technology Stack

Gunakan:

```text
Flutter
Dart
Riverpod
GoRouter
Dio
Freezed
json_serializable
CachedNetworkImage
Drift / Isar
Flutter Secure Storage
Google Fonts
```

Optional:

```text
Firebase
Supabase
Sentry
```

---

# 3. Initial Project Setup

Struktur awal:

```text
lib/
├── app/
├── core/
├── features/
├── shared/
└── main.dart
```

Run:

```bash
flutter pub get
flutter analyze
flutter test
```

Semua harus berhasil sebelum development feature dimulai.

---

# 4. Folder Structure

Gunakan feature-first architecture.

```text
lib/
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── api/
│   ├── error/
│   ├── storage/
│   ├── utils/
│   └── constants/
│
├── features/
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── search/
│   ├── song/
│   ├── artist/
│   ├── favorite/
│   ├── history/
│   └── auth/
│
└── shared/
    ├── widgets/
    └── models/
```

---

# 5. Feature Structure

Contoh:

```text
features/song/
├── data/
│   ├── datasource/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── controllers/
    ├── screens/
    └── widgets/
```

---

# 6. Execution Phase

## Phase 1 — Foundation

Implementasikan:

```text
Flutter project
Theme
Router
Error handler
API client
Storage
Reusable components
```

Definition of Done:

```text
App dapat dijalankan.
Navigation tersedia.
Theme sesuai DESIGN.MD.
```

---

## Phase 2 — Song Domain

Implementasikan:

```text
Song
Artist
Album
Lyrics
```

Repository interface dibuat sebelum implementasi datasource.

---

## Phase 3 — Home

Buat:

```text
HomeScreen
SongCard
RecentlyViewed
PopularSongs
PopularArtists
```

---

## Phase 4 — Search

Implementasikan:

```text
Search input
Debounce
Search provider
Result
Empty state
Error state
```

Debounce:

```text
300–500 ms
```

Jangan API call setiap karakter tanpa debounce.

---

## Phase 5 — Song Detail

Implementasikan:

```text
Song metadata
Album cover
Favorite
Lyrics
Artist navigation
```

Prioritas tertinggi pada readability lyrics.

---

## Phase 6 — Favorites

Implementasikan:

```text
Favorite repository
Local favorite
Remote sync optional
Favorite screen
```

Optimistic update dapat digunakan.

Jika API gagal, state harus dikembalikan.

---

## Phase 7 — History

Saat lagu dibuka:

```text
recordSongView(song)
```

Limit awal:

```text
50 songs
```

Jika song sudah ada, pindahkan ke posisi terbaru.

---

## Phase 8 — Authentication

Jika authentication menjadi bagian MVP:

```text
Login
Register
Logout
Session
```

Token disimpan menggunakan:

```text
flutter_secure_storage
```

---

# 7. API Rules

Seluruh request melewati:

```text
ApiClient
```

Dilarang melakukan:

```dart
Dio().get(...)
```

langsung dari widget.

Flow:

```text
Widget
↓
Controller
↓
Use Case
↓
Repository
↓
Datasource
↓
API
```

---

# 8. UI Rules

Developer wajib mengikuti `DESIGN.MD`.

Tidak boleh menggunakan:

```text
Gradient
Random color
Arbitrary spacing
Different radius tanpa alasan
```

Gunakan theme constants.

Contoh:

```dart
AppColors.background
AppColors.surface
AppColors.primary
AppColors.textPrimary
```

---

# 9. State Handling

Setiap async feature harus memiliki:

```text
loading
success
empty
error
```

Contoh:

```text
SearchLoading
SearchSuccess
SearchEmpty
SearchError
```

---

# 10. Error Handling

Jangan:

```dart
catch (e) {
  print(e);
}
```

saja.

Gunakan typed failure:

```text
NetworkFailure
TimeoutFailure
ServerFailure
UnauthorizedFailure
NotFoundFailure
UnknownFailure
```

User hanya melihat human-readable message.

---

# 11. Logging

Development:

```text
Request
Status code
Failure
Navigation error
```

Production:

Jangan log:

```text
Password
Token
API secret
Personal data
```

---

# 12. Coding Standard

Gunakan:

```bash
dart format .
flutter analyze
flutter test
```

Sebelum commit.

---

# 13. Naming Convention

File:

```text
snake_case.dart
```

Class:

```text
PascalCase
```

Variable:

```text
camelCase
```

Provider:

```text
songProvider
favoriteSongsProvider
```

---

# 14. Git Workflow

Branch:

```text
main
develop
feature/*
fix/*
refactor/*
```

Contoh:

```text
feature/song-detail
feature/search
fix/lyrics-overflow
```

Commit:

```text
feat: add song detail
fix: handle missing lyrics
refactor: move song repository
test: add search repository test
```

---

# 15. Executor Completion Checklist

Sebelum feature dianggap selesai:

* Requirement sesuai PRD.
* UI sesuai DESIGN.
* Loading tersedia.
* Empty state tersedia.
* Error state tersedia.
* Responsive.
* Unit test tersedia.
* Widget test jika relevan.
* `flutter analyze` sukses.
* `flutter test` sukses.
* Tidak terdapat API secret.
* Tidak terdapat gradient.
* Tidak terdapat debug code production.

---

---

# qa.md

## 1. QA Purpose

QA memastikan aplikasi LyricWave:

* berjalan sesuai PRD;
* mempunyai UI konsisten;
* tidak crash;
* menangani network failure;
* menampilkan lirik dengan benar.

---

# 2. Test Environment

Minimum:

```text
Android 10+
iOS 15+
```

Screen:

```text
Small Android
Standard Android
Large Android
iPhone
```

Test juga pada:

```text
Wi-Fi
Mobile data
Slow connection
Offline
```

---

# 3. Testing Layers

Gunakan:

```text
Unit Test
Widget Test
Integration Test
Manual QA
```

---

# 4. Unit Test

Prioritaskan:

```text
Repository
Use Case
Controller
Data mapper
Favorite logic
History logic
```

Contoh:

```text
searchSongs returns songs when API succeeds.

searchSongs returns failure when API timeout.

favoriteSong stores song correctly.

history prevents unnecessary duplicate.
```

---

# 5. Home Test Cases

## QA-HOME-001

Action:

```text
Launch app.
```

Expected:

```text
Home tampil tanpa crash.
```

## QA-HOME-002

Kondisi:

```text
API loading.
```

Expected:

```text
Skeleton tampil.
```

## QA-HOME-003

Kondisi:

```text
API error.
```

Expected:

```text
Error message dan Retry tampil.
```

---

# 6. Search Test Cases

## QA-SEARCH-001

Input:

```text
Coldplay
```

Expected:

```text
Lagu atau artis relevan tampil.
```

## QA-SEARCH-002

Input:

```text
''
```

Expected:

```text
Tidak melakukan unnecessary search.
```

## QA-SEARCH-003

Input:

```text
randomquerythatdoesnotexist
```

Expected:

```text
Empty state tampil.
```

## QA-SEARCH-004

Input:

```text
hello
HELLO
Hello
```

Expected:

```text
Search tidak gagal hanya karena perbedaan uppercase/lowercase.
```

---

# 7. Song Detail Tests

Pastikan:

```text
Cover tampil.
Judul tampil.
Artist tampil.
Lyrics tampil.
Metadata benar.
```

Jika cover gagal:

```text
Placeholder image tampil.
```

Jika lyrics kosong:

```text
Lyrics are currently unavailable.
```

---

# 8. Lyrics Stress Test

Test lirik:

```text
1 baris
20 baris
100 baris
500+ baris
```

Pastikan:

* Tidak overflow.
* Scroll bekerja.
* Tidak terpotong.
* Font tetap readable.
* Layout tidak freeze.

---

# 9. Favorite Tests

Test:

```text
Add favorite
Remove favorite
Repeated tap
Restart app
Offline favorite
```

Expected:

Favorite tetap konsisten setelah restart jika disimpan local.

---

# 10. History Test

Buka:

```text
Song A
Song B
Song C
Song A
```

Expected:

```text
Song A
Song C
Song B
```

Song A tidak perlu muncul dua kali.

---

# 11. Network Test

Simulasikan:

```text
No internet
Timeout
500
404
401
Malformed response
Slow connection
```

Aplikasi tidak boleh crash.

---

# 12. Navigation Test

Test:

```text
Home → Song
Song → Artist
Artist → Song
Back
Search → Song
Favorite → Song
```

Back stack harus benar.

---

# 13. UI QA

Periksa seluruh halaman.

### Colors

Tidak boleh ditemukan:

```text
Gradient
```

Background harus konsisten dengan DESIGN.MD.

### Typography

Periksa:

```text
Title hierarchy
Lyrics readability
Metadata readability
```

### Spacing

Periksa:

```text
16 px default horizontal
24 px section spacing
```

Tidak harus pixel-perfect pada semua device, tetapi harus konsisten.

---

# 14. Responsive QA

Periksa:

```text
320 px
360 px
390 px
430 px
600 px+
```

Tidak boleh:

* overflow horizontal;
* clipped button;
* clipped song title;
* lyrics keluar layar.

---

# 15. Performance QA

Periksa:

```text
Scrolling song list
Scrolling lyrics
Search
Image loading
Navigation
```

Target:

```text
Smooth scrolling
No obvious frame drops
```

---

# 16. Accessibility

Pastikan:

```text
Tap target >= 44–48 px
```

Contrast harus cukup jelas.

Icon penting memiliki semantic label.

Contoh:

```text
Add to favorite
Play song
Back
Search
```

---

# 17. Release Blocking Bugs

Tidak boleh release jika terdapat:

```text
Crash
Login gagal total
Search tidak bekerja
Song detail tidak dapat dibuka
Lyrics menyebabkan crash
Favorite corrupt
Navigation loop
API secret exposed
```

---

# 18. Pre Release Checklist

```bash
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --release
```

Harus berhasil sebelum release candidate disetujui.

---

---

# architecture-review.md

## 1. Architecture Objective

Arsitektur LyricWave harus:

* scalable;
* mudah diuji;
* mudah mengganti API;
* tidak mengikat UI langsung ke backend;
* mendukung offline cache;
* memisahkan business logic dari Flutter widget.

---

# 2. Recommended Architecture

Gunakan:

> **Feature-first Clean Architecture**

Flow utama:

```text
Presentation
     ↓
Domain
     ↓
Data
```

Atau:

```text
Flutter UI
   ↓
Riverpod Controller
   ↓
Use Case
   ↓
Repository Interface
   ↓
Repository Implementation
   ↓
Remote / Local Datasource
```

---

# 3. Architecture Diagram

```text
┌─────────────────────────────┐
│        Presentation         │
│                             │
│ Screen / Widget / Provider  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│            Domain           │
│                             │
│ Entity / Repository /       │
│ Use Case                    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│             Data            │
│                             │
│ Repository Implementation   │
│ Remote Datasource           │
│ Local Datasource            │
└──────────────┬──────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
     REST API       Local DB
```

---

# 4. Presentation Layer

Berisi:

```text
Screen
Widget
Controller
Riverpod Provider
UI State
```

Tidak boleh:

* melakukan SQL;
* memanggil Dio langsung;
* menyimpan API secret;
* melakukan parsing response kompleks.

---

# 5. Domain Layer

Layer paling independen.

Berisi:

```text
Entity
Repository Interface
Use Case
```

Contoh:

```text
SearchSongs
GetSongDetail
GetSongLyrics
AddFavorite
RemoveFavorite
GetHistory
```

Domain tidak bergantung pada Flutter UI.

---

# 6. Data Layer

Berisi:

```text
DTO
Mapper
Datasource
Repository Implementation
```

Contoh:

```text
SongDto
SongMapper
SongRemoteDatasource
SongLocalDatasource
SongRepositoryImpl
```

---

# 7. Dependency Direction

Allowed:

```text
Presentation → Domain

Data → Domain
```

Hindari:

```text
Domain → Presentation
Domain → Flutter Widget
Domain → Dio
```

---

# 8. State Management Review

Gunakan:

**Riverpod**

Alasan teknis:

* dependency injection;
* async state;
* testable;
* cocok dengan feature-first structure;
* mengurangi coupling antara widget dan business logic.

Contoh konseptual:

```text
songRepositoryProvider

↓	

songDetailControllerProvider

↓

SongDetailScreen
```

---

# 9. Navigation

Gunakan:

```text
go_router
```

Routes:

```text
/
 /search
 /song/:id
 /artist/:id
 /favorites
 /history
 /profile
```

Jika login diperlukan:

```text
/login
/register
```

Gunakan redirect untuk authentication.

---

# 10. API Architecture

Untuk prototype:

```text
Flutter
↓
External API
```

Untuk production direkomendasikan:

```text
Flutter
↓
Application Backend
↓
Music Metadata API
↓
Lyrics Provider
```

Backend memberikan:

* secret protection;
* API aggregation;
* rate limit;
* normalization;
* caching.

---

# 11. Repository Pattern

UI tidak perlu mengetahui sumber data.

Contoh:

```text
SongRepository
```

dapat mengambil data dari:

```text
Remote API
Local DB
Cache
```

tanpa mengubah UI.

---

# 12. Cache Strategy

Home:

```text
Cache 15–30 menit
```

Song metadata:

```text
Cache beberapa jam
```

Lyrics:

```text
Cache lebih lama apabila lisensi/provider mengizinkan.
```

Favorite:

```text
Persist
```

History:

```text
Persist
```

---

# 13. Search Architecture

Flow:

```text
SearchField
↓
Debounce
↓
SearchController
↓
SearchSongs
↓
SongRepository
↓
API
```

Debounce:

```text
300–500 ms
```

Search sebelumnya harus dapat dibatalkan jika keyword baru dikirim.

---

# 14. Failure Architecture

Gunakan:

```text
Failure
```

daripada melempar API exception hingga UI.

Hierarchy:

```text
Failure
├── NetworkFailure
├── TimeoutFailure
├── ServerFailure
├── UnauthorizedFailure
├── NotFoundFailure
└── UnknownFailure
```

Controller mengubah failure menjadi UI message.

---

# 15. Image Architecture

Gunakan:

```text
cached_network_image
```

Wajib mempunyai:

```text
placeholder
errorWidget
cache
```

Jangan download image ulang setiap rebuild.

---

# 16. Security Review

## API Key

Tidak boleh:

```dart
const apiKey = "SECRET_KEY";
```

di repository public.

Untuk secret penting gunakan backend proxy.

---

## Auth Token

Simpan:

```text
Flutter Secure Storage
```

Jangan menggunakan SharedPreferences untuk token sensitif.

---

## HTTPS

Production API wajib menggunakan:

```text
HTTPS
```

---

# 17. Lyrics Architecture

Pisahkan music metadata dan lyrics.

```text
SongRepository
LyricsRepository
```

karena sumber datanya mungkin berbeda.

Contoh:

```text
Music API
→ song metadata

Lyrics API
→ lyrics
```

Song detail dapat menggabungkan keduanya.

---

# 18. Player Architecture

Apabila audio preview ditambahkan:

```text
PlayerService
```

menjadi global service.

State:

```text
idle
loading
playing
paused
completed
error
```

Data:

```text
currentSong
position
duration
queue
```

Jangan menyimpan player state langsung di SongDetailScreen.

---

# 19. Database

Rekomendasi:

```text
Drift
```

atau:

```text
Isar
```

Entity local:

```text
FavoriteSong
SongHistory
CachedSong
AppPreference
```

---

# 20. Scalability Review

Struktur feature-first memungkinkan penambahan:

```text
Playlist
Translation
Synced Lyrics
Recommendation
Audio Player
User Profile
```

tanpa mengubah keseluruhan struktur proyek.

---

# 21. Architecture Risks

## Risk 1 — Lyrics Provider

API mungkin:

* rate limited;
* tidak memiliki semua lagu;
* memiliki restriction penggunaan.

Mitigasi:

```text
Repository abstraction
Provider fallback
Cache
Licensed provider
```

---

## Risk 2 — API Key Exposure

Flutter merupakan client application sehingga secret dapat diekstrak.

Mitigasi:

```text
Backend proxy
```

---

## Risk 3 — Large Lyrics

Lirik panjang dapat menyebabkan expensive rebuild.

Mitigasi:

```text
Separate LyricsWidget
Avoid unnecessary rebuild
Use efficient scrolling
```

---

## Risk 4 — Large Song Lists

Mitigasi:

```text
Pagination
Lazy list
Cached images
```

Gunakan:

```dart
ListView.builder
```

---

# 22. Architecture Decision Records

### ADR-001

**Decision:** Flutter

Reason:

```text
Cross-platform mobile development.
```

### ADR-002

**Decision:** Riverpod

Reason:

```text
State management + dependency injection.
```

### ADR-003

**Decision:** Feature-first architecture

Reason:

```text
Scale berdasarkan feature.
```

### ADR-004

**Decision:** Repository abstraction

Reason:

```text
External API dapat berubah tanpa mengubah UI.
```

### ADR-005

**Decision:** Separate LyricsRepository

Reason:

```text
Music metadata dan lyrics dapat berasal dari provider berbeda.
```

### ADR-006

**Decision:** No Gradient Design System

Reason:

```text
Menjaga identitas visual aplikasi tetap minimal, dark, dan konsisten.
```

---

# 23. Final Architecture

```text
                     ┌────────────────┐
                     │     Flutter    │
                     │       UI       │
                     └───────┬────────┘
                             │
                             ▼
                     ┌────────────────┐
                     │    Riverpod    │
                     │   Controller   │
                     └───────┬────────┘
                             │
                             ▼
                     ┌────────────────┐
                     │    Use Case    │
                     └───────┬────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │     Repository       │
                  └──────────┬───────────┘
                             │
                ┌────────────┴────────────┐
                ▼                         ▼
        ┌───────────────┐         ┌───────────────┐
        │ Remote Source │         │ Local Source  │
        └───────┬───────┘         └───────┬───────┘
                │                         │
         ┌──────┴──────┐                  │
         ▼             ▼                  ▼
     Music API     Lyrics API       Local Database
```

Architecture status:

```text
Suitable for MVP: YES

Suitable for scaling: YES

API replaceable: YES

Testable: YES

Offline capable: YES

Supports future player: YES
```
