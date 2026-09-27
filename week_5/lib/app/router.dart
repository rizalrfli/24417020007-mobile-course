import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/artist/presentation/artist_screen.dart';
import '../features/favorite/presentation/favorites_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/song/presentation/mini_player_bar.dart';
import '../features/song/presentation/song_detail_screen.dart';
import '../shared/widgets/app_widgets.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, shell) => AppScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shellHome'),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shellSearch'),
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey:
                GlobalKey<NavigatorState>(debugLabel: 'shellFavorites'),
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shellProfile'),
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/song/:id',
        builder: (context, state) =>
            SongDetailScreen(songId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/artist/:id',
        builder: (context, state) =>
            ArtistScreen(artistId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: EmptyState(
          title: 'Halaman tidak ditemukan',
          message: 'Kembali ke beranda untuk mencari lagu.',
          action: 'Buka beranda',
          onAction: () => context.go('/'),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniPlayerBar(),
        NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) =>
              shell.goBranch(index, initialLocation: index == shell.currentIndex),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'Cari'),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorit',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ],
    ),
  );
}
