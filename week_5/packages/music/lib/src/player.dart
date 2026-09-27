import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'music.dart';
import 'shared.dart';

/// Music Player
class MusicPlayer {
  MethodChannel channel = MethodChannel('salkuadrat/musicplayer');

  /// Callback to be called when loading music
  final void Function()? onLoading;

  /// Callback to be called when playing music
  final void Function()? onPlaying;

  /// Callback to be called when music is paused
  final void Function()? onPaused;

  /// Callback to be called when music is stopped
  final void Function()? onStopped;

  /// Callback to be called when music is ended
  final void Function()? onCompleted;

  /// Callback to be called when play next music
  final void Function()? onPlayNext;

  /// Callback to be called when play previous music
  final void Function()? onPlayPrevious;

  /// Callback to be called when computed duration is available
  final void Function(Duration)? onDuration;

  /// Callback to be called for updating position
  final void Function(Duration)? onPosition;

  /// Callback to be called when error
  final void Function(String)? onError;

  MusicPlayer({
    this.onLoading,
    this.onPlaying,
    this.onPaused,
    this.onStopped,
    this.onCompleted,
    this.onPlayNext,
    this.onPlayPrevious,
    this.onDuration,
    this.onPosition,
    this.onError,
  }) {
    _init();
  }

  void _init() {
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onDuration':
          int duration = (call.arguments as num).round();
          onDuration?.call(Duration(milliseconds: duration));
          break;
        case 'onPosition':
          int position = (call.arguments as num).round();
          onPosition?.call(Duration(milliseconds: position));
          break;
        case 'onPlayPrevious':
          onPlayPrevious?.call();
          break;
        case 'onPlayNext':
          onPlayNext?.call();
          break;
        case 'onLoading':
          onLoading?.call();
          break;
        case 'onPlaying':
          onPlaying?.call();
          break;
        case 'onPaused':
          onPaused?.call();
          break;
        case 'onStopped':
          onStopped?.call();
          break;
        case 'onCompleted':
          onCompleted?.call();
          break;
        case 'onError':
          String message = call.arguments as String;
          onError?.call(message);
          break;
        default:
          debugPrint('Unknown method ${call.method}');
      }
    });
  }

  /// Prepare music before real playing (if we want to show loading notification)
  Future<void> prepare(Music music) async {
    String image = await _artwork(music.image);
    onDuration?.call(Duration(milliseconds: 0));
    onPosition?.call(Duration(milliseconds: 0));
    await channel.invokeMethod('prepare', <String, dynamic>{
      'id': music.id,
      'title': music.title,
      'url': music.url,
      'album': music.album,
      'artist': music.artist,
      'duration': music.duration?.inMilliseconds ?? 0,
      'imageUrl': music.image,
      'image': image,
    });
  }

  /// Play the music
  Future<void> play(Music music,
      {bool showPrevious = false, bool showNext = false}) async {
    final url = music.url.startsWith('assets/')
        ? (kIsWeb ? 'assets/${music.url}' : await resolveAudioAsset(music.url))
        : music.url;
    String image = await _artwork(music.image);

    onDuration?.call(Duration(milliseconds: 0));
    onPosition?.call(Duration(milliseconds: 0));
    await channel.invokeMethod('play', <String, dynamic>{
      'id': music.id,
      'title': music.title,
      'url': url,
      'album': music.album,
      'artist': music.artist,
      'duration': music.duration?.inMilliseconds ?? 0,
      'imageUrl': music.image,
      'image': image,
      'showPrevious': showPrevious,
      'showNext': showNext,
    });
  }

  Future<String> _artwork(String url) async {
    if (kIsWeb || url.isEmpty) return '';
    try {
      return await download(url).timeout(const Duration(seconds: 8));
    } catch (_) {
      return '';
    }
  }

  /// Pause current music
  Future<void> pause() async {
    await channel.invokeMethod('pause');
  }

  /// Resume current music
  Future<void> resume() async {
    await channel.invokeMethod('resume');
  }

  /// Stop playing
  Future<void> stop() async {
    await channel.invokeMethod('stop');
  }

  /// Seek to play on specified position
  Future<void> seek(Duration position) async {
    await channel.invokeMethod('seek', position.inMilliseconds);
  }

  /// Cancel notification
  Future<void> cancel() async {
    await channel.invokeMethod('cancel');
  }

  /// Dispose
  Future<void> dispose() async {
    await channel.invokeMethod('dispose');
  }
}
