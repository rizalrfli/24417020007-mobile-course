import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music/music.dart';

import '../../../shared/data/mock_data.dart';
import '../../../shared/data/song_audio_sources.dart';
import '../../../shared/models/music.dart';

final songPlayerProvider = ChangeNotifierProvider<SongAudioController>((ref) {
  final controller = SongAudioController(
    resolveSource: (songId) async {
      return await ref.read(songAudioSourceProvider(songId).future);
    },
    getPlaylist: () => mockSongs,
  );
  return controller;
});

enum PlaybackStatus { idle, loading, playing, paused, failed }

class SongAudioController extends ChangeNotifier {
  SongAudioController({
    MusicPlayer Function(SongAudioController)? createPlayer,
    this.resolveSource,
    this.getPlaylist,
  }) {
    _player =
        createPlayer?.call(this) ??
        MusicPlayer(
          onLoading: () => updateStatus(PlaybackStatus.loading),
          onPlaying: () => updateStatus(PlaybackStatus.playing),
          onPaused: () => updateStatus(PlaybackStatus.paused),
          onStopped: () => updateStatus(PlaybackStatus.idle),
          onCompleted: () {
            position = Duration.zero;
            updateStatus(PlaybackStatus.idle);
          },
          onDuration: updateDuration,
          onPosition: updatePosition,
          onError: (_) => fail(),
        );
  }

  final Future<String?> Function(String songId)? resolveSource;
  final List<Song> Function()? getPlaylist;

  late final MusicPlayer _player;
  Song? _currentSong;
  String? _songId;

  Song? get currentSong => _currentSong;
  set currentSong(Song? song) {
    _currentSong = song;
    _songId = song?.id;
  }

  String? get songId => _currentSong?.id ?? _songId;
  set songId(String? value) {
    _songId = value;
    if (value == null) {
      _currentSong = null;
    } else {
      _currentSong = mockSongs.cast<Song?>().firstWhere(
        (s) => s?.id == value,
        orElse: () => null,
      );
    }
  }

  PlaybackStatus status = PlaybackStatus.idle;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool busy = false;
  bool _disposed = false;
  Timer? _loadingTimer;
  Future<void> _pending = Future.value();

  static bool get supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void updateStatus(PlaybackStatus value) {
    if (_disposed || songId == null) return;
    status = value;
    _loadingTimer?.cancel();
    if (value == PlaybackStatus.loading) {
      _loadingTimer = Timer(const Duration(seconds: 20), () {
        unawaited(
          _run(() async {
            await _player.stop();
            fail();
          }),
        );
      });
    }
    _notify();
  }

  void updateDuration(Duration value) {
    duration = value;
    _notify();
  }

  void updatePosition(Duration value) {
    position = value;
    _notify();
  }

  void fail() => updateStatus(PlaybackStatus.failed);

  Future<void> _run(Future<void> Function() action) {
    _pending = _pending.then((_) async {
      if (_disposed) return;
      try {
        await action();
      } catch (_) {
        fail();
      }
    });
    return _pending;
  }

  Future<void> playSong(Song song, String source) async {
    if (source.isEmpty || busy) return;
    busy = true;
    _notify();
    await _run(() async {
      if (songId != null) await _player.stop();
      currentSong = song;
      duration = Duration.zero;
      position = Duration.zero;
      updateStatus(PlaybackStatus.loading);
      await _player.play(
        Music(
          id: song.id,
          title: song.title,
          artist: song.artist.name,
          album: song.album?.title,
          url: source,
          image: '',
        ),
      );
    });
    busy = false;
    _notify();
  }

  Future<void> toggle(Song song, String source) async {
    if (source.isEmpty || busy || status == PlaybackStatus.loading) return;
    if (songId == song.id) {
      if (status == PlaybackStatus.playing) {
        busy = true;
        _notify();
        await _run(() => _player.pause());
        busy = false;
        _notify();
      } else if (status == PlaybackStatus.paused) {
        busy = true;
        _notify();
        await _run(() => _player.resume());
        busy = false;
        _notify();
      } else {
        await playSong(song, source);
      }
    } else {
      await playSong(song, source);
    }
  }

  Future<void> pause() => _run(() async {
    if (status == PlaybackStatus.playing) {
      await _player.pause();
    }
  });

  Future<void> resume() => _run(() async {
    if (status == PlaybackStatus.paused) {
      await _player.resume();
    }
  });

  Future<void> togglePlayPause() async {
    if (busy || status == PlaybackStatus.loading || currentSong == null) return;
    if (status == PlaybackStatus.playing) {
      busy = true;
      _notify();
      await _run(() => _player.pause());
      busy = false;
      _notify();
    } else if (status == PlaybackStatus.paused) {
      busy = true;
      _notify();
      await _run(() => _player.resume());
      busy = false;
      _notify();
    }
  }

  Future<void> next() async {
    if (busy || status == PlaybackStatus.loading || currentSong == null) return;
    final playlist = getPlaylist?.call() ?? mockSongs;
    if (playlist.isEmpty) return;
    final currentIndex = playlist.indexWhere((s) => s.id == currentSong!.id);
    final count = playlist.length;

    for (int offset = 1; offset <= count; offset++) {
      final candidate = playlist[(currentIndex + offset) % count];
      String? src;
      if (resolveSource != null) {
        try {
          src = await resolveSource!(candidate.id);
        } catch (_) {
          src = null;
        }
      } else {
        src = songAudioAssets[candidate.id];
      }

      if (src != null && src.isNotEmpty) {
        await playSong(candidate, src);
        return;
      }
    }
  }

  Future<void> previous() async {
    if (busy || status == PlaybackStatus.loading || currentSong == null) return;
    final playlist = getPlaylist?.call() ?? mockSongs;
    if (playlist.isEmpty) return;
    final currentIndex = playlist.indexWhere((s) => s.id == currentSong!.id);
    final count = playlist.length;

    for (int offset = 1; offset <= count; offset++) {
      final candidate = playlist[(currentIndex - offset + count) % count];
      String? src;
      if (resolveSource != null) {
        try {
          src = await resolveSource!(candidate.id);
        } catch (_) {
          src = null;
        }
      } else {
        src = songAudioAssets[candidate.id];
      }

      if (src != null && src.isNotEmpty) {
        await playSong(candidate, src);
        return;
      }
    }
  }

  Future<void> seek(Duration value) => _run(() async {
    if (status != PlaybackStatus.playing && status != PlaybackStatus.paused) {
      return;
    }
    final clamped = Duration(
      milliseconds: value.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    await _player.seek(clamped);
    updatePosition(clamped);
  });

  Future<void> stop() => _run(() async {
    if (songId == null) return;
    await _player.stop();
    currentSong = null;
    _songId = null;
    status = PlaybackStatus.idle;
    duration = Duration.zero;
    position = Duration.zero;
    _loadingTimer?.cancel();
    _notify();
  });

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loadingTimer?.cancel();
    unawaited(
      _pending
          .then((_) async {
            if (songId != null) await _player.stop();
            await _player.dispose();
          })
          .catchError((Object _) {}),
    );
    super.dispose();
  }
}
