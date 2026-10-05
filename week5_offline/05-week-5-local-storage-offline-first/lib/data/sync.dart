import 'local/note.dart';
import 'remote/note_remote.dart';
import 'repositories/note_repository.dart';

class OfflineException implements Exception {
  const OfflineException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<int> syncNotes(
  NoteRepository repo, {
  required NoteRemote remote,
  bool offline = false,
}) async {
  if (offline) {
    throw const OfflineException('Perangkat offline, sinkronisasi ditunda.');
  }
  final pending = await repo.fetchDirtyNotes();
  var synced = 0;
  for (final sent in pending) {
    final accepted = await remote.upload(sent);
    if (accepted.id != sent.id || accepted.updatedAt.isBefore(sent.updatedAt)) {
      throw StateError('ACK server tidak valid; catatan tetap dirty');
    }
    if (await repo.acknowledge(sent, accepted)) synced++;
  }
  return synced;
}

/// Last-write-wins UTC; timestamp sama memilih versi lokal yang dikirim.
Note resolveConflict(Note local, Note remote) =>
    remote.updatedAt.isAfter(local.updatedAt) ? remote : local;
