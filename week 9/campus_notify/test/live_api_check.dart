import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/device_registrar.dart';

/// Uji integrasi terhadap mock API yang benar-benar berjalan.
///
/// Nama berkas sengaja TIDAK berakhiran `_test.dart` supaya `flutter test`
/// biasa tidak ikut menjalankannya (butuh server hidup). Jalankan eksplisit:
///
///   node tools/mock-api/server.js &
///   flutter test test/live_api_check.dart
///
/// Alamat server bisa diganti lewat --dart-define=MOCK_API_URL=...
const baseUrl = String.fromEnvironment(
  'MOCK_API_URL',
  defaultValue: 'http://127.0.0.1:8080',
);

Dio buildDio({String url = baseUrl, int detik = 5}) => Dio(
  BaseOptions(
    baseUrl: url,
    connectTimeout: Duration(seconds: detik),
    receiveTimeout: Duration(seconds: detik),
  ),
);

Future<bool> serverHidup() async {
  try {
    final response = await buildDio(detik: 2).get<dynamic>('/health');
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // `flutter_test` memasang `HttpOverrides` yang membalas HTTP 400 untuk
    // SEMUA request, supaya unit test tidak diam-diam menembak jaringan
    // sungguhan. Untuk uji integrasi ini penjaga itu harus dilepas; tanpa
    // baris ini test terlihat lulus padahal tidak pernah menghubungi server.
    HttpOverrides.global = null;

    if (!await serverHidup()) {
      // Gagal keras, bukan dilewati diam-diam: hasil "lulus" tanpa pernah
      // menghubungi server adalah bukti palsu.
      fail(
        'Mock API tidak berjalan di $baseUrl.\n'
        'Jalankan dulu: node tools/mock-api/server.js',
      );
    }
  });

  test('login lewat HTTP ke mock API berhasil', () async {
    final session = await HttpAuthRepository(
      buildDio(),
    ).login(email: 'mhs@polinema.ac.id', password: 'rahasia1');

    expect(session.access, isNotEmpty);
    expect(session.refresh, isNotEmpty);
  });

  test('password salah ditolak dengan pesan yang ramah', () async {
    await expectLater(
      HttpAuthRepository(
        buildDio(),
      ).login(email: 'mhs@polinema.ac.id', password: 'salah'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.message,
          'message',
          'Email atau kata sandi salah.',
        ),
      ),
    );
  });

  test('refresh token mengembalikan access token baru', () async {
    final auth = HttpAuthRepository(buildDio());
    final session = await auth.login(
      email: 'mhs@polinema.ac.id',
      password: 'rahasia1',
    );

    final renewed = await auth.refresh(session.refresh);

    expect(renewed.access, isNotEmpty);
    expect(renewed.access, isNot(session.access));
    // Mock API memutar refresh token, jadi token baru harus berbeda.
    expect(renewed.refresh, isNot(session.refresh));
  });

  test('POST /devices memakai Bearer token dari login', () async {
    final session = await HttpAuthRepository(
      buildDio(),
    ).login(email: 'mhs@polinema.ac.id', password: 'rahasia1');

    final api = buildDio();
    api.options.headers['Authorization'] = 'Bearer ${session.access}';

    await HttpDeviceRegistrar(api).register('token-uji-dari-dart-123456');

    final daftar = await api.get<dynamic>('/devices');
    final tokens = (daftar.data['devices'] as List).map(
      (entry) => entry['fcm_token_prefix'],
    );
    expect(tokens, contains('token-uji-da...'));
  });

  test('tanpa token, /devices ditolak 401', () async {
    final api = buildDio();
    await expectLater(
      api.get<dynamic>('/devices'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
  });

  test('server yang mati menghasilkan pesan koneksi', () async {
    final auth = HttpAuthRepository(
      buildDio(
        // Port tinggi yang tidak ada yang mendengarkan. Port 9 sengaja
        // dihindari: sebagian lingkungan jaringan memperlakukannya sebagai
        // port "discard" dan membalas HTTP 400, bukan menolak koneksi.
        url: 'http://127.0.0.1:65500',
        detik: 2,
      ),
    );

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
}
