import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'note.dart';

Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 2,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX notes_updated ON notes(updated_at DESC)');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE notes ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'CREATE INDEX notes_updated ON notes(updated_at DESC)',
        );
        for (final row in await db.query('notes')) {
          final note = Note.fromMap(row);
          await db.update(
            'notes',
            {'updated_at': note.toMap()['updated_at']},
            where: 'id = ?',
            whereArgs: [note.id],
          );
        }
      }
    },
  );
}
