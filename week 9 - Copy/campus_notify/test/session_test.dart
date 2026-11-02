import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'; // ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/domain/auth/auth_repository.dart';
import 'package:campus_notify/data/auth/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';

/// `TokenStore` asli di atas platform secure storage palsu di memori, sehingga
/// logika refresh token diuji tanpa platform channel Android/iOS.
TokenStore memoryStore(Map<String, String> data) {
  FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
    data,
  );
  return TokenStore(storage: const FlutterSecureStorage());
}

class FailingAuthRepository extends MockAuthRepository {
  const FailingAuthRepository();

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    throw const AuthFailure('refresh kedaluwarsa');
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

  group('MockAuthRepository (mode demo)', () {
    test('login menolak email tanpa @ dan kata sandi pendek', () async {
      const auth = MockAuthRepository();
      expect(
        () => auth.login(email: 'tanpa-at', password: 'rahasia1'),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => auth.login(email: 'mhs@polinema.ac.id', password: '123'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('login valid mengembalikan pasangan access dan refresh', () async {
      final session = await const MockAuthRepository().login(
        email: 'mhs@polinema.ac.id',
        password: 'rahasia1',
      );
      expect(session.access, isNotEmpty);
      expect(session.refresh, isNotEmpty);
    });

    test('refresh token kosong ditolak', () async {
      expect(
        () => const MockAuthRepository().refresh(''),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('HttpAuthRepository (login lewat API)', () {
    late Dio dio;
    late HttpAuthRepository auth;
    late List<RequestOptions> requests;

    setUp(() {
      requests = [];
      dio = Dio(BaseOptions(baseUrl: 'https://api.kampus.test'));
      auth = HttpAuthRepository(dio);
    });

    void reply(int status, String body) {
      dio.httpClientAdapter = _FakeAdapter((options) {
        requests.add(options);
        return _response(options, status, body);
      });
    }

    test('mengirim email dan password ke /auth/login', () async {
      reply(200, '{"access_token":"a1","refresh_token":"r1"}');

      final session = await auth.login(
        email: '  mhs@polinema.ac.id ',
        password: 'rahasia1',
      );

      expect(session.access, 'a1');
      expect(session.refresh, 'r1');
      expect(requests.single.path, '/auth/login');
      expect(requests.single.method, 'POST');
      expect(requests.single.data, {
        'email': 'mhs@polinema.ac.id',
        'password': 'rahasia1',
      });
    });

    test('menerima nama field camelCase dan tanpa refresh token', () async {
      reply(200, '{"accessToken":"a2"}');

      final session = await auth.login(
        email: 'mhs@polinema.ac.id',
        password: 'rahasia1',
      );

      expect(session.access, 'a2');
      expect(session.refresh, isEmpty);
    });

    test('401 berarti kredensial salah, bukan sesi berakhir', () async {
      reply(401, '{"message":"invalid"}');

      await expectLater(
        auth.login(email: 'mhs@polinema.ac.id', password: 'salah'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            'Email atau kata sandi salah.',
          ),
        ),
      );
    });

    test('respons tanpa access token ditolak', () async {
      reply(200, '{"refresh_token":"r1"}');

      await expectLater(
        auth.login(email: 'mhs@polinema.ac.id', password: 'rahasia1'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('email atau kata sandi kosong tidak dikirim ke server', () async {
      reply(200, '{"access_token":"a1"}');

      await expectLater(
        auth.login(email: '   ', password: 'rahasia1'),
        throwsA(isA<AuthFailure>()),
      );
      expect(requests, isEmpty);
    });

    test('server mati menghasilkan pesan yang bisa ditampilkan', () async {
      dio.httpClientAdapter = _FakeAdapter((options) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'unreachable',
        );
      });

      await expectLater(
        auth.login(email: 'mhs@polinema.ac.id', password: 'rahasia1'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            contains('koneksi'),
          ),
        ),
      );
    });

    test(
      'refresh mengirim refresh token dan mengembalikan access baru',
      () async {
        reply(200, '{"access_token":"a9"}');

        final renewed = await auth.refresh('r1');

        expect(renewed.access, 'a9');
        expect(renewed.refresh, 'r1', reason: 'server tidak memutar token');
        expect(requests.single.path, '/auth/refresh');
        expect(requests.single.data, {'refresh_token': 'r1'});
      },
    );
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
      dio = buildApiClient(store, const MockAuthRepository());
    });

    test(
      '401 memicu refresh sekali lalu mengulang request dengan token baru',
      () async {
        await store.save(access: 'access-lama', refresh: 'refresh-valid');
        dio.httpClientAdapter = _FakeAdapter((options) {
          deviceCalls++;
          final auth = options.headers['Authorization'];
          return _response(
            options,
            auth == 'Bearer access-lama' ? 401 : 200,
            '{}',
          );
        });

        final response = await dio.post('/devices', data: {'fcm_token': 't'});

        expect(response.statusCode, 200);
        expect(deviceCalls, 2, reason: 'request awal + satu retry');
        expect(await store.readAccess(), startsWith('mock-access-renewed-'));
        expect(await store.readRefresh(), 'refresh-valid');
      },
    );

    test(
      'refresh gagal membersihkan sesi supaya pengguna login ulang',
      () async {
        await store.save(access: 'access-lama', refresh: 'refresh-valid');
        final failing = buildApiClient(store, const FailingAuthRepository());
        failing.httpClientAdapter = _FakeAdapter(
          (options) => _response(options, 401, '{}'),
        );

        await expectLater(
          failing.post('/devices', data: {'fcm_token': 't'}),
          throwsA(isA<DioException>()),
        );
        expect(await store.readAccess(), isNull);
        expect(await store.readRefresh(), isNull);
      },
    );

    test('tanpa refresh token request tidak diulang', () async {
      await store.save(access: 'access-lama', refresh: '');
      dio.httpClientAdapter = _FakeAdapter((options) {
        deviceCalls++;
        return _response(options, 401, '{}');
      });

      await expectLater(
        dio.post('/devices', data: {'fcm_token': 't'}),
        throwsA(isA<DioException>()),
      );
      expect(deviceCalls, 1);
    });
  });
}

ResponseBody _response(RequestOptions options, int status, String body) {
  return ResponseBody.fromString(
    body,
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
  ) async => onRequest(options);

  @override
  void close({bool force = false}) {}
}
