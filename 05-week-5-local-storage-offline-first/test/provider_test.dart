import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/data/local/note.dart';
import 'package:offline_notes/providers/note_providers.dart';
import 'fakes.dart';

void main() {
  test(
    'provider reads fake repository and reloads after local write',
    () async {
      final repo = FakeNoteRepository(
        notes: [Note(id: 1, title: 'Awal', updatedAt: DateTime.utc(2026))],
      );
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      expect((await container.read(notesProvider.future)).single.title, 'Awal');
      await container.read(noteActionsProvider).add('Baru', 'Tetap offline');
      expect((await container.read(notesProvider.future)).first.title, 'Baru');
      expect(await container.read(dirtyCountProvider.future), 1);
    },
  );
  test('provider surfaces repository error without automatic retry', () async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(failRead: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(notesProvider.future),
      throwsA(isA<StateError>()),
    );
  });
}
