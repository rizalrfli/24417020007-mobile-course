import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'inbox_item.dart';

/// Penyimpanan daftar notifikasi.
///
/// Dipisah dari [InboxRepository] supaya logika daftar bisa diuji tanpa
/// platform channel `shared_preferences`.
abstract class InboxStore {
  Future<List<InboxItem>> read();
  Future<void> write(List<InboxItem> items);
}

/// Penyimpanan nyata di perangkat.
///
/// `shared_preferences` dipakai, bukan secure storage: isi pengumuman bukan
/// rahasia, dan secure storage di Android punya batas ukuran yang tidak cocok
/// untuk daftar yang terus bertambah.
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
      // Data rusak (mis. proses mati saat menulis). Mulai dari daftar kosong
      // daripada membuat kotak masuk gagal dibuka selamanya.
      return const [];
    }
    if (decoded is! List) return const [];

    return decoded
        .map(InboxItem.tryFromJson)
        .whereType<InboxItem>()
        .toList(growable: false);
  }

  @override
  Future<void> write(List<InboxItem> items) async {
    final prefs = await _preferences();
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}

/// Penyimpanan di memori untuk unit test.
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

/// Operasi daftar notifikasi: terbaru di atas, tanpa duplikat, jumlah dibatasi.
class InboxRepository {
  InboxRepository(this._store, {this.maxItems = 50});

  final InboxStore _store;

  /// Batas atas butir yang disimpan, supaya penyimpanan tidak tumbuh tanpa
  /// batas. Butir terlama dibuang lebih dulu.
  final int maxItems;

  Future<List<InboxItem>> load() => _store.read();

  /// Menimpa seluruh daftar. Dipakai jalur optimistis di UI setelah daftar
  /// baru dihitung di memori.
  Future<void> write(List<InboxItem> items) => _store.write(items);

  /// Menambahkan [item] lalu mengembalikan daftar terbaru.
  ///
  /// Id yang sama tidak digandakan: pesan yang dikirim ulang menggantikan isi
  /// lama di posisi yang sama, sehingga angka badge tidak menggelembung.
  Future<List<InboxItem>> add(InboxItem item) async {
    final items = insertItem(await _store.read(), item, maxItems: maxItems);
    await _store.write(items);
    return items;
  }

  /// Sisipkan [item] di paling atas, ganti bila id sudah ada, lalu potong ke
  /// [maxItems]. Fungsi murni agar aturan urutan dan batas bisa diuji langsung.
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
      if (items.length > maxItems) {
        items.removeRange(maxItems, items.length);
      }
    }
    return items;
  }

  /// Menghapus butir dari daftar. Inilah aksi "dibaca": butir yang dibaca
  /// hilang dari daftar sekaligus dari badge.
  Future<List<InboxItem>> markRead(String id) async {
    final items = List<InboxItem>.of(await _store.read());
    items.removeWhere((item) => item.id == id);
    await _store.write(items);
    return items;
  }

  Future<List<InboxItem>> clear() async {
    await _store.write(const []);
    return const [];
  }
}
