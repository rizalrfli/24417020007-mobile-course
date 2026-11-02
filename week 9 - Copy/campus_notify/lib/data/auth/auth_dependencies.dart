import 'package:dio/dio.dart';

import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/auth/server_config.dart';
import 'package:campus_notify/domain/auth/auth_repository.dart';
import 'package:campus_notify/data/auth/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/data/push/device_registrar.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

const useMockAuth = bool.fromEnvironment('USE_MOCK_AUTH');


/// Dio constructors and external adapters are kept in data, not widgets.
class AuthDependencies {
  const AuthDependencies._();

  static const baseUrl = apiBaseUrl;
  static const mockAuthEnabled = useMockAuth;

  static Dio createAuthDio(String baseUrl) => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  static AuthRepository createRepository(Dio dio) => useMockAuth
      ? const MockAuthRepository()
      : HttpAuthRepository(dio);

  static Dio createApiClient(TokenStore store, AuthRepository repository,
      String baseUrl) {
    final dio = buildApiClient(store, repository);
    dio.options.baseUrl = baseUrl;
    return dio;
  }

  static DeviceRegistrar createDeviceRegistrar(Dio dio) =>
      HttpDeviceRegistrar(dio);

  static ServerConfigStore createServerConfigStore() =>
      PrefsServerConfigStore();
}
