import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sync.dart';
import '../data/remote/note_remote.dart';
import 'offline_providers.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
);

final dirtyCountProvider = FutureProvider<int>(
  (ref) => ref.watch(noteRepositoryProvider).countDirty(),
);

/// Membaca satu catatan berdasarkan id untuk NoteDetailPage melalui GoRouter.
final noteByIdProvider = FutureProvider.family<Note?, int>(
  (ref, id) => ref.watch(noteRepositoryProvider).getNoteById(id),
);

final noteActionsProvider = Provider<NoteActions>((ref) => NoteActions(ref));
final noteRemoteProvider = Provider<NoteRemote>((ref) => HttpNoteRemote());
final syncBusyProvider = NotifierProvider<SyncBusy, bool>(SyncBusy.new);

class SyncBusy extends Notifier<bool> {
  @override
  bool build() => false;
  void setBusy(bool value) => state = value;
}

/// Kumpulan aksi yang mengubah data. Setiap mutasi diakhiri invalidate
/// agar provider baca (notes & dirty count) memuat ulang dari database.
class NoteActions {
  NoteActions(this._ref);

  final Ref _ref;

  NoteRepository get _repo => _ref.read(noteRepositoryProvider);

  Future<void> add(String title, String body) async {
    await _repo.addNote(title: title, body: body);
    _refresh();
  }

  Future<void> update(Note note) async {
    await _repo.updateNote(note);
    _refresh();
  }

  Future<void> delete(int id) async {
    await _repo.deleteNote(id);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(notesProvider);
    _ref.invalidate(dirtyCountProvider);
    _ref.invalidate(noteByIdProvider);
  }

  Future<int> sync() async {
    if (_ref.read(syncBusyProvider)) return 0;
    _ref.read(syncBusyProvider.notifier).setBusy(true);
    final offline = _ref.read(forceOfflineProvider);
    try {
      return await syncNotes(
        _repo,
        remote: _ref.read(noteRemoteProvider),
        offline: offline,
      );
    } finally {
      if (_ref.mounted) {
        _refresh();
        _ref.read(syncBusyProvider.notifier).setBusy(false);
      }
    }
  }
}
