import 'package:dio/dio.dart';
import 'package:campus_notify/data/api_error_mapper.dart';
import 'package:campus_notify/domain/auth/auth_repository.dart';

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
      if (body is! Map) throw const AuthFailure('Respons server tidak dikenali.');
      final access = _firstString(body, const ['access_token', 'accessToken', 'token']);
      if (access == null) throw const AuthFailure('Server tidak mengirim access token.');
      final refresh = _firstString(body, const ['refresh_token', 'refreshToken']) ?? '';
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
      if (body is! Map) throw const AuthFailure('Sesi berakhir. Silakan masuk kembali.');
      final access = _firstString(body, const ['access_token', 'accessToken', 'token']);
      if (access == null) throw const AuthFailure('Sesi berakhir. Silakan masuk kembali.');
      final refresh = _firstString(body, const ['refresh_token', 'refreshToken']) ?? refreshToken;
      return AuthSession(access: access, refresh: refresh);
    } on DioException catch (error) {
      throw AuthFailure(mapDioException(error).message, cause: error);
    }
  }

  String _loginMessage(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) return 'Email atau kata sandi salah.';
    if (status == 400 || status == 422) {
      return 'Format email atau kata sandi tidak diterima server.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi lambat. Coba lagi sebentar.';
    }
    return mapDioException(error).message;
  }

  String? _firstString(Map<dynamic, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!email.contains('@') || password.length < 6) {
      throw const AuthFailure('Email atau kata sandi tidak valid');
    }
    return AuthSession(access: 'mock-access-for-$email', refresh: 'mock-refresh-for-$email');
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    if (refreshToken.isEmpty) throw const AuthFailure('Refresh token hilang');
    return AuthSession(
      access: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
      refresh: refreshToken,
    );
  }
}


