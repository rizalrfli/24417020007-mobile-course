import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'; // ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/server_config.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/providers/auth_provider.dart';

/// Reproduksi alur login seperti dipakai di perangkat, terhadap mock API hidup.
///
///   node tools/mock-api/server.js &
///   flutter test test/login_flow_check.dart
///
/// Tiga jebakan yang dihindari di sini:
/// 1. `pumpAndSettle` tidak pernah selesai karena layar tunggu memutar
///    `CircularProgressIndicator` tanpa henti.
/// 2. `testWidgets` memakai timer palsu, sehingga HTTP sungguhan tidak pernah
///    rampung. Bagian yang menyentuh jaringan dibungkus `tester.runAsync`.
/// 3. `router.dispose()` ikut membuang `RouterRefresh`; membuang container
///    setelahnya memicu "used after being disposed". Router tidak dibuang di
///    sini karena umur test memang pendek.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'http://127.0.0.1:8080';

  setUpAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform({});
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        serverConfigStoreProvider
            .overrideWithValue(MemoryServerConfigStore(baseUrl)),
        authRepositoryProvider.overrideWithValue(
          HttpAuthRepository(Dio(BaseOptions(baseUrl: baseUrl))),
        ),
      ],
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> bootApp(WidgetTester tester, ProviderContainer container) async {
    await container.read(serverUrlProvider.notifier).load();
    final router = buildRouter(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: CampusNotifyApp(router: router),
      ),
    );
    await settle(tester);
  }

  List<String> visibleText() => find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), password);
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await Future<void>.delayed(const Duration(milliseconds: 900));
    });
    await settle(tester);
  }

  // ---- lapisan logika: tanpa widget, tanpa timer palsu ---------------------

  test('AuthNotifier.login menyimpan token dan menandai sesi aktif', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);
    expect(container.read(authStateProvider).value, isFalse);

    await container
        .read(authStateProvider.notifier)
        .login('mhs@polinema.ac.id', 'rahasia1');

    final state = container.read(authStateProvider);
    // ignore: avoid_print
    print('STATE setelah login -> ${state.runtimeType} / ${state.value}');
    expect(state.hasError, isFalse, reason: 'tidak boleh error: ${state.error}');
    expect(state.value, isTrue);

    final access = await container.read(tokenStoreProvider).readAccess();
    // ignore: avoid_print
    print('TOKEN -> ${access == null ? "NULL" : "${access.length} char"}');
    expect(access, isNotNull);
  });

  test('AuthNotifier.login dengan password salah jadi AsyncError', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);
    await container
        .read(authStateProvider.notifier)
        .login('mhs@polinema.ac.id', 'salahbanget');

    final state = container.read(authStateProvider);
    // ignore: avoid_print
    print('STATE setelah gagal -> ${state.runtimeType} / ${state.error}');
    expect(state.hasError, isTrue);
    expect(state.value, isFalse);
  });

  // ---- lapisan UI: alur penuh di layar ------------------------------------

  testWidgets('login benar membawa pengguna ke beranda', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await bootApp(tester, container);

    expect(find.byKey(const Key('email')), findsOneWidget);

    await fillAndSubmit(
      tester,
      email: 'mhs@polinema.ac.id',
      password: 'rahasia1',
    );

    // ignore: avoid_print
    print('SETELAH LOGIN -> ${visibleText()}');

    expect(find.text('Pengumuman'), findsOneWidget);
    expect(container.read(authStateProvider).value, isTrue);
  });

  testWidgets('login salah menampilkan pesan dan tetap di /login',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await bootApp(tester, container);

    await fillAndSubmit(
      tester,
      email: 'mhs@polinema.ac.id',
      password: 'salahbanget',
    );

    // ignore: avoid_print
    print('SETELAH GAGAL -> ${visibleText()}');

    expect(find.byKey(const Key('email')), findsOneWidget, reason: 'tetap di /login');
    expect(find.textContaining('salah'), findsWidgets);
  });

  testWidgets('alamat server bisa diganti dari layar login', (tester) async {
    final container = ProviderContainer(
      overrides: [
        // Mulai dari alamat contoh: kondisi yang membuat pengguna tidak bisa
        // login.
        serverConfigStoreProvider.overrideWithValue(
          MemoryServerConfigStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(serverUrlProvider.notifier).load();
    expect(isPlaceholderUrl(container.read(serverUrlProvider)), isTrue);

    await bootApp(tester, container);

    // Panel server otomatis terbuka saat alamat masih contoh.
    await tester.enterText(find.byKey(const Key('server')), baseUrl);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await settle(tester);

    expect(container.read(serverUrlProvider), baseUrl);
    // ignore: avoid_print
    print('SERVER SETELAH SIMPAN -> ${container.read(serverUrlProvider)}');
  });
}
