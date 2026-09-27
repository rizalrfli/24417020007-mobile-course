import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_widgets.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cari')),
      body: PageBody(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverToBoxAdapter(
                child: SearchField(
                  controller: _text,
                  onChanged: ref
                      .read(searchControllerProvider.notifier)
                      .setQuery,
                ),
              ),
            ),
            if (state.query.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  title: 'Cari lagu yang ingin kamu baca',
                  message: 'Ketik judul, nama artis, atau album.',
                  icon: Icons.search,
                ),
              )
            else
              ...state.results.when(
                skipLoadingOnRefresh: false,
                loading: () => [
                  const SliverPadding(
                    padding: EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: LoadingSkeleton(label: 'Mencari lagu'),
                    ),
                  ),
                ],
                error: (error, _) => [
                  SliverToBoxAdapter(
                    child: ErrorState(
                      error: error,
                      onRetry: ref
                          .read(searchControllerProvider.notifier)
                          .retry,
                    ),
                  ),
                ],
                data: (songs) => songs.isEmpty
                    ? [
                        const SliverToBoxAdapter(
                          child: EmptyState(
                            title: 'Lagu tidak ditemukan',
                            message: 'Coba judul, artis, atau album lain.',
                            icon: Icons.search_off,
                          ),
                        ),
                      ]
                    : [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: Semantics(
                              liveRegion: true,
                              child: Text('${songs.length} lagu ditemukan'),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          sliver: SliverList.builder(
                            itemCount: songs.length,
                            itemBuilder: (context, index) =>
                                SongTile(song: songs[index]),
                          ),
                        ),
                      ],
              ),
          ],
        ),
      ),
    );
  }
}
