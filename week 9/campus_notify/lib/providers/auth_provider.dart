import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/device_registrar.dart';
import '../data/token_store.dart';
import 'inbox_provider.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Base URL backend kampus.
///
/// Tidak di-hardcode supaya bisa diganti tanpa mengubah kode:
/// `flutter run --dart-define=API_BASE_URL=https://api.kampus.ac.id`
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://example-campus-api.test',
);

/// Jalur mundur untuk demo saat backend belum tersedia.
///
/// Default `false`: build normal selalu memanggil API sungguhan. Aktifkan
/// hanya dengan `--dart-define=USE_MOCK_AUTH=true`.
const useMockAuth = bool.fromEnvironment('USE_MOCK_AUTH');

/// Dio khusus untuk login dan refresh.
///
/// Dipisah dari [apiClientProvider] karena login tidak boleh memakai token
/// lama maupun interceptor refresh: kegagalan login harus muncul sebagai pesan
/// "kata sandi salah", bukan sebagai percobaan refresh yang menimpa sesi.
final authDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMockAuth) return const MockAuthRepository();
  return HttpAuthRepository(ref.watch(authDioProvider));
});

final apiClientProvider = Provider<Dio>((ref) {
  final dio = buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
  dio.options.baseUrl = apiBaseUrl;
  return dio;
});

final deviceRegistrarProvider = Provider<DeviceRegistrar>((ref) {
  return HttpDeviceRegistrar(ref.watch(apiClientProvider));
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  /// Melempar [AuthFailure] bila login gagal; pemanggil menampilkan pesannya.
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    // Pengumuman milik sesi sebelumnya tidak boleh tetap terlihat oleh
    // pengguna lain di perangkat yang sama.
    await ref.read(inboxProvider.notifier).clearAll();
    ref.invalidateSelf();
  }
}
