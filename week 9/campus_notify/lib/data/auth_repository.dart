import 'package:dio/dio.dart';

import 'api_errors.dart';

/// Pasangan token hasil login.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;

  /// Boleh kosong bila backend tidak menerbitkan refresh token. Interceptor di
  /// `api_client.dart` melewati proses refresh saat nilainya kosong.
  final String refresh;
}

/// Kegagalan login yang sudah siap ditampilkan ke pengguna.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cause});

  final String message;

  /// Error asli (mis. [DioException]) untuk diagnosis teknis di layar login.
  /// Tanpa ini, detail seperti "connection refused" hilang saat dibungkus.
  final Object? cause;

  /// Pesan polos tanpa awalan `Exception:` supaya bisa langsung ditampilkan.
  @override
  String toString() => message;
}

/// Kontrak autentikasi. Implementasi nyata ada di [HttpAuthRepository],
/// sedangkan [MockAuthRepository] dipakai untuk demo tanpa backend.
abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  /// Mengembalikan sesi baru. Bila server memutar refresh token (seperti mock
  /// API), [AuthSession.refresh] berisi token baru; bila tidak, token lama.
  Future<AuthSession> refresh(String refreshToken);
}

/// Login ke backend kampus lewat HTTP.
///
/// Kontrak yang dipakai:
/// - `POST {baseUrl}/auth/login` body `{"email": ..., "password": ...}`
/// - respons sukses: `{"access_token": "...", "refresh_token": "..."}`
/// - `POST {baseUrl}/auth/refresh` body `{"refresh_token": ...}`
///   respons: `{"access_token": "...", "refresh_token": "..."}` (refresh
///   token baru opsional)
///
/// Nama field juga diterima dalam bentuk camelCase (`accessToken`) maupun
/// `token` tunggal, supaya backend yang sedikit berbeda tidak memaksa aplikasi
/// diubah.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(
    this._dio, {
    this.loginPath = '/auth/login',
    this.refreshPath = '/auth/refresh',
  });

  final Dio _dio;
  final String loginPath;
  final String refreshPath;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      throw const AuthFailure('Email dan kata sandi wajib diisi.');
    }

    try {
      final response = await _dio.post<dynamic>(
        loginPath,
        data: {'email': trimmed, 'password': password},
      );
      final body = response.data;
      if (body is! Map) {
        throw const AuthFailure('Respons server tidak dikenali.');
      }

      final access = _firstString(body, const [
        'access_token',
        'accessToken',
        'token',
      ]);
      if (access == null || access.isEmpty) {
        throw const AuthFailure('Server tidak mengirim access token.');
      }
      final refresh = _firstString(body, const [
            'refresh_token',
            'refreshToken',
          ]) ??
          '';

      return AuthSession(access: access, refresh: refresh);
    } on DioException catch (error) {
      throw AuthFailure(_loginMessage(error), cause: error);
    }
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    if (refreshToken.isEmpty) {
      throw const AuthFailure('Sesi berakhir. Silakan masuk kembali.');
    }
    try {
      final response = await _dio.post<dynamic>(
        refreshPath,
        data: {'refresh_token': refreshToken},
      );
      final body = response.data;
      if (body is! Map) {
        throw const AuthFailure('Sesi berakhir. Silakan masuk kembali.');
      }
      final access =
          _firstString(body, const ['access_token', 'accessToken', 'token']);
      if (access == null || access.isEmpty) {
        throw const AuthFailure('Sesi berakhir. Silakan masuk kembali.');
      }
      // Server yang memutar refresh token langsung mencabut token lama, jadi
      // token baru wajib disimpan. Kalau tidak dikirim, token lama masih sah.
      final rotated = _firstString(body, const [
        'refresh_token',
        'refreshToken',
      ]);
      return AuthSession(access: access, refresh: rotated ?? refreshToken);
    } on DioException catch (error) {
      throw AuthFailure(mapDioException(error).message, cause: error);
    }
  }

  /// 401/403 saat login berarti kredensial salah, bukan "sesi berakhir".
  String _loginMessage(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Email atau kata sandi salah.';
    }
    if (status == 400 || status == 422) {
      return 'Format email atau kata sandi tidak diterima server.';
    }
    return mapDioException(error).message;
  }

  static String? _firstString(Map<dynamic, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

/// Autentikasi tiruan untuk demo tanpa backend.
///
/// Aktif hanya bila aplikasi dijalankan dengan
/// `--dart-define=USE_MOCK_AUTH=true`. Tidak pernah jadi jalur default, supaya
/// build rilis tidak diam-diam menerima kredensial palsu.
class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!email.contains('@') || password.length < 6) {
      throw const AuthFailure('Email atau kata sandi tidak valid');
    }
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    if (refreshToken.isEmpty) {
      throw const AuthFailure('Refresh token hilang');
    }
    return AuthSession(
      access: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
      refresh: refreshToken,
    );
  }
}
