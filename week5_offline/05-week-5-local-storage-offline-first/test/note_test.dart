import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/data/local/note.dart';
import 'package:offline_notes/data/sync.dart';

void main() {
  test('model round-trip preserves dirty, tombstone, and UTC instant', () {
    final note = Note(
      id: 7,
      title: 'SQLite',
      body: 'Offline',
      updatedAt: DateTime.parse('2026-10-05T10:00:00+07:00'),
      dirty: true,
      deleted: true,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.id, 7);
    expect(restored.title, note.title);
    expect(restored.body, note.body);
    expect(restored.updatedAt.isAtSameMomentAs(note.updatedAt), isTrue);
    expect(restored.updatedAt.isUtc, isTrue);
    expect(restored.dirty, isTrue);
    expect(restored.deleted, isTrue);
  });
  test('missing optional model fields use defaults', () {
    final note = Note.fromMap({'title': 'Catatan'});
    expect(note.body, '');
    expect(note.dirty, isFalse);
    expect(note.deleted, isFalse);
  });
  test('conflict selects newest UTC timestamp, tie selects local', () {
    final local = Note(
      id: 1,
      title: 'Local',
      updatedAt: DateTime.utc(2026, 10, 5),
    );
    final remote = local.copyWith(
      title: 'Remote',
      updatedAt: local.updatedAt.add(const Duration(seconds: 1)),
    );
    expect(resolveConflict(local, remote).title, 'Remote');
    expect(resolveConflict(remote, local).title, 'Remote');
    expect(
      resolveConflict(local, local.copyWith(title: 'Equal remote')).title,
      'Local',
    );
  });
}
