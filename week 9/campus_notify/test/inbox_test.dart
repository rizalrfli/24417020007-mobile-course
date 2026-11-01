import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_notify/data/inbox_item.dart';
import 'package:campus_notify/data/inbox_store.dart';
import 'package:campus_notify/providers/inbox_provider.dart';
import 'package:campus_notify/routes.dart';

InboxItem item(String id, {String title = 'Pengumuman', DateTime? at}) {
  return InboxItem(
    id: id,
    title: title,
    body: 'isi $id',
    route: Routes.announcement(id),
    receivedAt: at ?? DateTime(2026, 11, 1, 9),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InboxItem.fromMessage', () {
    test('memakai messageId dan rute yang sah', () {
      final result = InboxItem.fromMessage(
        messageId: 'msg-1',
        title: 'Jadwal berubah',
        body: 'Kelas pindah ke A2',
        data: {'route': '/pengumuman/3', 'id': '3'},
      );

      expect(result.id, 'msg-1');
      expect(result.title, 'Jadwal berubah');
      expect(result.body, 'Kelas pindah ke A2');
      expect(result.route, '/pengumuman/3');
    });

    test('rute asing dari payload tidak dipakai apa adanya', () {
      final result = InboxItem.fromMessage(
        messageId: 'msg-2',
        title: 'Mencurigakan',
        body: '',
        data: {'route': 'https://jahat.example/curi'},
      );

      expect(result.route, Routes.home);
    });

    test('tanpa messageId memakai data.id, lalu jatuh ke id lokal', () {
      final withDataId = InboxItem.fromMessage(
        messageId: null,
        title: 'A',
        body: '',
        data: {'route': '/pengumuman/7', 'id': '7'},
      );
      expect(withDataId.id, '7');

      final withoutAnyId = InboxItem.fromMessage(
        messageId: null,
        title: 'B',
        body: '',
        data: {'route': '/pengumuman/7'},
      );
      expect(withoutAnyId.id, isNotEmpty);
    });

    test('judul dan isi kosong diganti nilai yang aman', () {
      final result = InboxItem.fromMessage(
        messageId: 'msg-3',
        title: '   ',
        body: null,
        data: const {},
      );

      expect(result.title, 'Pengumuman');
      expect(result.body, isEmpty);
    });
  });

  group('InboxItem serialisasi', () {
    test('bolak-balik JSON mempertahankan isi', () {
      final original = item('1', title: 'Uji');
      final restored = InboxItem.tryFromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );

      expect(restored, isNotNull);
      expect(restored!.id, '1');
      expect(restored.title, 'Uji');
      expect(restored.route, '/pengumuman/1');
      expect(restored.receivedAt, original.receivedAt);
    });

    test('entri rusak dikembalikan null, bukan melempar', () {
      expect(InboxItem.tryFromJson('bukan map'), isNull);
      expect(InboxItem.tryFromJson({'title': 'tanpa id'}), isNull);
      expect(InboxItem.tryFromJson({'id': 'x'}), isNull);
    });

    test('rute tidak dikenal saat dibaca ulang dibersihkan ke beranda', () {
      final restored = InboxItem.tryFromJson({
        'id': '1',
        'title': 'A',
        'body': '',
        'route': '/admin',
        'received_at': '2026-11-01T09:00:00.000',
      });

      expect(restored!.route, Routes.home);
    });
  });

  group('InboxRepository', () {
    test('butir baru masuk paling atas', () async {
      final repo = InboxRepository(MemoryInboxStore());
      await repo.add(item('1'));
      final items = await repo.add(item('2'));

      expect(items.map((entry) => entry.id), ['2', '1']);
    });

    test('id yang sama tidak digandakan', () async {
      final repo = InboxRepository(MemoryInboxStore());
      await repo.add(item('1', title: 'Lama'));
      final items = await repo.add(item('1', title: 'Baru'));

      expect(items, hasLength(1));
      expect(items.single.title, 'Baru');
    });

    test('jumlah dibatasi maxItems, butir terlama dibuang', () async {
      final repo = InboxRepository(MemoryInboxStore(), maxItems: 2);
      await repo.add(item('1'));
      await repo.add(item('2'));
      final items = await repo.add(item('3'));

      expect(items.map((entry) => entry.id), ['3', '2']);
    });

    test('markRead menghapus butir dari daftar', () async {
      final repo = InboxRepository(MemoryInboxStore());
      await repo.add(item('1'));
      await repo.add(item('2'));

      final items = await repo.markRead('1');

      expect(items.map((entry) => entry.id), ['2']);
    });

    test('clear mengosongkan daftar', () async {
      final repo = InboxRepository(MemoryInboxStore());
      await repo.add(item('1'));

      expect(await repo.clear(), isEmpty);
      expect(await repo.load(), isEmpty);
    });
  });

  group('PrefsInboxStore', () {
    test('menulis lalu membaca kembali daftar', () async {
      SharedPreferences.setMockInitialValues({});
      final store = PrefsInboxStore();

      await store.write([item('1'), item('2')]);
      final items = await store.read();

      expect(items.map((entry) => entry.id), ['1', '2']);
    });

    test('data rusak tidak membuat kotak masuk gagal dibuka', () async {
      SharedPreferences.setMockInitialValues({
        PrefsInboxStore.storageKey: '{bukan json',
      });

      expect(await PrefsInboxStore().read(), isEmpty);
    });
  });

  group('InboxNotifier + badge', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [inboxStoreProvider.overrideWithValue(MemoryInboxStore())],
      );
      addTearDown(container.dispose);
    });

    test('angka badge mengikuti jumlah butir belum dibaca', () async {
      await container.read(inboxProvider.future);
      expect(container.read(unreadCountProvider), 0);

      await container.read(inboxProvider.notifier).add(item('1'));
      expect(container.read(unreadCountProvider), 1);

      await container.read(inboxProvider.notifier).add(item('2'));
      expect(container.read(unreadCountProvider), 2);

      await container.read(inboxProvider.notifier).markRead('1');
      expect(container.read(unreadCountProvider), 1);
    });

    test('pesan yang dikirim ulang tidak menaikkan badge', () async {
      await container.read(inboxProvider.future);
      await container.read(inboxProvider.notifier).add(item('1'));
      await container.read(inboxProvider.notifier).add(item('1'));

      expect(container.read(unreadCountProvider), 1);
    });

    test('butir tetap ada setelah provider dibangun ulang', () async {
      await container.read(inboxProvider.future);
      await container.read(inboxProvider.notifier).add(item('1'));

      container.invalidate(inboxProvider);
      final items = await container.read(inboxProvider.future);

      expect(items.map((entry) => entry.id), ['1']);
    });

    test('clearAll mengosongkan daftar dan badge', () async {
      await container.read(inboxProvider.future);
      await container.read(inboxProvider.notifier).add(item('1'));

      await container.read(inboxProvider.notifier).clearAll();

      expect(container.read(unreadCountProvider), 0);
    });
  });
}
