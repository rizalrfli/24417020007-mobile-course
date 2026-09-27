# DESIGN.MD — LyricWave

## 1. Design Overview

**LyricWave** adalah aplikasi mobile berbasis Flutter untuk menampilkan informasi lagu seperti:

* Judul lagu
* Nama artis
* Album
* Cover album
* Durasi lagu
* Tahun rilis
* Genre
* Lirik lagu
* Lagu favorit
* Riwayat lagu yang pernah dibuka

Aplikasi mengambil inspirasi pengalaman penggunaan aplikasi musik modern seperti Spotify, tetapi memiliki identitas visual sendiri.

Fokus utama desain adalah:

> **Dark, clean, immersive, modern, dan lyrics-first.**

Aplikasi menggunakan kombinasi warna **biru gelap dan hitam tanpa gradient**.

---

# 2. Design Principles

## 2.1 Dark First

Semua halaman menggunakan tema gelap sebagai tampilan utama.

Tidak tersedia light mode pada versi MVP.

Background utama menggunakan warna hampir hitam dengan sedikit tone biru.

---

## 2.2 No Gradient

Dilarang menggunakan:

* Linear gradient
* Radial gradient
* Gradient button
* Gradient card
* Gradient background

Gunakan:

* Solid color
* Border
* Shadow tipis
* Opacity
* Perbedaan elevation

untuk menciptakan hierarchy.

---

## 2.3 Lyrics First

Lirik merupakan informasi utama aplikasi.

Halaman detail lagu harus memberikan ruang terbesar kepada lirik dibanding metadata lainnya.

---

## 2.4 Minimal Interface

Hindari terlalu banyak:

* Border
* Shadow
* Icon
* Button
* Decorative element

Setiap komponen UI harus memiliki fungsi yang jelas.

---

# 3. Color Palette

## Primary Background

```text
App Background
#05070A

Secondary Background
#080D14

Surface
#0D1520

Elevated Surface
#111C29
```

## Primary Color

```text
Primary Blue
#1D78F2

Primary Hover / Active
#2788FF

Dark Blue
#0B376D
```

## Text

```text
Primary Text
#F5F7FA

Secondary Text
#A5AFBD

Muted Text
#667085
```

## Semantic Colors

```text
Success
#22C55E

Warning
#F59E0B

Error
#EF4444
```

Tidak menggunakan gradient pada semantic color maupun primary color.

---

# 4. Typography

Font utama:

**Inter**

Fallback:

```text
Roboto
Arial
sans-serif
```

Flutter:

```dart
GoogleFonts.inter()
```

## Typography Scale

### Display

```text
32 px
Bold
```

Digunakan untuk nama lagu pada hero section tertentu.

### Heading 1

```text
24 px
700
```

### Heading 2

```text
20 px
700
```

### Heading 3

```text
18 px
600
```

### Body Large

```text
16 px
400
```

### Body

```text
14 px
400
```

### Caption

```text
12 px
400
```

### Lyrics

```text
22–28 px
500–700
Line-height: 1.4–1.6
```

Lyrics aktif dapat menggunakan:

```text
#F5F7FA
```

Lyrics nonaktif:

```text
#667085
```

---

# 5. Spacing System

Gunakan sistem berbasis kelipatan 4.

```text
4 px
8 px
12 px
16 px
20 px
24 px
32 px
40 px
48 px
```

Default horizontal padding:

```text
16 px
```

Section spacing:

```text
24 px
```

---

# 6. Border Radius

Gunakan rounded corner secara konsisten.

```text
Small        8 px
Medium       12 px
Large        16 px
Extra Large  24 px
Circle       999 px
```

Album cover:

```text
12–16 px
```

Card:

```text
16 px
```

Button:

```text
12 px
```

---

# 7. Navigation

Gunakan **Bottom Navigation Bar**.

Menu MVP:

1. Home
2. Search
3. Favorites
4. Profile

Contoh:

```text
┌─────────────────────────────┐
│                             │
│        Page Content         │
│                             │
├─────────────────────────────┤
│ Home Search Favorite Profile│
└─────────────────────────────┘
```

Bottom navigation:

```text
Background: #080D14
Selected:   #1D78F2
Unselected: #667085
```

---

# 8. Home Screen

Struktur:

```text
Greeting

Recently Viewed

Popular Songs

Recommended Songs

Popular Artists
```

Contoh:

```text
Good Evening

Recently Played
┌─────┐ ┌─────┐ ┌─────┐
│ IMG │ │ IMG │ │ IMG │
└─────┘ └─────┘ └─────┘

Popular Songs

01  Album     Song Name
              Artist

02  Album     Song Name
              Artist
```

Album cover tidak perlu terlalu besar.

---

# 9. Song Card

## Horizontal Song Card

Struktur:

```text
┌──────┐
│Album │  Song Title
│Cover │  Artist
└──────┘
```

Ukuran cover:

```text
56 x 56 px
```

Judul:

```text
14 px
600
```

Artist:

```text
12 px
#A5AFBD
```

Optional action:

```text
⋮
```

---

# 10. Song Detail Screen

Halaman terpenting dalam aplikasi.

