import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/data/api_error_mapper.dart';
import 'package:campus_notify/domain/push/message_route.dart';
import 'package:campus_notify/presentation/routes.dart';

void main() {
  group('routeFromMessage', () {
    test('payload kosong jatuh ke beranda', () {
      expect(routeFromMessage({}), Routes.home);
      expect(routeFromMessage({'route': ''}), Routes.home);
      expect(routeFromMessage({'route': '   '}), Routes.home);
    });

    test('menambah slash di depan bila payload tidak memakainya', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('data payload membawa id pengumuman', () {
      final data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(Routes.announcementId(routeFromMessage(data)), '3');
    });

    test('URL eksternal tidak boleh dipakai sebagai rute', () {
      expect(
        routeFromMessage({'route': 'https://jahat.example/login'}),
        Routes.home,
      );
      expect(routeFromMessage({'route': '//jahat.example'}), Routes.home);
    });

    test('rute yang tidak terdaftar di router dikembalikan ke beranda', () {
      expect(routeFromMessage({'route': '/admin/rahasia'}), Routes.home);
      expect(routeFromMessage({'route': '/pengumuman/../login'}), Routes.home);
      expect(routeFromMessage({'route': '/login'}), Routes.home);
    });

    test('nilai route yang bukan String tidak membuat crash', () {
      expect(routeFromMessage({'route': 42}), Routes.home);
      expect(routeFromMessage({'route': null}), Routes.home);
    });
  });

  group('Routes', () {
    test('announcementId hanya menerima satu segmen id yang aman', () {
      expect(Routes.announcementId('/pengumuman/3'), '3');
      expect(Routes.announcementId('/pengumuman/uas-2026'), 'uas-2026');
      expect(Routes.announcementId('/pengumuman/'), isNull);
      expect(Routes.announcementId('/pengumuman/3/edit'), isNull);
      expect(Routes.announcementId('/pengumuman/3?tab=1'), isNull);
      expect(Routes.announcementId('/lain/3'), isNull);
    });

    test('announcement dan announcementId konsisten', () {
      expect(Routes.announcement('7'), '/pengumuman/7');
      expect(Routes.announcementId(Routes.announcement('7')), '7');
    });
  });

  group('mapDioException', () {
    DioException error(DioExceptionType type, {int? status}) {
      return DioException(
        requestOptions: RequestOptions(path: '/devices'),
        type: type,
        response: status == null
            ? null
            : Response(requestOptions: RequestOptions(path: '/devices'), statusCode: status),
      );
    }

    test('timeout dan offline bisa diulang', () {
      expect(mapDioException(error(DioExceptionType.connectionTimeout)).isRetryable, isTrue);
      expect(mapDioException(error(DioExceptionType.connectionError)).isRetryable, isTrue);
    });

    test('401 meminta login ulang tanpa menampilkan exception mentah', () {
      final failure = mapDioException(error(DioExceptionType.badResponse, status: 401));
      expect(failure.isRetryable, isFalse);
      expect(failure.message, contains('masuk kembali'));
    });

    test('5xx dianggap gangguan sementara', () {
      final failure = mapDioException(error(DioExceptionType.badResponse, status: 503));
      expect(failure.isRetryable, isTrue);
      expect(failure.message, contains('Server'));
    });
  });
}
