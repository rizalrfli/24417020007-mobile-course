import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/data/mock_data.dart';
import '../shared/models/music.dart';

final isDemoProvider = Provider<bool>(
  (ref) => mockSongs.every((song) => song.isDemo),
);

final homeProvider = AsyncNotifierProvider<HomeController, HomeFeed>(
  HomeController.new,
);

class HomeController extends AsyncNotifier<HomeFeed> {
  @override
  Future<HomeFeed> build() async => HomeFeed(
    popular: [
      mockSongs.firstWhere((s) => s.id == 'nina'),
      mockSongs.firstWhere((s) => s.id == 'honeybee'),
      mockSongs.firstWhere((s) => s.id == 'peradaban'),
      mockSongs.firstWhere((s) => s.id == 'akad'),
    ],
    recommended: [
      mockSongs.firstWhere((s) => s.id == 'everything-u-are'),
      mockSongs.firstWhere((s) => s.id == 'honeybee'),
      mockSongs.firstWhere((s) => s.id == 'nina'),
      mockSongs.firstWhere((s) => s.id == 'akad'),
    ],
    artists: mockArtists,
    isDemo: ref.watch(isDemoProvider),
  );

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => build());
  }
}

final songDetailProvider = FutureProvider.autoDispose.family<Song, String>(
  (ref, id) async => mockSongs.firstWhere(
    (song) => song.id == id,
    orElse: () => throw Exception('Lagu tidak ditemukan'),
  ),
);

final lyricsProvider = FutureProvider.autoDispose.family<Lyrics, String>((
  ref,
  id,
) async {
  final song = mockSongs.firstWhere(
    (song) => song.id == id,
    orElse: () => throw Exception('Lagu tidak ditemukan'),
  );
  var text = mockLyrics[id];
  if (id == 'peradaban') {
    const path = 'assets/lyrics/peradaban.txt';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    if (manifest.listAssets().contains(path)) {
      text = (await rootBundle.loadString(path)).trim();
    }
  }
  return Lyrics(
    text: text,
    attribution: song.isDemo
        ? 'Teks contoh orisinal untuk demo LyricWave.'
        : null,
    isDemo: song.isDemo,
  );
});

final artistProvider = FutureProvider.autoDispose.family<Artist, String>(
  (ref, id) async => allMockArtists.firstWhere(
    (artist) => artist.id == id,
    orElse: () => throw Exception('Artis tidak ditemukan'),
  ),
);

final artistSongsProvider = FutureProvider.autoDispose
    .family<List<Song>, String>(
      (ref, id) async =>
          mockSongs.where((song) => song.artist.id == id).toList(),
    );

final favoriteSongsProvider =
    NotifierProvider<FavoriteSongsNotifier, AsyncValue<List<Song>>>(
      FavoriteSongsNotifier.new,
    );

class FavoriteSongsNotifier extends Notifier<AsyncValue<List<Song>>> {
  @override
  AsyncValue<List<Song>> build() => const AsyncData([]);

  void setFavorite(Song song, bool favorite) {
    final current = state.valueOrNull ?? [];
    if (favorite) {
      if (!current.any((s) => s.id == song.id)) {
        state = AsyncData([...current, song]);
      }
    } else {
      state = AsyncData(current.where((s) => s.id != song.id).toList());
    }
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, AsyncValue<List<Song>>>(
      HistoryNotifier.new,
    );

class HistoryNotifier extends Notifier<AsyncValue<List<Song>>> {
  @override
  AsyncValue<List<Song>> build() => const AsyncData([]);

  void recordView(Song song) {
    final current = state.valueOrNull ?? [];
    final filtered = current.where((s) => s.id != song.id).toList();
    state = AsyncData([song, ...filtered].take(50).toList());
  }

  void clearHistory() {
    state = const AsyncData([]);
  }
}

final libraryActionsProvider = NotifierProvider<LibraryActions, Set<String>>(
  LibraryActions.new,
);

class LibraryActions extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  Future<void> setFavorite(Song song, bool favorite) async {
    ref.read(favoriteSongsProvider.notifier).setFavorite(song, favorite);
  }

  Future<void> recordView(Song song) async {
    ref.read(historyProvider.notifier).recordView(song);
  }

  Future<void> clearHistory() async {
    ref.read(historyProvider.notifier).clearHistory();
  }
}

final lyricsSizeProvider =
    NotifierProvider<LyricsSizeController, AsyncValue<double>>(
      LyricsSizeController.new,
    );

class LyricsSizeController extends Notifier<AsyncValue<double>> {
  @override
  AsyncValue<double> build() => const AsyncData(24.0);

  Future<void> setSize(double size) async {
    state = AsyncData(size.clamp(22, 28));
  }
}
