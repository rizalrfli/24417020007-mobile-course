import 'package:dio/dio.dart';

/// Pesan siap tampil untuk pengguna.
///
/// UI hanya menerima [message] dan [isRetryable], bukan [DioException] mentah.
class ApiFailure {
  const ApiFailure(this.message, {this.isRetryable = false});

  final String message;

  /// True bila mengulang aksi yang sama masuk akal (jaringan/timeout/server).
  final bool isRetryable;
}

ApiFailure mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ApiFailure(
        'Koneksi lambat. Coba lagi sebentar.',
        isRetryable: true,
      );
    case DioExceptionType.connectionError:
      return const ApiFailure(
        'Tidak ada koneksi internet. Periksa jaringan Anda.',
        isRetryable: true,
      );
    case DioExceptionType.badCertificate:
      return const ApiFailure('Sertifikat server tidak valid.');
    case DioExceptionType.cancel:
      return const ApiFailure('Permintaan dibatalkan.');
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode ?? 0;
      if (status == 401) {
        return const ApiFailure('Sesi berakhir. Silakan masuk kembali.');
      }
      if (status == 403) {
        return const ApiFailure('Akun ini tidak punya akses ke data tersebut.');
      }
      if (status == 404) {
        return const ApiFailure('Data yang diminta tidak ditemukan.');
      }
      if (status >= 500) {
        return const ApiFailure(
          'Server kampus sedang bermasalah. Coba lagi nanti.',
          isRetryable: true,
        );
      }
      return ApiFailure('Permintaan ditolak (kode $status).');
    case DioExceptionType.transformTimeout:
    case DioExceptionType.unknown:
      return const ApiFailure(
        'Gagal menghubungi server. Periksa jaringan Anda.',
        isRetryable: true,
      );
  }
}
