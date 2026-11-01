import '../routes.dart';

/// Mengubah `data` payload FCM menjadi rute internal.
///
/// Fungsi murni: tidak menyentuh Firebase, sehingga bisa diuji tanpa perangkat.
/// Payload yang tidak dikenal dikembalikan ke beranda, bukan diteruskan apa
/// adanya, supaya backend tidak bisa memaksa aplikasi membuka URL eksternal.
String routeFromMessage(Map<String, dynamic> data) {
  final value = data['route'];
  final raw = value is String ? value.trim() : '';
  if (raw.isEmpty) return Routes.home;

  // Tolak URL absolut dan protocol-relative (`//host/path`).
  if (raw.contains('://') || raw.startsWith('//')) return Routes.home;

  final route = raw.startsWith('/') ? raw : '/$raw';
  return Routes.isKnown(route) ? route : Routes.home;
}
