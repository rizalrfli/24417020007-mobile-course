import 'package:campus_notify/domain/inbox/inbox_item.dart';

import 'package:campus_notify/domain/failures.dart';

/// Repository contract owned by the domain layer.
abstract interface class InboxRepository {
  Future<({List<InboxItem> items, Failure? failure})> load();
  Future<({List<InboxItem> items, Failure? failure})> add(InboxItem item);
  Future<({List<InboxItem> items, Failure? failure})> write(
    List<InboxItem> items,
  );
  Future<({List<InboxItem> items, Failure? failure})> markRead(String id);
  Future<({List<InboxItem> items, Failure? failure})> clear();
}
