import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_4/camera.dart';
import 'package:week_4/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/camera');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('Buka kamera tanpa perangkat, coba lagi, lalu kembali', (
    tester,
  ) async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'availableCameras') {
        attempts++;
        return <Object>[];
      }
      return null;
    });
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Buka kamera'));
    await tester.tap(find.text('Buka kamera'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada kamera pada perangkat ini.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CameraApp), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Penolakan izin menampilkan petunjuk pengaturan', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'CameraAccessDenied');
    });
    await tester.pumpWidget(const MaterialApp(home: CameraApp()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Izin kamera ditolak'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keluar saat kamera dimuat tidak memperbarui halaman tertutup', (
    tester,
  ) async {
    final pending = Completer<List<Object>>();
    messenger.setMockMethodCallHandler(channel, (call) => pending.future);
    await tester.pumpWidget(const MaterialApp(home: CameraApp()));
    await tester.pump();
    expect(find.text('Membuka kamera...'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
