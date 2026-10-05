import 'package:offline_notes/data/local/note.dart';
import 'package:offline_notes/data/remote/note_remote.dart';
import 'package:offline_notes/data/repositories/note_repository.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({List<Note> notes = const [], this.failRead = false})
    : items = [...notes],
      super(openDb: () => throw UnimplementedError());
  final List<Note> items;
  final bool failRead;

  @override
  Future<List<Note>> fetchNotes() async {
    if (failRead) throw StateError('db locked');
    return items.where((n) => !n.deleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;
  @override
  Future<List<Note>> fetchDirtyNotes() async =>
      items.where((n) => n.dirty).toList();
  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    final note = Note(
      id: items.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now().toUtc(),
      dirty: true,
    );
    items.add(note);
    return note;
  }

  @override
  Future<bool> acknowledge(Note sent, Note accepted) async {
    final index = items.indexWhere((n) => n.id == sent.id);
    if (index < 0 || items[index].updatedAt != sent.updatedAt) return false;
    items[index] = accepted.copyWith(dirty: false);
    return true;
  }
}

class FakeRemote implements NoteRemote {
  FakeRemote({this.onUpload});
  final Future<Note> Function(Note)? onUpload;
  int calls = 0;
  @override
  Future<Note> upload(Note note) async {
    calls++;
    return onUpload == null ? note.copyWith(dirty: false) : onUpload!(note);
  }
}
