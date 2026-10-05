import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/data/local/note.dart';
import 'package:offline_notes/data/sync.dart';
import 'fakes.dart';

Note pending(int id) => Note(
  id: id,
  title: 'N$id',
  updatedAt: DateTime.utc(2026, 10, 5),
  dirty: true,
);

void main() {
  test(
    'successful ACK clears dirty per uploaded note including tombstone',
    () async {
      final repo = FakeNoteRepository(
        notes: [pending(1), pending(2).copyWith(deleted: true)],
      );
      final remote = FakeRemote();
      expect(await syncNotes(repo, remote: remote), 2);
      expect(await repo.countDirty(), 0);
      expect(remote.calls, 2);
      expect((await repo.fetchNotes()).length, 1);
    },
  );
  test('forced offline preserves dirty and makes no network request', () async {
    final repo = FakeNoteRepository(notes: [pending(1)]);
    final remote = FakeRemote();
    await expectLater(
      syncNotes(repo, remote: remote, offline: true),
      throwsA(isA<OfflineException>()),
    );
    expect(remote.calls, 0);
    expect(await repo.countDirty(), 1);
  });
  test(
    'network failure preserves unacknowledged notes after partial success',
    () async {
      final repo = FakeNoteRepository(notes: [pending(1), pending(2)]);
      final remote = FakeRemote(
        onUpload: (n) async {
          if (n.id == 2) throw StateError('network failed');
          return n;
        },
      );
      await expectLater(
        syncNotes(repo, remote: remote),
        throwsA(isA<StateError>()),
      );
      expect(repo.items.first.dirty, isFalse);
      expect(repo.items.last.dirty, isTrue);
    },
  );
  test('edit during upload remains dirty after older ACK', () async {
    final repo = FakeNoteRepository(notes: [pending(1)]);
    final remote = FakeRemote(
      onUpload: (n) async {
        repo.items[0] = n.copyWith(
          title: 'Edit baru',
          updatedAt: n.updatedAt.add(const Duration(seconds: 1)),
        );
        return n;
      },
    );
    expect(await syncNotes(repo, remote: remote), 0);
    expect(repo.items.single.title, 'Edit baru');
    expect(await repo.countDirty(), 1);
  });
  test('newer server conflict result replaces local version', () async {
    final repo = FakeNoteRepository(notes: [pending(1)]);
    final remote = FakeRemote(
      onUpload: (n) async => n.copyWith(
        title: 'Server terbaru',
        updatedAt: n.updatedAt.add(const Duration(seconds: 1)),
      ),
    );
    expect(await syncNotes(repo, remote: remote), 1);
    expect(repo.items.single.title, 'Server terbaru');
  });
  test('invalid ACK identity does not clear dirty', () async {
    final repo = FakeNoteRepository(notes: [pending(1)]);
    await expectLater(
      syncNotes(
        repo,
        remote: FakeRemote(onUpload: (n) async => n.copyWith(id: 99)),
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repo.countDirty(), 1);
  });
}
