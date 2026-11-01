import 'dart:convert';

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

/// Payload notifikasi lokal: id dan rute dalam satu string.
///
/// `flutter_local_notifications` hanya menyimpan satu string payload, tetapi
/// saat banner diklik aplikasi perlu tahu notifikasi mana yang harus dihapus
/// dari daftar. JSON dipakai supaya id dan rute tidak saling menempel.
String encodeNotificationPayload({required String id, required String route}) {
  return jsonEncode({'id': id, 'route': route});
}

/// Membaca kembali payload dari [encodeNotificationPayload].
///
/// Payload lama (hanya berisi rute mentah) tetap diterima agar notifikasi yang
/// sudah ada di tray sebelum pembaruan tidak membuat aplikasi gagal membuka
/// halaman.
({String? id, String route}) decodeNotificationPayload(String payload) {
  final raw = payload.trim();
  if (raw.isEmpty) return (id: null, route: Routes.home);

  if (raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final route = routeFromMessage({
          'route': decoded['route']?.toString() ?? '',
        });
        final id = decoded['id']?.toString();
        return (id: (id == null || id.isEmpty) ? null : id, route: route);
      }
    } on FormatException {
      // Bukan JSON yang valid; diperlakukan sebagai rute mentah di bawah.
    }
  }

  return (id: null, route: routeFromMessage({'route': raw}));
}
