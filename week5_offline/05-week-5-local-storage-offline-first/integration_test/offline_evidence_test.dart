import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_notes/main.dart' as app;

Future<void> host(String command) async {
  debugPrint('Evidence cache: ${Directory.systemTemp.path}, command: $command');
  final request = File('${Directory.systemTemp.path}/evidence-request');
  final ack = File('${Directory.systemTemp.path}/evidence-ack');
  if (await ack.exists()) await ack.delete();
  await request.writeAsString(command);
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    if (await ack.exists() && (await ack.readAsString()).trim() == command) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('Host did not acknowledge $command');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('CRUD, themes, SQLite cache, airplane and HTTP sync evidence', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    await host('online');

    await tester.tap(find.byTooltip('Posts (cache-first)'));
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await host('offline');
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Judul wajib diisi'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(0),
      'Praktikum saat mode pesawat',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Catatan ini disimpan ke SQLite tanpa jaringan.',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('belum tersinkron'), findsOneWidget);
    await host('capture:01-daftar-mode-pesawat');

    await tester.tap(find.text('Praktikum saat mode pesawat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(1),
      'Isi diperbarui saat mode pesawat, dirty tetap aktif.',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(
      find.text('Isi diperbarui saat mode pesawat, dirty tetap aktif.'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sinkronkan'));
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('belum tersinkron'), findsOneWidget);
    await host('capture:02-dirty-sebelum-sync');

    await tester.tap(find.byTooltip('Posts (cache-first)'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);
    await host('capture:03-bacaan-cache-offline');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tema gelap'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SwitchListTile).first)).brightness,
      Brightness.dark,
    );
    await host('capture:04-tema-gelap');
    await tester.tap(find.text('Tema gelap'));
    await tester.pumpAndSettle();
    await host('capture:05-tema-terang');
    await tester.tap(find.text('Paksa mode offline'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sinkronkan'));
    await tester.pumpAndSettle();
    expect(
      find.text('Perangkat offline, sinkronisasi ditunda.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paksa mode offline'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await host('online');
    await tester.tap(find.byTooltip('Sinkronkan'));
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('belum tersinkron'), findsNothing);
    await host('capture:06-dirty-sesudah-sync');

    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'Catatan untuk dihapus',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan untuk dihapus'), findsNothing);
    await tester.tap(find.byTooltip('Sinkronkan'));
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
