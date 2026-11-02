import 'package:app_badge_plus/app_badge_plus.dart';

/// Abstraksi badge di ikon aplikasi (launcher / home screen).
///
/// Dipisah dari implementasi plugin supaya bisa diganti versi palsu di test dan
/// supaya kegagalan launcher tidak pernah menghentikan alur notifikasi.
abstract class BadgeSink {
  Future<void> setCount(int count);
}

/// Menulis angka ke ikon aplikasi.
///
/// Tidak semua launcher Android mendukung badge angka (mis. launcher stok
/// AOSP). Kegagalan diabaikan dengan sengaja: badge di dalam aplikasi
/// ([NotificationBell]) tetap menampilkan angka yang benar.
class LauncherBadgeSink implements BadgeSink {
  const LauncherBadgeSink();

  @override
  Future<void> setCount(int count) async {
    try {
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(count < 0 ? 0 : count);
      }
    } catch (_) {
      // Launcher tidak mendukung badge atau plugin tidak tersedia.
    }
  }
}

/// Versi palsu untuk test: mencatat angka terakhir yang diminta.
class MemoryBadgeSink implements BadgeSink {
  int? lastCount;
  int calls = 0;

  @override
  Future<void> setCount(int count) async {
    lastCount = count;
    calls++;
  }
}
