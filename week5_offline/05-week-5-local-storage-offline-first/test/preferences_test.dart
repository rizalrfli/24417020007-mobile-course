import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_notes/providers/prefs_providers.dart';
import 'package:offline_notes/data/prefs.dart';

void main() {
  test(
    'theme persists and last-opened returns previous session before saving current',
    () async {
      SharedPreferences.setMockInitialValues({
        'last_opened_at': '2026-10-04T03:00:00Z',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(lastOpenedProvider.future),
        '2026-10-04T03:00:00Z',
      );
      expect(await container.read(darkModeProvider.future), false);
      await container.read(darkModeProvider.notifier).toggle();
      expect(await PrefsRepository().getDarkMode(), true);
      expect(
        await PrefsRepository().getLastOpened(),
        isNot('2026-10-04T03:00:00Z'),
      );
    },
  );
}
