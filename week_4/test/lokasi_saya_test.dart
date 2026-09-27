import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_4/lokasi_saya.dart';
import 'package:week_4/main.dart';

void main() {
  const channel = MethodChannel('lyokone/location');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> calls;
  late int service;
  late int permission;

  setUp(() {
    calls = [];
    service = 1;
    permission = 1;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      switch (call.method) {
        case 'serviceEnabled':
        case 'requestService':
          return service;
        case 'hasPermission':
        case 'requestPermission':
          return permission;
        case 'getLocation':
          return {'latitude': -7.98, 'longitude': 112.63};
        default:
          throw PlatformException(code: 'UNEXPECTED_METHOD');
      }
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> openLocation(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LokasiSayaButton())),
    );
    await tester.tap(find.text('Lokasi saya'));
    await tester.pumpAndSettle();
  }

  testWidgets('Tombol lokasi di halaman utama menampilkan koordinat', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.byType(LokasiSayaButton));
    await tester.tap(find.text('Lokasi saya'));
    await tester.pumpAndSettle();
    expect(
      find.text('Latitude: -7.980000\nLongitude: 112.630000'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Lokasi saya'), findsOneWidget);
  });

  testWidgets('GPS mati tidak meminta koordinat', (tester) async {
    service = 0;
    await openLocation(tester);
    expect(find.textContaining('GPS belum aktif'), findsOneWidget);
    expect(calls, ['serviceEnabled', 'requestService']);
  });

  testWidgets('Izin ditolak tidak meminta koordinat', (tester) async {
    permission = 0;
    await openLocation(tester);
    expect(find.textContaining('Izin lokasi ditolak'), findsOneWidget);
    expect(calls, contains('requestPermission'));
    expect(calls, isNot(contains('getLocation')));
  });

  testWidgets('Izin diblokir mengarahkan pengguna ke pengaturan', (
    tester,
  ) async {
    permission = 2;
    await openLocation(tester);
    expect(find.textContaining('Izin lokasi diblokir'), findsOneWidget);
    expect(calls, isNot(contains('requestPermission')));
    expect(calls, isNot(contains('getLocation')));
  });

  testWidgets('Izin perkiraan lokasi tetap menampilkan koordinat', (
    tester,
  ) async {
    permission = 3;
    await openLocation(tester);
    expect(find.textContaining('Latitude: -7.980000'), findsOneWidget);
  });
}
