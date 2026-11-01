import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'; // ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/data/api_client.dart';

/// `TokenStore` asli di atas platform secure storage palsu di memori, sehingga
/// logika refresh token diuji tanpa platform channel Android/iOS.
TokenStore memoryStore(Map<String, String> data) {
  FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(data);
  return TokenStore(storage: const FlutterSecureStorage());
}

class FailingAuthRepository extends AuthRepository {
  @override
  Future<String> refresh(String refreshToken) async {
    throw Exception('refresh kedaluwarsa');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TokenStore', () {
    test('menyimpan dan menghapus kedua token', () async {
      final store = memoryStore({});
      await store.save(access: 'access-1', refresh: 'refresh-1');
      expect(await store.readAccess(), 'access-1');
      expect(await store.readRefresh(), 'refresh-1');

      await store.clear();
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    });

    test('sesi tanpa token berarti harus login', () async {
      final store = memoryStore({});
      expect(await store.readAccess(), isNull);
    });
  });

  group('AuthRepository', () {
    test('login menolak email tanpa @ dan kata sandi pendek', () async {
      final auth = AuthRepository();
      expect(
        () => auth.login(email: 'tanpa-at', password: 'rahasia1'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => auth.login(email: 'mhs@polinema.ac.id', password: '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('login valid mengembalikan pasangan access dan refresh', () async {
      final session = await AuthRepository()
          .login(email: 'mhs@polinema.ac.id', password: 'rahasia1');
      expect(session.access, isNotEmpty);
      expect(session.refresh, isNotEmpty);
    });

    test('refresh token kosong ditolak', () async {
      expect(() => AuthRepository().refresh(''), throwsA(isA<Exception>()));
    });
  });

  group('Interceptor refresh 401', () {
    late Map<String, String> data;
    late TokenStore store;
    late Dio dio;
    late int deviceCalls;

    setUp(() {
      data = {};
      store = memoryStore(data);
      deviceCalls = 0;
      dio = buildApiClient(store, AuthRepository());
    });

    test('401 memicu refresh sekali lalu mengulang request dengan token baru',
        () async {
      await store.save(access: 'access-lama', refresh: 'refresh-valid');
      dio.httpClientAdapter = _FakeAdapter((options) {
        deviceCalls++;
        final auth = options.headers['Authorization'];
        return _response(options, auth == 'Bearer access-lama' ? 401 : 200);
      });

      final response = await dio.post('/devices', data: {'fcm_token': 't'});

      expect(response.statusCode, 200);
      expect(deviceCalls, 2, reason: 'request awal + satu retry');
      expect(await store.readAccess(), startsWith('mock-access-renewed-'));
      expect(await store.readRefresh(), 'refresh-valid');
    });

    test('refresh gagal membersihkan sesi supaya pengguna login ulang', () async {
      await store.save(access: 'access-lama', refresh: 'refresh-valid');
      final failing = buildApiClient(store, FailingAuthRepository());
      failing.httpClientAdapter = _FakeAdapter((options) => _response(options, 401));

      await expectLater(
        failing.post('/devices', data: {'fcm_token': 't'}),
        throwsA(isA<DioException>()),
      );
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    });

    test('tanpa refresh token request tidak diulang', () async {
      await store.save(access: 'access-lama', refresh: '');
      dio.httpClientAdapter = _FakeAdapter((options) {
        deviceCalls++;
        return _response(options, 401);
      });

      await expectLater(
        dio.post('/devices', data: {'fcm_token': 't'}),
        throwsA(isA<DioException>()),
      );
      expect(deviceCalls, 1);
    });
  });
}

ResponseBody _response(RequestOptions options, int status) {
  return ResponseBody.fromString(
    '{}',
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.onRequest);

  final ResponseBody Function(RequestOptions) onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      onRequest(options);

  @override
  void close({bool force = false}) {}
}
