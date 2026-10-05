import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:offline_notes/data/local/note.dart';
import 'package:offline_notes/data/repositories/note_repository.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late NoteRepository repo;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT NULL, updated_at TEXT NOT NULL, dirty INTEGER NOT NULL, deleted INTEGER NOT NULL)',
    );
    repo = NoteRepository(openDb: () async => db);
  });
  tearDown(() => db.close());

  test('SQLite CRUD sorts updates and keeps deleted notes queued', () async {
    final first = await repo.addNote(title: 'Pertama');
    final second = await repo.addNote(title: 'Kedua');
    await repo.updateNote(first.copyWith(title: 'Terbaru'));
    expect((await repo.fetchNotes()).first.title, 'Terbaru');
    await repo.deleteNote(second.id!);
    expect(await repo.getNoteById(second.id!), isNull);
    expect((await repo.fetchNotes()).length, 1);
    expect((await repo.fetchDirtyNotes()).where((n) => n.deleted).length, 1);
    expect(await repo.countDirty(), 2);
  });

  test('SQLite conditional ACK cannot clear a newer edit', () async {
    final sent = await repo.addNote(title: 'Versi dikirim');
    await repo.updateNote(sent.copyWith(title: 'Edit saat upload'));
    expect(await repo.acknowledge(sent, sent), isFalse);
    expect((await repo.getNoteById(sent.id!))!.title, 'Edit saat upload');
    expect(await repo.countDirty(), 1);
  });

  test(
    'fixed-width UTC timestamps sort correctly across fractional seconds',
    () async {
      final base = DateTime.utc(2026, 10, 5);
      for (final micros in [0, 1, 1000, 1001]) {
        await db.insert(
          'notes',
          Note(
            title: '$micros',
            updatedAt: base.add(Duration(microseconds: micros)),
          ).toMap(),
        );
      }
      expect((await repo.fetchNotes()).map((n) => n.title), [
        '1001',
        '1000',
        '1',
        '0',
      ]);
    },
  );
}
