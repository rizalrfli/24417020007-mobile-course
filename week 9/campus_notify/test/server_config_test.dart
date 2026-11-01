import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/data/server_config.dart';
import 'package:campus_notify/providers/auth_provider.dart';

void main() {
  group('normalizeServerUrl', () {
    test('menambah http:// bila skema tidak ditulis', () {
      expect(normalizeServerUrl('10.0.2.2:8080'), 'http://10.0.2.2:8080');
      expect(normalizeServerUrl('192.168.1.5:8080'), 'http://192.168.1.5:8080');
    });

    test('membuang spasi dan garis miring di ujung', () {
      expect(normalizeServerUrl('  https://a.test  '), 'https://a.test');
      expect(normalizeServerUrl('https://a.test/'), 'https://a.test');
      expect(normalizeServerUrl('https://a.test///'), 'https://a.test');
    });

    test('mempertahankan path yang memang bagian dari base', () {
      expect(normalizeServerUrl('https://a.test/api'), 'https://a.test/api');
      expect(normalizeServerUrl('https://a.test/api/'), 'https://a.test/api');
    });

    test('menolak skema selain http dan https', () {
      expect(normalizeServerUrl('ftp://a.test'), isNull);
      expect(normalizeServerUrl('javascript:alert(1)'), isNull);
    });

    test('menolak alamat kosong atau tanpa host', () {
      expect(normalizeServerUrl(''), isNull);
      expect(normalizeServerUrl('   '), isNull);
      expect(normalizeServerUrl('http://'), isNull);
    });

    test('alamat contoh terdeteksi sebagai placeholder', () {
      expect(isPlaceholderUrl('https://example-campus-api.test'), isTrue);
      expect(isPlaceholderUrl('http://10.0.2.2:8080'), isFalse);
    });
  });

  group('serverUrlProvider', () {
    late MemoryServerConfigStore store;
    late ProviderContainer container;

    setUp(() {
      store = MemoryServerConfigStore();
      container = ProviderContainer(
        overrides: [serverConfigStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
    });

    test('default memakai nilai dari dart-define', () {
      expect(container.read(serverUrlProvider), apiBaseUrl);
    });

    test('menyimpan alamat yang sudah dinormalkan', () async {
      final ok = await container
          .read(serverUrlProvider.notifier)
          .save('  10.0.2.2:8080/ ');

      expect(ok, isTrue);
      expect(container.read(serverUrlProvider), 'http://10.0.2.2:8080');
      expect(store.value, 'http://10.0.2.2:8080');
    });

    test('alamat tidak sah tidak mengubah apa pun', () async {
      final before = container.read(serverUrlProvider);

      final ok = await container.read(serverUrlProvider.notifier).save('ftp://x');

      expect(ok, isFalse);
      expect(container.read(serverUrlProvider), before);
      expect(store.value, isNull);
    });

    test('load memakai alamat tersimpan', () async {
      store.value = 'https://api.kampus.test';

      await container.read(serverUrlProvider.notifier).load();

      expect(container.read(serverUrlProvider), 'https://api.kampus.test');
    });

    test('load tidak menimpa bila belum ada yang tersimpan', () async {
      await container.read(serverUrlProvider.notifier).load();

      expect(container.read(serverUrlProvider), apiBaseUrl);
    });

    test('reset kembali ke default dan mengosongkan simpanan', () async {
      await container.read(serverUrlProvider.notifier).save('http://a.test');
      await container.read(serverUrlProvider.notifier).reset();

      expect(container.read(serverUrlProvider), apiBaseUrl);
      expect(store.value, isEmpty);
    });

    test('Dio login ikut memakai alamat baru', () async {
      expect(container.read(authDioProvider).options.baseUrl, apiBaseUrl);

      await container
          .read(serverUrlProvider.notifier)
          .save('http://192.168.1.5:8080');

      expect(
        container.read(authDioProvider).options.baseUrl,
        'http://192.168.1.5:8080',
      );
    });
  });
}
