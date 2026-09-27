import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favorit')),
    body: PageBody(
      child: ref
          .watch(favoriteSongsProvider)
          .when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingSkeleton(),
            ),
            error: (error, _) => ListView(
              children: [
                ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(favoriteSongsProvider),
                ),
              ],
            ),
            data: (songs) {
              if (songs.isEmpty) {
                return ListView(
                  children: [
                    EmptyState(
                      title: 'Belum ada lagu favorit',
                      message:
                          'Ketuk ikon hati pada lagu. Favoritmu akan tersimpan di perangkat ini.',
                      icon: Icons.favorite_border,
                      action: 'Cari lagu',
                      onAction: () => context.go('/search'),
                    ),
                  ],
                );
              }
              final query = _text.text.trim().toLowerCase();
              final filtered = songs
                  .where(
                    (s) => '${s.title} ${s.artist.name} ${s.album?.title ?? ''}'
                        .toLowerCase()
                        .contains(query),
                  )
                  .toList();
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${songs.length} lagu tersimpan'),
                          const SizedBox(height: 20),
                          SearchField(
                            controller: _text,
                            label: 'Cari di favorit',
                            hint: 'Judul, artis, atau album favorit',
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverToBoxAdapter(
                      child: EmptyState(
                        title: 'Tidak ada favorit yang cocok',
                        message: 'Coba kata kunci lain.',
                        icon: Icons.search_off,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            SongTile(song: filtered[index], showFavorite: true),
                      ),
                    ),
                ],
              );
            },
          ),
    ),
  );
}
