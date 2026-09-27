import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'song_audio_controller.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(songPlayerProvider);
    final song = player.currentSong;
    if (song == null || player.status == PlaybackStatus.idle) {
      return const SizedBox.shrink();
    }

    final isPlaying = player.status == PlaybackStatus.playing;
    final isLoading = player.status == PlaybackStatus.loading;
    final progress = player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      container: true,
      label: 'Pemutar lagu mini: ${song.title} oleh ${song.artist.name}',
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.elevatedSurface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.duration > Duration.zero)
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            InkWell(
              onTap: () =>
                  context.push('/song/${Uri.encodeComponent(song.id)}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    CoverArt(
                      title: song.title,
                      url: song.coverUrl ?? song.album?.coverUrl,
                      size: 44,
                      isDemo: song.isDemo,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      iconSize: 28,
                      tooltip: 'Lagu sebelumnya',
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: player.busy || isLoading
                          ? null
                          : () => player.previous(),
                    ),
                    IconButton(
                      iconSize: 28,
                      tooltip: isLoading
                          ? 'Memuat lagu'
                          : isPlaying
                          ? 'Jeda'
                          : 'Putar lagu',
                      icon: isLoading
                          ? const Icon(
                              Icons.hourglass_top_rounded,
                              color: AppColors.textSecondary,
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppColors.textPrimary,
                            ),
                      onPressed: player.busy || isLoading
                          ? null
                          : () => player.togglePlayPause(),
                    ),
                    IconButton(
                      iconSize: 28,
                      tooltip: 'Lagu selanjutnya',
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: player.busy || isLoading
                          ? null
                          : () => player.next(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
