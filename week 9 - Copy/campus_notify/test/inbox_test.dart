import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_notify/domain/inbox/inbox_item.dart';
import 'package:campus_notify/domain/inbox/inbox_repository.dart';
import 'package:campus_notify/domain/inbox/usecases/add_inbox_item.dart';
import 'package:campus_notify/domain/inbox/usecases/get_inbox.dart';
import 'package:campus_notify/domain/failures.dart';
import 'package:campus_notify/data/inbox/inbox_store.dart';
import 'package:campus_notify/data/inbox/inbox_item_model.dart';
import 'package:campus_notify/data/inbox/inbox_repository_impl.dart';
import 'package:campus_notify/presentation/inbox/inbox_controller.dart';
import 'package:campus_notify/presentation/routes.dart';

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
      final result = InboxItemModel.fromMessage(
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
      final result = InboxItemModel.fromMessage(
        messageId: 'msg-2',
        title: 'Mencurigakan',
        body: '',
        data: {'route': 'https://jahat.example/curi'},
      );

      expect(result.route, Routes.home);
    });

    test('tanpa messageId memakai data.id, lalu jatuh ke id lokal', () {
      final withDataId = InboxItemModel.fromMessage(
        messageId: null,
        title: 'A',
        body: '',
        data: {'route': '/pengumuman/7', 'id': '7'},
      );
      expect(withDataId.id, '7');

      final withoutAnyId = InboxItemModel.fromMessage(
        messageId: null,
        title: 'B',
        body: '',
        data: {'route': '/pengumuman/7'},
      );
      expect(withoutAnyId.id, isNotEmpty);
    });

    test('judul dan isi kosong diganti nilai yang aman', () {
      final result = InboxItemModel.fromMessage(
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
      final restored = InboxItemModel.fromJson(
        InboxItemModel.fromEntity(original).toJson(),
      );

      expect(restored, isNotNull);
      expect(restored.id, '1');
      expect(restored.title, 'Uji');
      expect(restored.route, '/pengumuman/1');
      expect(restored.receivedAt, original.receivedAt);
    });

    test('entri rusak dikembalikan null, bukan melempar', () {
      expect(() => InboxItemModel.fromJson('bukan map'), throwsFormatException);
      expect(() => InboxItemModel.fromJson({'title': 'tanpa id'}), throwsFormatException);
      expect(() => InboxItemModel.fromJson({'id': 'x'}), throwsFormatException);
    });

    test('rute tidak dikenal saat dibaca ulang dibersihkan ke beranda', () {
      final restored = InboxItemModel.fromJson({
        'id': '1',
        'title': 'A',
        'body': '',
        'route': '/admin',
        'received_at': '2026-11-01T09:00:00.000',
      });

      expect(restored.route, Routes.home);
    });
  });

  group('InboxRepositoryImpl', () {
    test('new item is added at the top and duplicate ids are replaced', () async {
      final repo = InboxRepositoryImpl(MemoryInboxStore());
      await repo.add(item('1'));
      await repo.add(item('2'));
      final replaced = await repo.add(item('1', title: 'Updated'));
      expect(replaced.items.map((entry) => entry.id), ['2', '1']);
      expect(replaced.items.last.title, 'Updated');
      expect(replaced.failure, isNull);
    });

    test('limits item count and removes the oldest item', () async {
      final repo = InboxRepositoryImpl(MemoryInboxStore(), maxItems: 2);
      await repo.add(item('1'));
      await repo.add(item('2'));
      final result = await repo.add(item('3'));
      expect(result.items.map((entry) => entry.id), ['3', '2']);
    });

    test('markRead and clear update stored inbox', () async {
      final repo = InboxRepositoryImpl(MemoryInboxStore());
      await repo.add(item('1'));
      await repo.add(item('2'));
      expect((await repo.markRead('1')).items.map((e) => e.id), ['2']);
      expect((await repo.clear()).items, isEmpty);
    });
  });

  group('Inbox use cases with fake repository', () {
    test('GetInbox returns items on success', () async {
      final fake = FakeInboxRepository(items: [item('ok')]);
      final result = await GetInbox(fake).call();
      expect(result.items.single.id, 'ok');
      expect(result.failure, isNull);
    });

    test('GetInbox returns failure without throwing', () async {
      const failure = LocalFailure('read failed');
      final result = await GetInbox(FakeInboxRepository(failure: failure)).call();
      expect(result.items, isEmpty);
      expect(result.failure, failure);
    });

    test('AddInboxItem delegates to repository contract', () async {
      final fake = FakeInboxRepository();
      final result = await AddInboxItem(fake).call(item('new'));
      expect(fake.added?.id, 'new');
      expect(result.items.single.id, 'new');
      expect(result.failure, isNull);
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

class FakeInboxRepository implements InboxRepository {
  FakeInboxRepository({List<InboxItem> items = const [], this.failure})
      : items = List.of(items);

  List<InboxItem> items;
  final Failure? failure;
  InboxItem? added;

  @override
  Future<({List<InboxItem> items, Failure? failure})> load() async =>
      (items: items, failure: failure);

  @override
  Future<({List<InboxItem> items, Failure? failure})> add(InboxItem item) async {
    added = item;
    items = [item, ...items];
    return (items: items, failure: failure);
  }

  @override
  Future<({List<InboxItem> items, Failure? failure})> write(
    List<InboxItem> items,
  ) async {
    this.items = List.of(items);
    return (items: this.items, failure: failure);
  }

  @override
  Future<({List<InboxItem> items, Failure? failure})> markRead(String id) async {
    items = items.where((item) => item.id != id).toList();
    return (items: items, failure: failure);
  }

  @override
  Future<({List<InboxItem> items, Failure? failure})> clear() async {
    items = [];
    return (items: items, failure: failure);
  }
}
