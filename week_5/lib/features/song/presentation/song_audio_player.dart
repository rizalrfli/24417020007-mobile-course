import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/song_audio_sources.dart';
import '../../../shared/models/music.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'audio_wave_bar.dart';
import 'song_audio_controller.dart';
import 'spotify_player.dart';

class SongAudioPlayer extends ConsumerWidget {
  const SongAudioPlayer({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotifyUrl = songSpotifyEmbeds[song.id];
    if (spotifyUrl != null) {
      return SpotifyPlayer(key: ValueKey(song.id), url: spotifyUrl);
    }
    final source = ref.watch(songAudioSourceProvider(song.id));
    return source.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Memeriksa audio...'),
      ),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(songAudioSourceProvider(song.id)),
        child: const Text('Gagal memuat audio. Coba lagi'),
      ),
      data: (path) => path == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Audio lagu belum tersedia.'),
            )
          : _Controls(song: song, source: path),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.song, required this.source});
  final Song song;
  final String source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SongAudioController.supported) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Putar lagu melalui Android, iOS, atau browser.'),
      );
    }
    final player = ref.watch(songPlayerProvider);
    final active = player.songId == song.id;
    final status = active ? player.status : PlaybackStatus.idle;
    final duration = active ? player.duration : Duration.zero;
    final position = active ? player.position : Duration.zero;
    final loading = status == PlaybackStatus.loading;
    final playing = status == PlaybackStatus.playing;
    final canSeek =
        duration > Duration.zero &&
        (playing || status == PlaybackStatus.paused);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (playing) ...[
            const AudioWaveform(isPlaying: true),
            const SizedBox(height: 12),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              IconButton(
                iconSize: 32,
                tooltip: 'Lagu sebelumnya',
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: loading || player.busy
                    ? null
                    : () => player.previous(),
              ),
              FilledButton.icon(
                onPressed: loading || player.busy
                    ? null
                    : () => player.toggle(song, source),
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  loading
                      ? 'Memuat lagu...'
                      : playing
                      ? 'Jeda'
                      : 'Putar lagu',
                ),
              ),
              IconButton(
                iconSize: 32,
                tooltip: 'Lagu selanjutnya',
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: loading || player.busy
                    ? null
                    : () => player.next(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: position.inMilliseconds.toDouble().clamp(
              0,
              duration.inMilliseconds.toDouble(),
            ),
            max: duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1,
            semanticFormatterCallback: (value) =>
                formatDuration(Duration(milliseconds: value.round())),
            onChanged: canSeek
                ? (value) => player.seek(Duration(milliseconds: value.round()))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${formatDuration(position)} / ${duration > Duration.zero ? formatDuration(duration) : '--:--'}',
            ),
          ),
          if (status == PlaybackStatus.failed)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Audio gagal diputar. Coba lagi atau periksa file lagunya.',
              ),
            ),
        ],
      ),
    );
  }
}
