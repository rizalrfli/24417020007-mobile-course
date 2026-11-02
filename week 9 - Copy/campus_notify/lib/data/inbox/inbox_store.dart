import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_notify/domain/inbox/inbox_item.dart';
import 'package:campus_notify/data/inbox/inbox_item_model.dart';

abstract interface class InboxStore {
  Future<List<InboxItem>> read();
  Future<void> write(List<InboxItem> items);
}

/// SharedPreferences adapter for the inbox storage contract.
class PrefsInboxStore implements InboxStore {
  PrefsInboxStore({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  static const storageKey = 'inbox_items_v1';

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<List<InboxItem>> read() async {
    final prefs = await _preferences();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];

    return decoded.map((raw) {
      try {
        return InboxItemModel.fromJson(raw).toEntity();
      } on FormatException {
        return null;
      }
    }).whereType<InboxItem>().toList(growable: false);
  }

  @override
  Future<void> write(List<InboxItem> items) async {
    final prefs = await _preferences();
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((item) => InboxItemModel.fromEntity(item).toJson()).toList()),
    );
  }
}

/// In-memory adapter used by tests.
class MemoryInboxStore implements InboxStore {
  MemoryInboxStore([List<InboxItem>? initial])
      : _items = List<InboxItem>.of(initial ?? const []);

  List<InboxItem> _items;

  @override
  Future<List<InboxItem>> read() async => List<InboxItem>.of(_items);

  @override
  Future<void> write(List<InboxItem> items) async {
    _items = List<InboxItem>.of(items);
  }
}
