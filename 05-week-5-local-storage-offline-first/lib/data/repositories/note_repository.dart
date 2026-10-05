import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openNotesDb;
  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    return (await db.query(
      'notes',
      where: 'deleted = 0',
      orderBy: 'updated_at DESC, id DESC',
    )).map(Note.fromMap).toList();
  }

  Future<Note?> getNoteById(int id) async {
    final db = await _openDb();
    final rows = await db.query(
      'notes',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Note.fromMap(rows.first);
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    if (title.trim().isEmpty) throw ArgumentError('Judul wajib diisi');
    final db = await _openDb();
    final note = Note(
      title: title.trim(),
      body: body,
      updatedAt: DateTime.now().toUtc(),
      dirty: true,
    );
    return note.copyWith(id: await db.insert('notes', note.toMap()));
  }

  Future<void> updateNote(Note note) async {
    if (note.id == null) throw ArgumentError('Catatan belum memiliki id');
    if (note.title.trim().isEmpty) throw ArgumentError('Judul wajib diisi');
    final db = await _openDb();
    await db.transaction((txn) async {
      final rows = await txn.query(
        'notes',
        where: 'id = ? AND deleted = 0',
        whereArgs: [note.id],
      );
      if (rows.isEmpty) throw StateError('Catatan tidak ditemukan');
      final current = Note.fromMap(rows.first);
      final updated = note.copyWith(
        title: note.title.trim(),
        updatedAt: _nextTime(current.updatedAt),
        dirty: true,
        deleted: false,
      );
      await txn.update(
        'notes',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    });
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      final rows = await txn.query(
        'notes',
        where: 'id = ? AND deleted = 0',
        whereArgs: [id],
      );
      if (rows.isEmpty) return;
      final current = Note.fromMap(rows.first);
      final tombstone = current.copyWith(
        deleted: true,
        dirty: true,
        updatedAt: _nextTime(current.updatedAt),
      );
      await txn.update(
        'notes',
        tombstone.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  DateTime _nextTime(DateTime previous) {
    final now = DateTime.now().toUtc();
    return now.isAfter(previous)
        ? now
        : previous.add(const Duration(microseconds: 1));
  }

  Future<List<Note>> fetchDirtyNotes() async {
    final db = await _openDb();
    return (await db.query(
      'notes',
      where: 'dirty = 1',
      orderBy: 'updated_at ASC',
    )).map(Note.fromMap).toList();
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM notes WHERE dirty = 1'),
        ) ??
        0;
  }

  // ACK hanya boleh membersihkan versi yang benar-benar dikirim.
  Future<bool> acknowledge(Note sent, Note accepted) async {
    final db = await _openDb();
    final changed = await db.update(
      'notes',
      accepted.copyWith(dirty: false).toMap(),
      where:
          'id = ? AND updated_at = ? AND title = ? AND body = ? AND deleted = ? AND dirty = 1',
      whereArgs: [
        sent.id,
        sent.toMap()['updated_at'],
        sent.title,
        sent.body,
        sent.deleted ? 1 : 0,
      ],
    );
    return changed == 1;
  }
}