Struktur:

```text
          Album Cover

           Song Name
           Artist Name

♡        ⋮

───────────────

Lyrics

I remember when...
The night was...
...

───────────────

Album
Release Year
Genre
Duration
```

Album cover:

```text
240–280 px
```

Jangan menggunakan background gradient berdasarkan album.

Tetap gunakan background solid:

```text
#05070A
```

---

# 11. Lyrics View

Lirik menjadi elemen utama.

Contoh:

```text
Yesterday
All my troubles seemed
so far away

Now it looks as though
they're here to stay
```

Style:

```text
Font Size : 24 px
Weight    : 600
Line Height: 1.5
```

Jika aplikasi mempunyai synced lyrics:

```text
Previous lyric
#667085

Current lyric
#F5F7FA
Bold

Next lyric
#A5AFBD
```

Current lyric boleh mempunyai indikator kecil:

```text
●
```

dengan warna:

```text
#1D78F2
```

---

# 12. Search Screen

Search bar:

```text
┌───────────────────────────┐
│ 🔍 Search songs or artists│
└───────────────────────────┘
```

Style:

```text
Background: #0D1520
Border: none
Radius: 12 px
```

Search dapat menerima:

* Song title
* Artist
* Album

State:

### Empty

```text
Search your favorite song
```

### Loading

Gunakan skeleton.

### Not Found

```text
No songs found.
Try another keyword.
```

### Result

```text
Songs

Album  Song Name
       Artist

Album  Song Name
       Artist
```

---

# 13. Favorites Screen

Struktur:

```text
Favorites

124 songs

Album   Song Name
        Artist

Album   Song Name
        Artist
```

User dapat:

* membuka lagu;
* menghapus favorite;
* mencari di dalam favorite.

---

# 14. Mini Player

Jika fitur audio preview/player tersedia, gunakan mini player.

Posisi:

```text
Above Bottom Navigation
```

Struktur:

```text
┌──────────────────────────────┐
│IMG  Song Name       ▶    ⏭ │
│     Artist                   │
└──────────────────────────────┘
```

Background:

```text
#111C29
```

Tidak menggunakan gradient.

---

# 15. Full Player

```text
          ─

       Album Cover


        Song Name
        Artist Name


────────────●────────

     01:34       03:46


    ⏮     ▶     ⏭


         Lyrics
```

Player control utama:

```text
Play button:
background #F5F7FA
icon #05070A
```

---

# 16. Profile Screen

Informasi:

```text
Avatar

Username
Email

Account
Preferences
About
Logout
```

Card background:

```text
#0D1520
```

---

# 17. Components

Komponen reusable:

```text
AppScaffold
AppTopBar
AppBottomNavigation
SongCard
SongTile
ArtistCard
AlbumCard
LyricsView
SearchField
FavoriteButton
PrimaryButton
SecondaryButton
MiniPlayer
EmptyState
ErrorState
LoadingSkeleton
```

---

# 18. Button

## Primary Button

```text
Background: #1D78F2
Text: #FFFFFF
Radius: 12 px
Height: 48 px
```

## Secondary Button

```text
Background: #0D1520
Text: #F5F7FA
Border: #1E293B
```

## Icon Button

```text
48 x 48
```

Gunakan icon dari:

```text
Lucide Icons
Material Icons
```

Jangan mencampurkan banyak gaya icon.

---

# 19. Loading State

Gunakan skeleton.

Contoh:

```text
████████
█████

████████████
██████
```

Warna:

```text
Base:
#0D1520

Highlight:
#172334
```

Tetap tanpa gradient animation.

Gunakan perubahan opacity jika ingin animasi.

---

# 20. Empty State

Contoh favorite kosong:

```text
♡
No favorite songs yet

Songs you favorite will
appear here.

[Explore Songs]
```

---

# 21. Error State

```text
Something went wrong.

We couldn't load the song.

[Try Again]
```

Jangan menampilkan error internal API langsung kepada user.

---

# 22. Responsive Rules

Target utama:

```text
360 px – 480 px
```

Support tablet:

```text
600 px+
```

Gunakan:

```dart
MediaQuery
LayoutBuilder
Flexible
Expanded
```

Hindari hardcoded width berdasarkan satu device tertentu.

---

# 23. Animation

Gunakan animasi sederhana:

```text
150 ms – 300 ms
```

Contoh:

* Favorite animation
* Page transition
* Play button
* Bottom navigation
* Skeleton opacity

Hindari excessive motion.

---

# 24. UI Restrictions

Dilarang menggunakan:

* Gradient
* Glassmorphism berlebihan
* Neon glow
* 3D icon
* Floating decorative blobs
* AI-style random illustration
* Terlalu banyak shadow
* Terlalu banyak border

Target visual:

> Modern music application yang terasa premium tetapi minimal.

---

# 25. Design Identity

LyricWave bukan clone Spotify.

Spotify hanya menjadi referensi dalam hal:

* Information hierarchy
* Navigation familiarity
* Music discovery UX
* Player interaction

LyricWave mempunyai identitas utama:

> **Dark-blue lyrics-centric music companion.**
