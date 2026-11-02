
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
  final Object? cause;

  /// Pesan polos tanpa awalan `Exception:` supaya bisa langsung ditampilkan.
  @override
  String toString() => message;
}

/// Contract required by application authentication flows.
abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> refresh(String refreshToken);
}
