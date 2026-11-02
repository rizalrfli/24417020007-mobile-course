import 'package:campus_notify/data/inbox/inbox_store.dart';
import 'package:campus_notify/domain/failures.dart';
import 'package:campus_notify/domain/inbox/inbox_item.dart';
import 'package:campus_notify/domain/inbox/inbox_repository.dart';

class InboxRepositoryImpl implements InboxRepository {
  InboxRepositoryImpl(this._store, {this.maxItems = 50});

  final InboxStore _store;
  final int maxItems;

  @override
  Future<({List<InboxItem> items, Failure? failure})> load() async {
    try {
      return (items: await _store.read(), failure: null as Failure?);
    } catch (error) {
      return (
        items: const <InboxItem>[],
        failure: LocalFailure('Gagal membaca inbox: $error') as Failure?,
      );
    }
  }

  @override
  Future<({List<InboxItem> items, Failure? failure})> add(InboxItem item) async {
    final loaded = await load();
    if (loaded.failure != null) return loaded;
    final items = insertItem(loaded.items, item, maxItems: maxItems);
    return write(items);
  }

  @override
  Future<({List<InboxItem> items, Failure? failure})> write(
    List<InboxItem> items,
  ) async {
    try {
      await _store.write(items);
      return (items: List<InboxItem>.unmodifiable(items), failure: null as Failure?);
    } catch (error) {
      return (items: items, failure: LocalFailure('Gagal menyimpan inbox: $error'));
    }
  }

  @override
  Future<({List<InboxItem> items, Failure? failure})> markRead(String id) async {
    final loaded = await load();
    if (loaded.failure != null) return loaded;
    return write(loaded.items.where((item) => item.id != id).toList());
  }

  @override
  Future<({List<InboxItem> items, Failure? failure})> clear() => write(const []);

  static List<InboxItem> insertItem(
    List<InboxItem> current,
    InboxItem item, {
    required int maxItems,
  }) {
    final items = List<InboxItem>.of(current);
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.insert(0, item);
      if (items.length > maxItems) items.removeRange(maxItems, items.length);
    }
    return items;
  }
}
