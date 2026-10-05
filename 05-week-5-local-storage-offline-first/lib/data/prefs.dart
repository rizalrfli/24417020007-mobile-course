import 'package:shared_preferences/shared_preferences.dart';

class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(_darkModeKey, value)) {
      throw StateError('Gagal menyimpan tema');
    }
  }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _lastOpenedKey,
      DateTime.now().toUtc().toIso8601String(),
    )) {
      throw StateError('Gagal menyimpan waktu buka');
    }
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }
}
