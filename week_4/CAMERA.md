# Menjalankan kamera

Jalankan dari folder `week_4`:

```sh
flutter pub get
flutter run
```

Pilih perangkat Android, iOS, atau browser yang memiliki akses kamera. Paket
`camera` tidak mendukung aplikasi desktop Windows. Android minimal API 24.
Setelah menambah plugin, hentikan aplikasi lalu jalankan kembali; hot reload
saja tidak memasang plugin native.

Tekan **Buka kamera** pada halaman utama, lalu izinkan akses kamera. Halaman
menampilkan pratinjau langsung. Gunakan tombol kembali untuk menutup kamera.
Contoh ini belum mengambil atau menyimpan foto, dan mikrofon tidak diaktifkan.

## Alur kode

- `main.dart` membuka `CameraApp` melalui `Navigator.push`.
- `camera.dart` memanggil `availableCameras()` ketika halaman dibuka.
- `CameraController` menginisialisasi kamera pertama dengan kualitas `high`.
- `CameraPreview` menampilkan gambar setelah inisialisasi selesai.
- `WidgetsBindingObserver` melepas kamera ketika aplikasi tidak aktif dan
  membukanya lagi saat aktif. `dispose()` melepas kamera saat halaman ditutup.
- Pesan error dan tombol **Coba lagi** muncul jika kamera tidak tersedia atau
  izin ditolak. Jika izin ditolak permanen, aktifkan lewat pengaturan aplikasi.

Pada emulator, aktifkan kamera virtual atau webcam di konfigurasi perangkat.
Pada browser, akses kamera memerlukan localhost atau HTTPS dan izin browser.

Referensi: https://pub.dev/packages/camera
