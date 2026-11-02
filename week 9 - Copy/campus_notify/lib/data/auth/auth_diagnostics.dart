import 'package:dio/dio.dart';
import 'package:campus_notify/domain/auth/auth_repository.dart';

typedef PingResult = ({bool ok, String detail});

Future<PingResult> pingApi(Dio dio, String baseUrl) async {
  final started = DateTime.now();
  try {
    final response = await dio.get<dynamic>('/health');
    final ms = DateTime.now().difference(started).inMilliseconds;
    if (response.statusCode == 200) {
      return (ok: true, detail: '$baseUrl menjawab 200 dalam ${ms}ms');
    }
    return (ok: false, detail: '$baseUrl menjawab ${response.statusCode}. '
        'Alamat benar tetapi bukan mock API yang diharapkan.');
  } on DioException catch (error) {
    return (ok: false, detail: _explainDio(error, baseUrl));
  } catch (error) {
    return (ok: false, detail: 'Gagal menghubungi $baseUrl: $error');
  }
}

String describeAuthFailure(Object? error, String baseUrl) {
  if (error is AuthFailure && error.cause is DioException) {
    return _explainDio(error.cause! as DioException, baseUrl);
  }
  if (error is DioException) return _explainDio(error, baseUrl);
  return 'Server: $baseUrl';
}

String _explainDio(DioException error, String baseUrl) {
  final status = error.response?.statusCode;
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return 'Tidak bisa terhubung ke $baseUrl. Periksa alamat benar, backend '
          'hidup, port terbuka, jaringan sama, dan AndroidManifest.xml '
          'memiliki android:usesCleartextTraffic="true" untuk http://.';
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
