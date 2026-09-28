import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music/music.dart';
import 'package:week_5/app/router.dart';
import 'package:week_5/features/song/presentation/audio_wave_bar.dart';
import 'package:week_5/features/song/presentation/song_audio_controller.dart';
import 'package:week_5/features/song/presentation/song_audio_player.dart';
import 'package:week_5/features/song/presentation/song_detail_screen.dart';
import 'package:week_5/shared/data/mock_data.dart';
import 'package:week_5/shared/data/song_audio_sources.dart';
import 'package:week_5/shared/models/music.dart';

class FakeMusicPlayer extends MusicPlayer {
  FakeMusicPlayer(this.controller);
  final SongAudioController controller;
  final calls = <String>[];
  Music? current;
  bool shouldFail = false;

  @override
  Future<void> play(
    Music music, {
    bool showPrevious = false,
    bool showNext = false,
  }) async {
    calls.add('play:${music.id}');
    if (shouldFail) throw StateError('Network unavailable');
    current = music;
    controller.updateDuration(const Duration(seconds: 287));
    controller.updateStatus(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    controller.updateStatus(PlaybackStatus.paused);
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    controller.updateStatus(PlaybackStatus.playing);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    controller.updateStatus(PlaybackStatus.idle);
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek:${position.inSeconds}');
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SongAudioController controller;
  late FakeMusicPlayer backend;
  final nina = mockSongs.firstWhere((song) => song.id == 'nina');
  final akad = mockSongs.firstWhere((song) => song.id == 'akad');

  setUp(() {
    controller = SongAudioController(
      createPlayer: (owner) {
        backend = FakeMusicPlayer(owner);
        return backend;
      },
    );
  });
  tearDown(() => controller.dispose());

  test(
    'plays matching audio, pauses, resumes, and clamps seek to audio duration',
    () async {
      await controller.toggle(nina, songAudioAssets['nina']!);
      expect(backend.current!.url, songAudioAssets['nina']!);
      expect(backend.current!.artist, '.Feast');
      expect(controller.status, PlaybackStatus.playing);
      expect(controller.duration, const Duration(seconds: 287));
      await controller.toggle(nina, songAudioAssets['nina']!);
      expect(controller.status, PlaybackStatus.paused);
      await controller.toggle(nina, songAudioAssets['nina']!);
      await controller.seek(const Duration(minutes: 10));
      expect(backend.calls, ['play:nina', 'pause', 'resume', 'seek:287']);
    },
  );

  test(
    'stops old song before playing another and clears state on stop',
    () async {
      await controller.toggle(nina, songAudioAssets['nina']!);
      await controller.toggle(akad, songAudioAssets['akad']!);
      expect(backend.calls, ['play:nina', 'stop', 'play:akad']);
      expect(controller.songId, 'akad');
      await controller.stop();
      expect(controller.songId, isNull);
      expect(controller.position, Duration.zero);
    },
  );

  test(
    'network failure can be retried and duplicate taps are ignored',
    () async {
      backend.shouldFail = true;
      await controller.toggle(nina, songAudioAssets['nina']!);
      expect(controller.status, PlaybackStatus.failed);
      expect(controller.busy, isFalse);
      backend.shouldFail = false;
      await Future.wait([
        controller.toggle(nina, songAudioAssets['nina']!),
        controller.toggle(nina, songAudioAssets['nina']!),
      ]);
      expect(controller.status, PlaybackStatus.playing);
      expect(backend.calls.where((call) => call == 'play:nina').length, 2);
    },
  );

  test('missing audio does not call native player', () async {
    await controller.toggle(
      mockSongs.firstWhere((song) => song.id == 'peradaban'),
      '',
    );
    expect(backend.calls, isEmpty);
  });

  testWidgets(
    'player controls reflect playback and remain usable at large text size',
    (tester) async {
      controller.dispose();
      controller = SongAudioController(
        createPlayer: (owner) {
          backend = FakeMusicPlayer(owner);
          return backend;
        },
      );
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            songPlayerProvider.overrideWith((ref) => controller),
            songAudioSourceProvider(
              'nina',
            ).overrideWith((ref) async => songAudioAssets['nina']),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(child: SongAudioPlayer(song: nina)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Putar lagu'));
      await tester.pumpAndSettle();
      expect(find.text('Jeda'), findsOneWidget);
      expect(find.text('0:00 / 4:47'), findsOneWidget);
      await tester.tap(find.text('Jeda'));
      await tester.pumpAndSettle();
      expect(controller.status, PlaybackStatus.paused);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('togglePlayPause pauses when playing and resumes when paused', () async {
    await controller.toggle(nina, songAudioAssets['nina']!);
    expect(controller.status, PlaybackStatus.playing);

    await controller.togglePlayPause();
    expect(controller.status, PlaybackStatus.paused);
    expect(backend.calls.last, 'pause');

    await controller.togglePlayPause();
    expect(controller.status, PlaybackStatus.playing);
    expect(backend.calls.last, 'resume');
  });

  test('next advances to next song with audio in playlist', () async {
    await controller.toggle(nina, songAudioAssets['nina']!);
    expect(controller.songId, 'nina');

    await controller.next();
    expect(controller.songId, 'peradaban');
    expect(backend.calls.last, 'play:peradaban');

    await controller.next();
    expect(controller.songId, 'akad');
    expect(backend.calls.last, 'play:akad');
  });

  test('previous advances to previous song with audio in playlist', () async {
    await controller.toggle(nina, songAudioAssets['nina']!);
    expect(controller.songId, 'nina');

    await controller.previous();
    expect(controller.songId, 'honeybee');
    expect(backend.calls.last, 'play:honeybee');

    await controller.previous();
    expect(controller.songId, 'everything-u-are');
    expect(backend.calls.last, 'play:everything-u-are');
  });

  testWidgets(
    'wave animation appears above next prev pause controls when audio plays',
    (tester) async {
      controller.dispose();
      controller = SongAudioController(
        createPlayer: (owner) {
          backend = FakeMusicPlayer(owner);
          return backend;
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            songPlayerProvider.overrideWith((ref) => controller),
            songAudioSourceProvider(
              'nina',
            ).overrideWith((ref) async => songAudioAssets['nina']),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: SongAudioPlayer(song: nina)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before playing: no wave animation
      expect(find.byType(AudioWaveform), findsNothing);
      expect(find.byTooltip('Lagu sebelumnya'), findsOneWidget);
      expect(find.byTooltip('Lagu selanjutnya'), findsOneWidget);
      expect(find.text('Putar lagu'), findsOneWidget);

      // Tap play
      await tester.tap(find.text('Putar lagu'));
      await tester.pumpAndSettle();

      // While playing: wave animation is present above next, prev, and pause
      expect(find.byType(AudioWaveform), findsOneWidget);
      expect(find.text('Jeda'), findsOneWidget);

      // Tap pause
      await tester.tap(find.text('Jeda'));
      await tester.pumpAndSettle();

      // When paused: wave animation disappears
      expect(find.byType(AudioWaveform), findsNothing);
      expect(find.text('Putar lagu'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('AudioWaveform renders active wave and semantics when playing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AudioWaveform(isPlaying: true, animate: true),
        ),
      ),
    );
    expect(find.byType(AudioWaveform), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(
      find.bySemanticsLabel('Animasi gelombang audio sedang berjalan'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'lyrics synchronization turns lines white one by one as song is sung',
    (tester) async {
      const sampleLyrics = Lyrics(
        timedLines: [
          LyricLine(startTime: Duration(seconds: 10), text: 'Baris pertama'),
          LyricLine(startTime: Duration(seconds: 20), text: 'Baris kedua'),
          LyricLine(startTime: Duration(seconds: 30), text: 'Baris ketiga'),
        ],
      );

      // At position 0s: no lines sung yet, all are grey
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LyricsView(
              lyrics: sampleLyrics,
              currentPosition: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Belum dinyanyikan: Baris pertama'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Belum dinyanyikan: Baris kedua'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Belum dinyanyikan: Baris ketiga'),
        findsOneWidget,
      );

      // At position 12s: first line starts singing -> turns white
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LyricsView(
              lyrics: sampleLyrics,
              currentPosition: Duration(seconds: 12),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Sedang dinyanyikan: Baris pertama'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Belum dinyanyikan: Baris kedua'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Belum dinyanyikan: Baris ketiga'),
        findsOneWidget,
      );

      // At position 25s: second line starts singing -> turns white too
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LyricsView(
              lyrics: sampleLyrics,
              currentPosition: Duration(seconds: 25),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Sudah dinyanyikan: Baris pertama'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Sedang dinyanyikan: Baris kedua'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Belum dinyanyikan: Baris ketiga'),
        findsOneWidget,
      );

      // Test tapping a line calls onSeek
      Duration? seeked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LyricsView(
              lyrics: sampleLyrics,
              currentPosition: Duration.zero,
              onSeek: (pos) => seeked = pos,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Baris kedua'));
      expect(seeked, const Duration(seconds: 20));
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('honeybee has configured audio asset and resolves properly', () async {
    final honeybee = mockSongs.firstWhere((s) => s.id == 'honeybee');
    expect(songAudioAssets[honeybee.id], isNotNull);
    expect(
      songAudioAssets[honeybee.id],
      'assets/audio/Olivia Rodrigo - honeybee (Full Official Audio) [HQ].mp3',
    );
    expect(songSpotifyEmbeds[honeybee.id], isNull);
  });

  test('navigation to main tabs keeps playback alive for mini player', () async {
    final calls = <String>[];
    const channel = MethodChannel('salkuadrat/musicplayer');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });
    final container = ProviderContainer();
    final router = container.read(routerProvider);
    final player = container.read(songPlayerProvider);
    router.go('/song/nina');
    player.songId = 'nina';
    player.updateStatus(PlaybackStatus.playing);

    for (final path in ['/', '/search', '/favorites', '/profile']) {
      router.go(path);
      await Future<void>.delayed(Duration.zero);
      expect(calls, isNot(contains('stop')));
      expect(player.songId, 'nina');
      expect(player.status, PlaybackStatus.playing);
    }

    container.dispose();
    await Future<void>.delayed(Duration.zero);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
