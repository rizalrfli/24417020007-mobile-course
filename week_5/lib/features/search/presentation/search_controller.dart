import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/models/music.dart';

class SongSearchState {
  const SongSearchState({this.query = '', this.results = const AsyncData([])});
  final String query;
  final AsyncValue<List<Song>> results;
}

final searchControllerProvider =
    StateNotifierProvider.autoDispose<SongSearchController, SongSearchState>(
      (ref) => SongSearchController(),
    );

class SongSearchController extends StateNotifier<SongSearchState> {
  SongSearchController() : super(const SongSearchState());
  Timer? _debounce;
  int _version = 0;

  void setQuery(String query) {
    _debounce?.cancel();
    final version = ++_version;
    if (query.trim().isEmpty) {
      state = const SongSearchState();
      return;
    }
    state = SongSearchState(query: query, results: const AsyncLoading());
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || version != _version) return;
      final keyword = query.trim().toLowerCase();
      final filtered = mockSongs
          .where(
            (song) => [
              song.title,
              song.artist.name,
              song.album?.title ?? '',
              song.genre ?? '',
            ].any((field) => field.toLowerCase().contains(keyword)),
          )
          .toList();
      state = SongSearchState(query: query, results: AsyncData(filtered));
    });
  }

  void retry() => setQuery(state.query);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
