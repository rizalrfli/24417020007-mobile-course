import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music/music.dart';
import 'package:week_5/app/app.dart';
import 'package:week_5/app/providers.dart';
import 'package:week_5/app/router.dart';
import 'package:week_5/features/song/presentation/song_audio_controller.dart';
import 'package:week_5/features/song/presentation/song_detail_screen.dart';
import 'package:week_5/shared/data/mock_data.dart';
import 'package:week_5/shared/models/music.dart';
import 'package:week_5/shared/widgets/app_widgets.dart';

Future<ProviderContainer> boot(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LyricWaveApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

class _WidgetFakeMusicPlayer extends MusicPlayer {
  _WidgetFakeMusicPlayer(this.controller);
  final SongAudioController controller;

  @override
  Future<void> play(
    Music music, {
    bool showPrevious = false,
    bool showNext = false,
  }) async {
    controller.updateDuration(const Duration(seconds: 287));
    controller.updateStatus(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    controller.updateStatus(PlaybackStatus.paused);
  }

  @override
  Future<void> resume() async {
    controller.updateStatus(PlaybackStatus.playing);
  }

  @override
  Future<void> stop() async {
    controller.updateStatus(PlaybackStatus.idle);
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('home to song to artist, favorite, and history work', (
    tester,
  ) async {
    final container = await boot(tester);
    expect(find.text('LyricWave'), findsOneWidget);

    await tapVisible(tester, find.text('Nina'));
    expect(find.text('Detail lagu'), findsOneWidget);
    expect(find.byType(LyricsView), findsOneWidget);
    expect(find.textContaining('Saat engkau tertidur'), findsOneWidget);

    // Verify history was recorded
    expect(
      container.read(historyProvider).valueOrNull?.map((s) => s.id),
      contains('nina'),
    );

    await tapVisible(tester, find.byTooltip('Simpan Nina ke favorit'));
    expect(
      container.read(favoriteSongsProvider).valueOrNull?.map((s) => s.id),
      contains('nina'),
    );
    await tapVisible(tester, find.text('.Feast'));
    expect(find.text('Artis'), findsOneWidget);
    await tapVisible(tester, find.text('Peradaban'));
    expect(find.text('Detail lagu'), findsOneWidget);
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.text('Artis'), findsOneWidget);
    container.read(routerProvider).go('/favorites');
    await tester.pumpAndSettle();
    expect(find.text('Nina'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada favorit yang cocok'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Hapus pencarian'));
    await tapVisible(tester, find.byTooltip('Hapus Nina dari favorit'));
    expect(find.text('Belum ada lagu favorit'), findsOneWidget);
    container.read(routerProvider).go('/history');
    await tester.pumpAndSettle();
    expect(container.read(historyProvider).valueOrNull, isNotEmpty);
    await tapVisible(tester, find.byTooltip('Hapus riwayat'));
    await tapVisible(tester, find.text('Batal'));
    expect(container.read(historyProvider).valueOrNull, isNotEmpty);
    await tapVisible(tester, find.byTooltip('Hapus riwayat'));
    await tapVisible(tester, find.widgetWithText(TextButton, 'Hapus riwayat'));
    expect(find.text('Riwayat masih kosong'), findsOneWidget);
    expect(container.read(historyProvider).valueOrNull, isEmpty);

    expect(tester.takeException(), isNull);
  });

  testWidgets('search filters live and handles empty states', (tester) async {
    final container = await boot(tester);
    container.read(routerProvider).go('/search');
    await tester.pumpAndSettle();

    expect(find.text('Cari lagu yang ingin kamu baca'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nina');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Nina'), findsOneWidget);

    // Search for non-existent keyword
    await tester.enterText(find.byType(TextField), 'unknownkeyword123');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Lagu tidak ditemukan'), findsOneWidget);

    // Clear search
    await tapVisible(tester, find.byTooltip('Hapus pencarian'));
    expect(find.text('Cari lagu yang ingin kamu baca'), findsOneWidget);
  });

  testWidgets('profile preferences, dialogs and keyboard navigation work', (
    tester,
  ) async {
    final container = await boot(tester);
    await tapVisible(tester, find.text('Profil'));

    // Change lyrics font size
    await tapVisible(tester, find.text('28 px'));
    expect(container.read(lyricsSizeProvider).valueOrNull, 28);

    // Open About dialog
    await tapVisible(tester, find.text('Tentang LyricWave'));
    expect(find.byType(AlertDialog), findsOneWidget);

    // Escape closes dialog
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    // Open Data di perangkat dialog
    await tapVisible(tester, find.text('Data di perangkat'));
    await tapVisible(tester, find.text('Tutup'));

    // Keyboard tab focus
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);

    // Instrumental song without lyrics
    container.read(routerProvider).go('/song/hening');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lyrics are currently unavailable.'),
      250,
    );
    expect(find.text('Lyrics are currently unavailable.'), findsOneWidget);

    // Unknown route
    container.read(routerProvider).go('/unknown');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Buka beranda'));
    expect(find.text('LyricWave'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 900.0]) {
    testWidgets('all screens reflow at ${width.toInt()}px', (tester) async {
      final container = await boot(tester, width: width);
      for (final path in [
        '/',
        '/search',
        '/favorites',
        '/profile',
        '/song/nina',
        '/artist/senja',
        '/history',
      ]) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
    });
  }

  testWidgets(
    '200 percent text scaling and 500 lyric lines remain scrollable',
    (tester) async {
      final container = await boot(tester, width: 320, scale: 2);
      for (final path in ['/profile', '/song/nina', '/artist/senja']) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LyricsView(
                lyrics: Lyrics(
                  text: List.generate(
                    501,
                    (index) => 'Baris lirik ${index + 1}',
                  ).join('\n'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        greaterThan(0),
      );
    },
  );

  testWidgets('songs with cover render CoverArt with asset image', (
    tester,
  ) async {
    final container = await boot(tester);
    expect(find.text('Everything U Are'), findsOneWidget);
    expect(find.text('Nina'), findsWidgets);

    container.read(routerProvider).go('/song/everything-u-are');
    await tester.pumpAndSettle();
    expect(find.text('Everything U Are'), findsWidgets);
    expect(find.text('Hindia'), findsWidgets);
    expect(tester.takeException(), isNull);

    container.read(routerProvider).go('/song/nina');
    await tester.pumpAndSettle();
    expect(find.text('Nina'), findsWidgets);
    expect(find.text('.Feast'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('verify nina.png asset is bundled and readable', () async {
    final data = await rootBundle.load('assets/cover/nina.png');
    expect(data.lengthInBytes, greaterThan(0));
  });

  test('verify logo.png asset is bundled and readable', () async {
    final data = await rootBundle.load('assets/logo/logo.png');
    expect(data.lengthInBytes, greaterThan(0));
  });

  test('verify honeybee.png asset is bundled and readable', () async {
    final data = await rootBundle.load('assets/cover/honeybee.png');
    expect(data.lengthInBytes, greaterThan(0));
  });

  test('verify honeybee mp3 audio asset is bundled and readable', () async {
    final data = await rootBundle.load(
      'assets/audio/Olivia Rodrigo - honeybee (Full Official Audio) [HQ].mp3',
    );
    expect(data.lengthInBytes, greaterThan(0));
  });

  testWidgets('honeybee song details and lyrics render correctly', (
    tester,
  ) async {
    final container = await boot(tester);
    container.read(routerProvider).go('/song/honeybee');
    await tester.pumpAndSettle();

    expect(find.text('Honeybee'), findsWidgets);
    expect(find.text('Olivia Rodrigo'), findsWidgets);
    expect(find.textContaining('Baby boy, honeybee'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CoverArt displays Image widget when url is asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverArt(
            title: 'Nina',
            url: 'assets/cover/nina.png',
            size: 240,
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Sampul tidak tersedia'), findsNothing);
  });

  testWidgets(
    'mini player appears on Beranda, Cari, Favorit, and Profil when playing, and supports pause and next',
    (tester) async {
      late SongAudioController player;
      final container = await boot(
        tester,
        overrides: [
          songPlayerProvider.overrideWith((ref) {
            player = SongAudioController(
              createPlayer: (owner) => _WidgetFakeMusicPlayer(owner),
            );
            return player;
          }),
        ],
      );
      final nina = mockSongs.firstWhere((s) => s.id == 'nina');
      addTearDown(() {
        player.stop();
      });

      // Initially no song playing
      expect(find.text('Lagu selanjutnya'), findsNothing);

      // Simulate playback started (e.g. playing nina)
      player.currentSong = nina;
      player.updateStatus(PlaybackStatus.playing);
      await tester.pumpAndSettle();

      // Appears on Beranda ('/')
      expect(find.text('Nina'), findsWidgets);
      expect(find.text('.Feast'), findsWidgets);
      expect(find.byTooltip('Jeda'), findsOneWidget);
      expect(find.byTooltip('Lagu selanjutnya'), findsOneWidget);

      // Appears on Cari ('/search')
      container.read(routerProvider).go('/search');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Jeda'), findsOneWidget);
      expect(find.byTooltip('Lagu selanjutnya'), findsOneWidget);

      // Appears on Favorit ('/favorites')
      container.read(routerProvider).go('/favorites');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Jeda'), findsOneWidget);
      expect(find.byTooltip('Lagu selanjutnya'), findsOneWidget);

      // Appears on Profil ('/profile')
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Jeda'), findsOneWidget);
      expect(find.byTooltip('Lagu selanjutnya'), findsOneWidget);

      // Test pause from mini player
      await tapVisible(tester, find.byTooltip('Jeda'));
      expect(player.status, PlaybackStatus.paused);
      expect(find.byTooltip('Putar lagu'), findsOneWidget);

      // Test resume from mini player
      await tapVisible(tester, find.byTooltip('Putar lagu'));
      expect(player.status, PlaybackStatus.playing);
      expect(find.byTooltip('Jeda'), findsOneWidget);

      // Test next to next song
      await tapVisible(tester, find.byTooltip('Lagu selanjutnya'));
      expect(player.songId, isNotNull);

      // Test tapping mini player navigates to detail
      await tapVisible(tester, find.text(player.currentSong!.title).first);
      expect(find.text('Detail lagu'), findsOneWidget);
    },
  );
}
