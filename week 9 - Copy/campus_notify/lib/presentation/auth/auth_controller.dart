import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/data/push/device_registrar.dart';
import 'package:campus_notify/domain/auth/auth_repository.dart';

import 'package:campus_notify/data/auth/server_config.dart';
import 'package:campus_notify/data/auth/auth_dependencies.dart';
import 'package:campus_notify/presentation/inbox/inbox_controller.dart';

/// Base URL backend kampus.
///
/// Tidak di-hardcode supaya bisa diganti tanpa mengubah kode:
/// `flutter run --dart-define=API_BASE_URL=https://api.kampus.ac.id`
///
/// Nilai ini hanya **default awal**. Pengguna bisa menggantinya langsung dari
/// layar login, karena flag `--dart-define` sering tidak terbaca (salah
/// terminal, lupa rebuild) dan gejalanya sulit dibedakan dari "server mati".
final serverConfigStoreProvider = Provider<ServerConfigStore>(
  (ref) => AuthDependencies.createServerConfigStore(),
);

/// Alamat backend yang sedang dipakai.
///
/// Disimpan di perangkat, jadi pengguna cukup mengaturnya sekali lewat layar
/// login dan tidak perlu menjalankan ulang dengan flag tertentu.
final serverUrlProvider =
    NotifierProvider<ServerUrlNotifier, String>(ServerUrlNotifier.new);

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final authDioProvider = Provider<Dio>(
  (ref) => AuthDependencies.createAuthDio(ref.watch(serverUrlProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthDependencies.createRepository(ref.watch(authDioProvider)),
);

final apiClientProvider = Provider<Dio>((ref) => AuthDependencies.createApiClient(
      ref.watch(tokenStoreProvider),
      ref.watch(authRepositoryProvider),
      ref.watch(serverUrlProvider),
    ));

final deviceRegistrarProvider = Provider<DeviceRegistrar>(
  (ref) => AuthDependencies.createDeviceRegistrar(ref.watch(apiClientProvider)),
);

class ServerUrlNotifier extends Notifier<String> {
  @override
  String build() => AuthDependencies.baseUrl;

  /// Membaca alamat tersimpan. Dipanggil sekali saat aplikasi mulai.
  Future<void> load() async {
    final saved = await ref.read(serverConfigStoreProvider).read();
    if (saved != null && saved.isNotEmpty) state = saved;
  }

  /// Menyimpan alamat baru. Mengembalikan false bila formatnya tidak sah.
  Future<bool> save(String raw) async {
    final normalized = normalizeServerUrl(raw);
    if (normalized == null) return false;
    state = normalized;
    await ref.read(serverConfigStoreProvider).write(normalized);
    return true;
  }

  /// Kembali ke alamat dari `--dart-define`.
  Future<void> reset() async {
    state = AuthDependencies.baseUrl;
    await ref.read(serverConfigStoreProvider).write('');
  }
}

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
