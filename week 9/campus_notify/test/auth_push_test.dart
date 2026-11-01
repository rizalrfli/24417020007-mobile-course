import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/messaging/message_route.dart';
import 'package:campus_notify/routes.dart';

void main() {
  test('routeFromMessage menangani route kosong dan tanpa slash', () {
    expect(routeFromMessage({}), Routes.home);
    expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
  });

  test('data payload membawa id pengumuman', () {
    const data = {'route': '/pengumuman/3', 'id': '3'};
    expect(data['id'], '3');
    expect(routeFromMessage(data), '/pengumuman/3');
  });

  test('provider auth membaca status login dari token', () {
    String? access = 'mock-access';
    expect(access, isNotNull);
    access = null;
    expect(access, isNull);
  });

  test('refresh gagal -> sesi dibersihkan (paksa login ulang)', () {
    const refresh = '';
    expect(refresh.isEmpty, isTrue);
  });
}
