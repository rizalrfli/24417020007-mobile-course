import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_notify/domain/inbox/inbox_item.dart';
import 'package:campus_notify/data/inbox/inbox_store.dart';
import 'package:campus_notify/domain/push/message_route.dart';
import 'package:campus_notify/data/push/notification_payload.dart';
import 'package:campus_notify/presentation/inbox/inbox_page.dart';
import 'package:campus_notify/presentation/inbox/inbox_controller.dart';
import 'package:campus_notify/presentation/routes.dart';

InboxItem item(String id) {
  return InboxItem(
    id: id,
    title: 'Pengumuman $id',
    body: 'Isi pengumuman $id',
    route: Routes.announcement(id),
    receivedAt: DateTime(2026, 11, 1, 9, 30),
  );
}

ProviderContainer containerWith(List<InboxItem> items) {
  final container = ProviderContainer(
    overrides: [
      inboxStoreProvider.overrideWithValue(MemoryInboxStore(items)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('routeFromMessage', () {
    test('menangani route kosong dan tanpa slash', () {
      expect(routeFromMessage({}), Routes.home);
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('menolak URL absolut dan rute yang tidak terdaftar', () {
      expect(routeFromMessage({'route': 'https://jahat.example'}), Routes.home);
      expect(routeFromMessage({'route': '//jahat.example'}), Routes.home);
      expect(routeFromMessage({'route': '/login'}), Routes.home);
      expect(routeFromMessage({'route': '/admin'}), Routes.home);
      expect(routeFromMessage({'route': '/pengumuman/../login'}), Routes.home);
    });
  });

  group('payload notifikasi lokal', () {
    test('id dan rute bertahan setelah encode lalu decode', () {
      final payload = encodeNotificationPayload(id: 'msg-1', route: '/pengumuman/3');
      final decoded = decodeNotificationPayload(payload);

      expect(decoded.id, 'msg-1');
      expect(decoded.route, '/pengumuman/3');
    });

    test('payload lama yang hanya berisi rute tetap terbaca', () {
      final decoded = decodeNotificationPayload('/pengumuman/9');

      expect(decoded.id, isNull);
      expect(decoded.route, '/pengumuman/9');
    });

    test('payload rusak atau rute asing kembali ke beranda', () {
      expect(decodeNotificationPayload('{rusak').route, Routes.home);
      expect(
        decodeNotificationPayload(
          encodeNotificationPayload(id: '1', route: 'https://jahat.example'),
        ).route,
        Routes.home,
      );
    });
  });

  group('NotificationBell', () {
    Future<void> pumpBell(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await container.read(inboxProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(actions: const [NotificationBell()]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan angka sesuai jumlah belum dibaca', (tester) async {
      await pumpBell(tester, containerWith([item('1'), item('2'), item('3')]));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('badge disembunyikan saat tidak ada notifikasi',
        (tester) async {
      await pumpBell(tester, containerWith([]));

      expect(find.text('0'), findsNothing);
    });

    testWidgets('angka di atas 99 diringkas menjadi 99+', (tester) async {
      await pumpBell(
        tester,
        containerWith([for (var i = 0; i < 120; i++) item('$i')]),
      );

      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('InboxPage', () {
    Future<ProviderContainer> pumpPage(
      WidgetTester tester,
      List<InboxItem> items,
    ) async {
      final container = containerWith(items);
      await container.read(inboxProvider.future);

      final router = GoRouter(
        initialLocation: Routes.inbox,
        routes: [
          GoRoute(
            path: Routes.inbox,
            builder: (_, _) => const InboxPage(),
          ),
          GoRoute(
            path: Routes.home,
            builder: (_, _) => const Scaffold(body: Text('beranda')),
          ),
          GoRoute(
            path: Routes.announcementPattern,
            builder: (_, state) => Scaffold(
              body: Text('pengumuman ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('daftar kosong menampilkan pesan, bukan halaman putih',
        (tester) async {
      await pumpPage(tester, []);

      expect(find.text('Belum ada notifikasi baru'), findsOneWidget);
    });

    testWidgets('mengetuk butir menghapusnya dan membuka pengumuman',
        (tester) async {
      final container = await pumpPage(tester, [item('1'), item('2')]);

      expect(find.text('Pengumuman 1'), findsOneWidget);

      await tester.tap(find.text('Pengumuman 1'));
      await tester.pumpAndSettle();

      // Sudah dibaca: hilang dari daftar dan dari badge.
      expect(find.text('pengumuman 1'), findsOneWidget);
      final remaining = container.read(inboxProvider).value!;
      expect(remaining.map((entry) => entry.id), ['2']);
      expect(container.read(unreadCountProvider), 1);
    });

    testWidgets('tandai semua dibaca mengosongkan daftar', (tester) async {
      final container = await pumpPage(tester, [item('1'), item('2')]);

      await tester.tap(find.byTooltip('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada notifikasi baru'), findsOneWidget);
      expect(container.read(unreadCountProvider), 0);
    });
  });
}
