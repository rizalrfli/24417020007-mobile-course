import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/music.dart';
import '../../../shared/widgets/app_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/logo/logo.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Text('LyricWave'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Riwayat lagu',
          onPressed: () => context.push('/history'),
          icon: const Icon(Icons.history),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: PageBody(
      child: RefreshIndicator(
        onRefresh: ref.read(homeProvider.notifier).refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(_greeting(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Temukan cerita\ndi setiap lagu.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Cari lagu, artis, atau album',
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go('/search'),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 12),
                        Expanded(child: Text('Lagu apa yang kamu cari?')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (ref.watch(isDemoProvider))
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Katalog demo · Lagu, artis, dan lirik adalah contoh.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            SectionTitle(
              'Terakhir dilihat',
              action: 'Riwayat',
              onAction: () => context.push('/history'),
            ),
            AsyncContent(
              value: ref.watch(historyProvider),
              onRetry: () => ref.invalidate(historyProvider),
              loadingLabel: 'Memuat riwayat',
              data: (songs) => songs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Lagu yang kamu buka akan tersimpan di sini.',
                      ),
                    )
                  : SongShelf(songs: songs.take(8).toList()),
            ),
            AsyncContent(
              value: ref.watch(homeProvider),
              onRetry: ref.read(homeProvider.notifier).refresh,
              data: (feed) => _HomeCatalog(feed: feed),
            ),
          ],
        ),
      ),
    ),
  );

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}

class _HomeCatalog extends StatelessWidget {
  const _HomeCatalog({required this.feed});
  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    if (feed.popular.isEmpty &&
        feed.recommended.isEmpty &&
        feed.artists.isEmpty) {
      return EmptyState(
        title: 'Katalog belum tersedia',
        message: 'Coba cari lagu berdasarkan judul atau artis.',
        action: 'Cari lagu',
        onAction: () => context.go('/search'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Lagu populer'),
        if (feed.popular.isEmpty)
          const Text('Belum ada lagu populer.')
        else
          ...feed.popular.indexed.map(
            (entry) => SongTile(song: entry.$2, number: entry.$1 + 1),
          ),
        const SectionTitle('Pilihan untukmu'),
        if (feed.recommended.isEmpty)
          const Text('Pilihan lagu belum tersedia.')
        else
          SongShelf(songs: feed.recommended),
        const SectionTitle('Artis populer'),
        if (feed.artists.isEmpty)
          const Text('Belum ada artis populer.')
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: feed.artists
                .map(
                  (artist) => SizedBox(
                    width: 96,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(
                          '/artist/${Uri.encodeComponent(artist.id)}',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            children: [
                              CoverArt(
                                title: artist.name,
                                url: artist.imageUrl,
                                size: 72,
                                circle: true,
                                isDemo: artist.isDemo,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                artist.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
