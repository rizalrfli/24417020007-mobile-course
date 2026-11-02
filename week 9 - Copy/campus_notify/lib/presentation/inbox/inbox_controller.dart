import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/domain/inbox/inbox_item.dart';
import 'package:campus_notify/domain/inbox/inbox_repository.dart';
import 'package:campus_notify/domain/inbox/usecases/add_inbox_item.dart';
import 'package:campus_notify/domain/inbox/usecases/get_inbox.dart';
import 'package:campus_notify/data/inbox/inbox_store.dart';
import 'package:campus_notify/data/inbox/inbox_repository_impl.dart';
import 'package:campus_notify/data/push/app_badge.dart';

final inboxStoreProvider = Provider<InboxStore>((ref) => PrefsInboxStore());

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepositoryImpl(ref.watch(inboxStoreProvider)),
);

final getInboxProvider = Provider<GetInbox>(
  (ref) => GetInbox(ref.watch(inboxRepositoryProvider)),
);

final addInboxItemProvider = Provider<AddInboxItem>(
  (ref) => AddInboxItem(ref.watch(inboxRepositoryProvider)),
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
    final result = await ref.watch(getInboxProvider).call();
    if (result.failure != null) throw StateError(result.failure!.message);
    return result.items;
  }

  /// Menyimpan notifikasi yang baru diterima.
  ///
  /// Aman dipanggil walau daftar belum selesai dimuat: isi penyimpanan dibaca
  /// lebih dulu supaya butir lama tidak hilang.
  Future<void> add(InboxItem item) async {
    final result = await ref.read(addInboxItemProvider).call(item);
    if (result.failure != null) throw StateError(result.failure!.message);
    state = AsyncData(result.items);
  }

  /// Menandai satu notifikasi sebagai dibaca: butir hilang dari daftar dan
  /// angka di lonceng langsung berkurang.
  Future<void> markRead(String id) async {
    final result = await ref.read(inboxRepositoryProvider).markRead(id);
    if (result.failure != null) throw StateError(result.failure!.message);
    state = AsyncData(result.items);
  }

  Future<void> clearAll() async {
    final result = await ref.read(inboxRepositoryProvider).clear();
    if (result.failure != null) throw StateError(result.failure!.message);
    state = AsyncData(result.items);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getInboxProvider).call();
      if (result.failure != null) throw StateError(result.failure!.message);
      return result.items;
    });
  }
}

/// Jumlah notifikasi belum dibaca untuk badge.
///
/// Diturunkan dari [inboxProvider], bukan dihitung terpisah, supaya tidak
/// mungkin menampilkan angka yang berbeda dari isi daftar.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).valueOrNull?.length ?? 0;
});
