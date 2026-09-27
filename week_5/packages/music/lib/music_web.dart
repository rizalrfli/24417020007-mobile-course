import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

class MusicWeb {
  MusicWeb(this.channel) {
    audio.addEventListener(
        'playing', ((web.Event _) => emit('onPlaying')).toJS);
    audio.addEventListener('pause', ((web.Event _) => emit('onPaused')).toJS);
    audio.addEventListener(
        'waiting', ((web.Event _) => emit('onLoading')).toJS);
    audio.addEventListener(
        'ended', ((web.Event _) => emit('onCompleted')).toJS);
    audio.addEventListener(
        'error', ((web.Event _) => emit('onError', 'Playback failed')).toJS);
    audio.addEventListener(
        'durationchange',
        ((web.Event _) {
          if (audio.duration.isFinite) {
            emit('onDuration', (audio.duration * 1000).round());
          }
        }).toJS);
    audio.addEventListener(
        'timeupdate',
        ((web.Event _) {
          emit('onPosition', (audio.currentTime * 1000).round());
        }).toJS);
  }

  final MethodChannel channel;
  final web.HTMLAudioElement audio = web.HTMLAudioElement()..preload = 'none';

  static void registerWith(Registrar registrar) {
    final channel = MethodChannel(
        'salkuadrat/musicplayer', const StandardMethodCodec(), registrar);
    final plugin = MusicWeb(channel);
    channel.setMethodCallHandler(plugin.handle);
  }

  void emit(String method, [Object? value]) {
    channel.invokeMethod<void>(method, value);
  }

  Future<void> handle(MethodCall call) async {
    switch (call.method) {
      case 'play':
        audio.src = (call.arguments as Map)['url'] as String;
        emit('onLoading');
        await audio.play().toDart;
        break;
      case 'pause':
        audio.pause();
        break;
      case 'resume':
        await audio.play().toDart;
        break;
      case 'seek':
        audio.currentTime = (call.arguments as num).toDouble() / 1000;
        break;
      case 'stop':
      case 'dispose':
        audio.pause();
        audio.removeAttribute('src');
        audio.load();
        emit('onStopped');
        break;
      case 'prepare':
      case 'cancel':
        break;
      default:
        throw MissingPluginException('Unknown music method: ${call.method}');
    }
  }
}
