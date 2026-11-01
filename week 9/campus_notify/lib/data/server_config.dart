import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan alamat backend.
///
/// Dipisah dari provider supaya logika normalisasi alamat bisa diuji tanpa
/// platform channel.
abstract class ServerConfigStore {
  Future<String?> read();
  Future<void> write(String url);
}

class PrefsServerConfigStore implements ServerConfigStore {
  static const storageKey = 'api_base_url_v1';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(storageKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Future<void> write(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, url);
  }
}

class MemoryServerConfigStore implements ServerConfigStore {
  MemoryServerConfigStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String url) async => value = url;
}

/// Menormalkan alamat yang diketik pengguna.
///
/// Mengembalikan null bila alamatnya tidak bisa dipakai. Tanpa normalisasi,
/// kesalahan kecil seperti spasi di ujung atau garis miring penutup membuat
/// path menjadi `//auth/login` dan server menjawab 404.
///
/// Contoh:
/// - `10.0.2.2:8080`        -> `http://10.0.2.2:8080`
/// - `https://a.test/`     -> `https://a.test`
/// - `  http://a.test  `   -> `http://a.test`
/// - `ftp://a.test`        -> null
/// - `''`                  -> null
String? normalizeServerUrl(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  // Tanpa skema, anggap http: backend lokal untuk belajar hampir selalu http.
  if (!text.contains('://')) text = 'http://$text';

  final uri = Uri.tryParse(text);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;

  // Buang garis miring di ujung; path lain (mis. /api) dipertahankan.
  final trimmed = text.replaceAll(RegExp(r'/+$'), '');
  return trimmed.isEmpty ? null : trimmed;
}

/// Alamat yang dipakai kalau pengguna belum pernah menyimpan apa pun.
///
/// `true` bila masih alamat contoh dari kode, dipakai untuk memperingatkan
/// pengguna di layar login.
bool isPlaceholderUrl(String url) {
  return url.contains('example-campus-api.test');
}
