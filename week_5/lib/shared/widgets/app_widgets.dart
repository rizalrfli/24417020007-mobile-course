import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../models/music.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: child,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.title,
    this.url,
    this.size = 56,
    this.isDemo = false,
    this.circle = false,
  });
  final String title;
  final String? url;
  final double size;
  final bool isDemo;
  final bool circle;

  Widget _placeholder(BuildContext context) => Container(
    color: isDemo ? AppColors.darkBlue : AppColors.elevatedSurface,
    padding: EdgeInsets.all(size >= 120 ? 16 : 8),
    child: size >= 120
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            isDemo ? 'Sampul demo' : 'Sampul tidak tersedia',
            textScaler: TextScaler.noScaling,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
          Text(
            title,
            textScaler: TextScaler.noScaling,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: size >= 240 ? 32 : 20,
                  height: 1.1,
                ),
              ),
            ],
          )
        : Center(
            child: Icon(
              circle ? Icons.person_outline : Icons.music_note_outlined,
              color: AppColors.textPrimary,
              size: size < 60 ? 24 : 36,
            ),
          ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${circle ? 'Foto' : 'Sampul'} $title${isDemo ? ', demo' : ''}',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(circle ? 999 : 12),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url!.isEmpty
            ? _placeholder(context)
            : (url!.startsWith('http://') || url!.startsWith('https://'))
                ? CachedNetworkImage(
                    imageUrl: url!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) => _placeholder(context),
                  )
                : Image.asset(
                    url!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) => Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(context),
                    ),
                  ),
      ),
    ),
  );
}

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.number,
    this.showFavorite = false,
  });
  final Song song;
  final int? number;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/song/${Uri.encodeComponent(song.id)}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (number != null) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    number!.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              CoverArt(
                title: song.title,
                url: song.coverUrl ?? song.album?.coverUrl,
                isDemo: song.isDemo,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (showFavorite)
                FavoriteButton(song: song)
              else
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.chevron_right, size: 20),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SongCard extends StatelessWidget {
  const SongCard({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 148,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/song/${Uri.encodeComponent(song.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoverArt(
                title: song.title,
                url: song.coverUrl ?? song.album?.coverUrl,
                size: 140,
                isDemo: song.isDemo,
              ),
              const SizedBox(height: 12),
              Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SongShelf extends StatelessWidget {
  const SongShelf({super.key, required this.songs});
  final List<Song> songs;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final song in songs)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SongCard(song: song),
            ),
        ],
      ),
    ),
  );
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteSongsProvider);
    final busy = ref.watch(libraryActionsProvider).contains(song.id);
    final selected =
        favorites.valueOrNull?.any((s) => s.id == song.id) ?? false;
    return IconButton(
      tooltip: favorites.hasError
          ? 'Muat ulang favorit'
          : selected
          ? 'Hapus ${song.title} dari favorit'
          : 'Simpan ${song.title} ke favorit',
      onPressed: busy || favorites.isLoading
          ? null
          : () async {
              if (favorites.hasError) {
                ref.invalidate(favoriteSongsProvider);
                return;
              }
              try {
                await ref
                    .read(libraryActionsProvider.notifier)
                    .setFavorite(song, !selected);
              } catch (error) {
                if (context.mounted) showFailure(context, error);
              }
            },
      icon: Icon(
        selected ? Icons.favorite : Icons.favorite_border,
        color: selected ? AppColors.active : AppColors.textSecondary,
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Judul lagu, artis, atau album',
    this.label = 'Cari lagu',
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Hapus pencarian',
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.library_music_outlined,
    this.action,
    this.onAction,
  });
  final String title;
  final String message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (onAction != null) ...[
          const SizedBox(height: 20),
          FilledButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Belum bisa memuat data',
  });
  final Object error;
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: EmptyState(
      title: title,
      message: errorMessage(error),
      icon: Icons.cloud_off_outlined,
      action: 'Coba lagi',
      onAction: onRetry,
    ),
  );
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.label = 'Memuat lagu', this.rows = 4});
  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, color: AppColors.elevatedSurface),
                        const SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: .6,
                          child: Container(height: 8, color: AppColors.surface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.loadingLabel = 'Memuat lagu',
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback onRetry;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    data: data,
    loading: () => LoadingSkeleton(label: loadingLabel),
    error: (error, _) => ErrorState(error: error, onRetry: onRetry),
  );
}

String errorMessage(Object error) {
  if (error is Exception) {
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return msg;
  }
  return 'Terjadi kendala saat memuat data. Silakan coba lagi.';
}

void showFailure(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
}

String formatDuration(Duration? duration) => duration == null
    ? 'Belum tersedia'
    : '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
