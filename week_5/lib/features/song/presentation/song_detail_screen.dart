import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/music.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'song_audio_controller.dart';
import 'song_audio_player.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  const SongDetailScreen({super.key, required this.songId});
  final String songId;

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(songDetailProvider(widget.songId), (previous, next) {
      final song = next.valueOrNull;
      if (song == null || _recorded) return;
      _recorded = true;
      ref.read(libraryActionsProvider.notifier).recordView(song).catchError((
        Object error,
      ) {
        if (mounted) showFailure(context, error);
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(songPlayerProvider);
    final isCurrentSong = player.songId == widget.songId;
    final currentPosition = isCurrentSong ? player.position : Duration.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail lagu')),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: AsyncContent(
            value: ref.watch(songDetailProvider(widget.songId)),
            onRetry: () => ref.invalidate(songDetailProvider(widget.songId)),
            data: (song) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SongHeader(song: song),
                SongAudioPlayer(song: song),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lirik',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.text_fields, size: 20),
                      label: const Text('Ukuran teks'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AsyncContent(
                  value: ref.watch(lyricsProvider(widget.songId)),
                  loadingLabel: 'Memuat lirik',
                  onRetry: () => ref.invalidate(lyricsProvider(widget.songId)),
                  data: (lyrics) => LyricsView(
                    lyrics: lyrics,
                    currentPosition: currentPosition,
                    fontSize: ref.watch(lyricsSizeProvider).valueOrNull ?? 24,
                    onSeek: isCurrentSong
                        ? (pos) => ref.read(songPlayerProvider).seek(pos)
                        : null,
                  ),
                ),
                const Divider(),
              Text(
                'Tentang lagu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _Metadata(
                label: 'Album',
                value: song.album?.title ?? 'Belum tersedia',
              ),
              _Metadata(
                label: 'Tahun rilis',
                value:
                    (song.releaseYear ?? song.album?.releaseYear)?.toString() ??
                    'Belum tersedia',
              ),
              _Metadata(label: 'Genre', value: song.genre ?? 'Belum tersedia'),
              _Metadata(label: 'Durasi', value: formatDuration(song.duration)),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _SongHeader extends StatelessWidget {
  const _SongHeader({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cover = CoverArt(
        title: song.album?.title ?? song.title,
        url: song.coverUrl ?? song.album?.coverUrl,
        size: constraints.maxWidth < 280 ? constraints.maxWidth : 240,
        isDemo: song.isDemo,
      );
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (song.isDemo)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Lagu demo',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          Text(song.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                context.push('/artist/${Uri.encodeComponent(song.artist.id)}'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    song.artist.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FavoriteButton(song: song),
              const SizedBox(width: 8),
              const Flexible(child: Text('Simpan ke koleksi favorit')),
            ],
          ),
        ],
      );
      if (constraints.maxWidth >= 600) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cover,
            const SizedBox(width: 32),
            Expanded(child: info),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: cover),
          const SizedBox(height: 24),
          info,
        ],
      );
    },
  );
}

class LyricsView extends StatelessWidget {
  const LyricsView({
    super.key,
    required this.lyrics,
    this.currentPosition = Duration.zero,
    this.fontSize = 24,
    this.onSeek,
  });

  final Lyrics lyrics;
  final Duration currentPosition;
  final double fontSize;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final lines = lyrics.lines;
    if (lines.isEmpty) {
      return const EmptyState(
        title: 'Lirik belum tersedia',
        message: 'Lyrics are currently unavailable.',
        icon: Icons.lyrics_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          if (lines[i].text.isEmpty)
            const SizedBox(height: 16)
          else ...[
            _LyricLineItem(
              line: lines[i],
              fontSize: fontSize,
              isSung: currentPosition >= lines[i].startTime,
              isCurrent: currentPosition >= lines[i].startTime &&
                  (i == lines.length - 1 ||
                      _isNextLineAfter(lines, i + 1, currentPosition)),
              onTap: onSeek != null ? () => onSeek!(lines[i].startTime) : null,
            ),
            const SizedBox(height: 6),
          ],
        ],
        if (lyrics.attribution?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              lyrics.attribution!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  static bool _isNextLineAfter(
    List<LyricLine> lines,
    int nextIndex,
    Duration currentPosition,
  ) {
    for (int j = nextIndex; j < lines.length; j++) {
      if (lines[j].text.isNotEmpty) {
        return currentPosition < lines[j].startTime;
      }
    }
    return false;
  }
}

class _LyricLineItem extends StatelessWidget {
  const _LyricLineItem({
    required this.line,
    required this.fontSize,
    required this.isSung,
    required this.isCurrent,
    this.onTap,
  });

  final LyricLine line;
  final double fontSize;
  final bool isSung;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSung ? AppColors.textPrimary : AppColors.muted;
    final fontWeight = isCurrent
        ? FontWeight.w700
        : isSung
        ? FontWeight.w600
        : FontWeight.w500;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: isCurrent
          ? 'Sedang dinyanyikan: ${line.text}'
          : isSung
          ? 'Sudah dinyanyikan: ${line.text}'
          : 'Belum dinyanyikan: ${line.text}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: 1.5,
              color: color,
            ),
            child: Text(line.text),
          ),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}
