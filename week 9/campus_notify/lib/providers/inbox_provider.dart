import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/inbox_item.dart';
import '../data/inbox_store.dart';
import '../messaging/app_badge.dart';

final inboxStoreProvider = Provider<InboxStore>((ref) => PrefsInboxStore());

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(ref.watch(inboxStoreProvider)),
);

/// Badge ikon aplikasi. Diganti versi palsu di test.
final badgeSinkProvider = Provider<BadgeSink>((ref) => const LauncherBadgeSink());

/// Daftar notifikasi yang belum dibaca.
///
/// `build()` membaca penyimpanan. Setiap aksi memperbarui state lebih dulu
/// (supaya badge langsung berubah) lalu menulis ke penyimpanan.
final inboxProvider =
    AsyncNotifierProvider<InboxNotifier, List<InboxItem>>(InboxNotifier.new);

class InboxNotifier extends AsyncNotifier<List<InboxItem>> {
  @override
  Future<List<InboxItem>> build() async {
    return ref.watch(inboxRepositoryProvider).load();
  }

  /// Menyimpan notifikasi yang baru diterima.
  ///
  /// Aman dipanggil walau daftar belum selesai dimuat: isi penyimpanan dibaca
  /// lebih dulu supaya butir lama tidak hilang.
  Future<void> add(InboxItem item) async {
    final repository = ref.read(inboxRepositoryProvider);
    final current = state.valueOrNull ?? await repository.load();
    final next = InboxRepository.insertItem(
      current,
      item,
      maxItems: repository.maxItems,
    );
    state = AsyncData(next);
    await repository.write(next);
  }

  /// Menandai satu notifikasi sebagai dibaca: butir hilang dari daftar dan
  /// angka di lonceng langsung berkurang.
  Future<void> markRead(String id) async {
    final repository = ref.read(inboxRepositoryProvider);
    final current = state.valueOrNull ?? await repository.load();
    final next = current.where((item) => item.id != id).toList(growable: false);
    state = AsyncData(next);
    await repository.write(next);
  }

  Future<void> clearAll() async {
    state = const AsyncData(<InboxItem>[]);
    await ref.read(inboxRepositoryProvider).clear();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(inboxRepositoryProvider).load(),
    );
  }
}

/// Jumlah notifikasi belum dibaca untuk badge.
///
/// Diturunkan dari [inboxProvider], bukan dihitung terpisah, supaya tidak
/// mungkin menampilkan angka yang berbeda dari isi daftar.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).valueOrNull?.length ?? 0;
});
