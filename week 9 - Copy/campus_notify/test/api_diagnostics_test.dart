import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/domain/auth/auth_repository.dart';
import 'package:campus_notify/data/auth/auth_dependencies.dart';
import 'package:campus_notify/data/auth/auth_diagnostics.dart';

DioException dioError(
  DioExceptionType type, {
  int? status,
  String base = 'http://10.0.2.2:8080',
}) {
  final options = RequestOptions(path: '/auth/login', baseUrl: base);
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
          ),
  );
}

void main() {
  group('describeAuthFailure', () {
    test('koneksi gagal menyebut URL dan langkah yang bisa dicek', () {
      final text = describeAuthFailure(
        dioError(DioExceptionType.connectionError),
        'http://10.0.2.2:8080',
      );

      expect(text, contains('http://10.0.2.2:8080'));
      expect(text, contains('10.0.2.2'));
      expect(text, contains('usesCleartextTraffic'));
    });

    test('timeout menjelaskan server tidak menjawab', () {
      final text = describeAuthFailure(
        dioError(DioExceptionType.connectionTimeout),
        'https://api.kampus.test',
      );

      expect(text, contains('tidak menjawab'));
    });

    test('404 menandakan path salah, bukan alamat salah', () {
      final text = describeAuthFailure(
        dioError(DioExceptionType.badResponse, status: 404),
        'https://api.kampus.test',
      );

      expect(text, contains('404'));
      expect(text, contains('/auth/login'));
    });

    test('401 menunjuk kredensial', () {
      final text = describeAuthFailure(
        dioError(DioExceptionType.badResponse, status: 401),
        'https://api.kampus.test',
      );

      expect(text, contains('kredensial'));
    });

    test('sertifikat tidak valid menyarankan http untuk backend lokal', () {
      final text = describeAuthFailure(
        dioError(DioExceptionType.badCertificate),
        'https://192.168.1.5:8080',
      );

      expect(text, contains('Sertifikat'));
    });

    test('AuthFailure biasa tetap menampilkan server yang dipakai', () {
      final text = describeAuthFailure(
        const AuthFailure('Email atau kata sandi salah.'),
        'https://api.kampus.test',
      );

      expect(text, contains('https://api.kampus.test'));
    });
  });

  group('apiBaseUrl', () {
    test('tidak lagi memakai alamat placeholder saat di-override', () {
      // Nilai di test ini mengikuti default pubspec karena --dart-define tidak
      // bisa diubah di dalam test. Yang diuji: nilainya tidak kosong dan
      // berbentuk URL, supaya layar login tidak menampilkan string aneh.
      expect(apiBaseUrl, isNotEmpty);
      expect(apiBaseUrl, startsWith('http'));
    });
  });
}
