import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/device_registrar.dart';
import '../data/server_config.dart';
import '../data/token_store.dart';
import 'inbox_provider.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Base URL backend kampus.
///
/// Tidak di-hardcode supaya bisa diganti tanpa mengubah kode:
/// `flutter run --dart-define=API_BASE_URL=https://api.kampus.ac.id`
///
/// Nilai ini hanya **default awal**. Pengguna bisa menggantinya langsung dari
/// layar login, karena flag `--dart-define` sering tidak terbaca (salah
/// terminal, lupa rebuild) dan gejalanya sulit dibedakan dari "server mati".
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://example-campus-api.test',
);

/// Jalur mundur untuk demo saat backend belum tersedia.
///
/// Default `false`: build normal selalu memanggil API sungguhan. Aktifkan
/// hanya dengan `--dart-define=USE_MOCK_AUTH=true`.
const useMockAuth = bool.fromEnvironment('USE_MOCK_AUTH');

final serverConfigStoreProvider = Provider<ServerConfigStore>(
  (ref) => PrefsServerConfigStore(),
);

/// Alamat backend yang sedang dipakai.
///
/// Disimpan di perangkat, jadi pengguna cukup mengaturnya sekali lewat layar
/// login dan tidak perlu menjalankan ulang dengan flag tertentu.
final serverUrlProvider =
    NotifierProvider<ServerUrlNotifier, String>(ServerUrlNotifier.new);

class ServerUrlNotifier extends Notifier<String> {
  @override
  String build() => apiBaseUrl;

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
    state = apiBaseUrl;
    await ref.read(serverConfigStoreProvider).write('');
  }
}

/// Dio khusus untuk login dan refresh.
///
/// Dipisah dari [apiClientProvider] karena login tidak boleh memakai token
/// lama maupun interceptor refresh: kegagalan login harus muncul sebagai pesan
/// "kata sandi salah", bukan sebagai percobaan refresh yang menimpa sesi.
final authDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ref.watch(serverUrlProvider),
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
  dio.options.baseUrl = ref.watch(serverUrlProvider);
  return dio;
});

final deviceRegistrarProvider = Provider<DeviceRegistrar>((ref) {
  return HttpDeviceRegistrar(ref.watch(apiClientProvider));
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

/// Hasil tes koneksi ke backend, untuk ditampilkan di layar login.
typedef PingResult = ({bool ok, String detail});

/// Menembak `GET /health` untuk memisahkan masalah jaringan dari masalah
/// kredensial.
///
/// [dio] sebaiknya berasal dari [authDioProvider] yang juga dipakai login,
/// sehingga hasil tes mencerminkan jalur yang benar-benar dipakai.
Future<PingResult> pingApi(Dio dio, String baseUrl) async {
  final started = DateTime.now();
  try {
    final response = await dio.get<dynamic>('/health');
    final ms = DateTime.now().difference(started).inMilliseconds;
    if (response.statusCode == 200) {
      return (ok: true, detail: '$baseUrl menjawab 200 dalam ${ms}ms');
    }
    return (
      ok: false,
      detail: '$baseUrl menjawab ${response.statusCode}. '
          'Alamat benar tetapi bukan mock API yang diharapkan.',
    );
  } on DioException catch (error) {
    return (ok: false, detail: _explainDio(error, baseUrl));
  } catch (error) {
    return (ok: false, detail: 'Gagal menghubungi $baseUrl: $error');
  }
}

/// Penjelasan teknis yang bisa ditindaklanjuti, ditampilkan di bawah pesan
/// ramah. Pesan ramah saja tidak cukup saat yang salah adalah URL atau
/// firewall: pengguna hanya bisa menebak.
String describeAuthFailure(Object? error, String baseUrl) {
  if (error is AuthFailure) {
    return 'Server: $baseUrl';
  }
  if (error is DioException) {
    return _explainDio(error, baseUrl);
  }
  return 'Server: $baseUrl';
}

String _explainDio(DioException error, String baseUrl) {
  final status = error.response?.statusCode;
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return 'Tidak bisa terhubung ke $baseUrl. Periksa:\n'
          '• Alamat benar (emulator Android: 10.0.2.2, HP fisik: IP laptop)\n'
          '• Backend hidup dan port-nya terbuka\n'
          '• HP dan laptop di jaringan yang sama\n'
          '• Kalau memakai http:// (bukan https), manifest butuh '
          'android:usesCleartextTraffic="true"';
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '$baseUrl tidak menjawab dalam batas waktu. Server mungkin '
          'hidup tetapi diblokir firewall.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat HTTPS $baseUrl tidak valid. Untuk backend lokal, '
          'pakai http:// bukan https://.';
    case DioExceptionType.badResponse:
      if (status == 404) {
        return '$baseUrl menjawab 404. Alamat server benar, tetapi path '
            '/auth/login tidak ada. Periksa API_BASE_URL.';
      }
      if (status == 400 || status == 422) {
        return '$baseUrl menolak format permintaan (kode $status). '
            'Kemungkinan backend memakai nama field berbeda.';
      }
      if (status == 401 || status == 403) {
        return '$baseUrl menolak kredensial (kode $status). '
            'Periksa email dan kata sandi.';
      }
      return '$baseUrl menjawab kode $status.';
    case DioExceptionType.cancel:
      return 'Permintaan ke $baseUrl dibatalkan.';
    case DioExceptionType.transformTimeout:
      return '$baseUrl mengirim data tetapi gagal dibaca (timeout transformasi).';
  }
}

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
