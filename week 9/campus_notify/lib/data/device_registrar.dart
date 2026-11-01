import 'package:dio/dio.dart';

import 'api_errors.dart';

/// Pengiriman registration token ke backend.
///
/// Antarmuka dipisah dari HTTP agar bisa diganti fake di unit test dan agar
/// layar Debug bisa melaporkan hasil nyata, bukan asumsi "berhasil".
abstract class DeviceRegistrar {
  Future<void> register(String token);
}

class HttpDeviceRegistrar implements DeviceRegistrar {
  HttpDeviceRegistrar(this._dio, {this.path = '/devices'});

  final Dio _dio;
  final String path;

  @override
  Future<void> register(String token) async {
    try {
      await _dio.post(
        path,
        data: {'fcm_token': token, 'platform': 'android'},
      );
    } on DioException catch (error) {
      throw ApiFailure(
        mapDioException(error).message,
        isRetryable: mapDioException(error).isRetryable,
      );
    }
  }
}
