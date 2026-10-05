import 'package:go_router/go_router.dart';

import 'pages/note_detail_page.dart';
import 'pages/notes_page.dart';
import 'pages/posts_page.dart';
import 'pages/settings_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const NotesPage(),
      routes: [
        GoRoute(
          path: 'note/:id',
          builder: (context, state) => NoteDetailPage(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: 'posts',
          builder: (context, state) => const PostsPage(),
        ),
      ],
    ),
  ],
);
