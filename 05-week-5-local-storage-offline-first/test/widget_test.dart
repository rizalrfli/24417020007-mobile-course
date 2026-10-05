import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/data/local/note.dart';
import 'package:offline_notes/widgets/note_form_dialog.dart';
import 'package:offline_notes/widgets/note_tile.dart';

void main() {
  testWidgets(
    'form validates via keyboard and Escape closes dialog at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const NoteFormDialog(),
                ),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Judul wajib diisi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(NoteFormDialog), findsNothing);
    },
  );

  testWidgets('long dirty note fits narrow phone in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            colorSchemeSeed: Colors.indigo,
          ),
          home: Scaffold(
            body: NoteTile(
              note: Note(
                id: 1,
                title: 'Judul panjang catatan praktikum penyimpanan offline',
                body: 'Isi',
                updatedAt: DateTime.utc(2026),
                dirty: true,
              ),
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('belum tersinkron'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final style = tester.widget<Chip>(find.byType(Chip));
      final scheme = Theme.of(
        tester.element(find.byType(NoteTile)),
      ).colorScheme;
      final foreground = style.labelStyle!.color!;
      final background = style.backgroundColor!;
      final lum1 = foreground.computeLuminance();
      final lum2 = background.computeLuminance();
      final contrast =
          ((lum1 > lum2 ? lum1 : lum2) + .05) /
          ((lum1 < lum2 ? lum1 : lum2) + .05);
      expect(contrast, greaterThanOrEqualTo(4.5));
      expect(foreground, scheme.onErrorContainer);
    }
  });
}
