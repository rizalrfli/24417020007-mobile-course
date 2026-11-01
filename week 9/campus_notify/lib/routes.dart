/// Satu sumber kebenaran untuk path rute.
///
/// GoRouter, tombol di UI, dan deep link dari FCM memakai konstanta yang sama
/// supaya rute tidak pernah berbeda antar lapisan.
class Routes {
  const Routes._();

  static const home = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const inbox = '/notifikasi';
  static const announcementPattern = '/pengumuman/:id';
  static const announcementPrefix = '/pengumuman/';

  static String announcement(String id) => '$announcementPrefix$id';

  /// True hanya untuk rute yang benar-benar terdaftar di router.
  ///
  /// Dipakai sebelum menavigasi dari payload FCM, sehingga payload asing tidak
  /// membuang pengguna ke layar kosong.
  static bool isKnown(String route) {
    if (route == home) return true;
    if (route == login || route == splash) return false;
    return announcementId(route) != null;
  }

  /// Mengembalikan id pengumuman bila [route] berbentuk `/pengumuman/<id>`.
  static String? announcementId(String route) {
    if (!route.startsWith(announcementPrefix)) return null;
    final id = route.substring(announcementPrefix.length);
    if (id.isEmpty) return null;
    if (id.contains('/') || id.contains('..') || id.contains('?')) return null;
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) return null;
    return id;
  }
}
