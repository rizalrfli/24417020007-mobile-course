import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../shared/models/music.dart';
import '../../../shared/widgets/app_widgets.dart';

class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.artistId});
  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Artis')),
    body: PageBody(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AsyncContent(
            value: ref.watch(artistProvider(artistId)),
            onRetry: () => ref.invalidate(artistProvider(artistId)),
            data: (artist) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CoverArt(
                  title: artist.name,
                  url: artist.imageUrl,
                  size: 96,
                  circle: true,
                  isDemo: artist.isDemo,
                ),
                const SizedBox(height: 20),
                Text(
                  artist.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                if (artist.isDemo)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Artis demo · Identitas contoh'),
                  ),
              ],
            ),
          ),
          AsyncContent(
            value: ref.watch(artistSongsProvider(artistId)),
            onRetry: () => ref.invalidate(artistSongsProvider(artistId)),
            data: (songs) {
              if (songs.isEmpty) {
                return const EmptyState(
                  title: 'Belum ada lagu',
                  message: 'Lagu artis ini belum tersedia di katalog.',
                );
              }
              final albums = <String, Album>{};
              for (final song in songs) {
                if (song.album != null) albums[song.album!.id] = song.album!;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Lagu populer'),
                  ...songs.map((song) => SongTile(song: song)),
                  const SectionTitle('Album'),
                  if (albums.isEmpty)
                    const Text('Informasi album belum tersedia.'),
                  ...albums.values.map(
                    (album) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          CoverArt(
                            title: album.title,
                            url: album.coverUrl,
                            size: 56,
                            isDemo: songs.first.isDemo,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  album.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (album.releaseYear != null)
                                  Text('${album.releaseYear}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
