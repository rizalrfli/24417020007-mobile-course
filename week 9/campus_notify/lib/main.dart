import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/inbox_item.dart';
import 'messaging/message_route.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/debug_page.dart';
import 'pages/home_page.dart';
import 'pages/inbox_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/inbox_provider.dart';
import 'providers/push_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (error) {
    // google-services.json tidak ada atau konfigurasi rusak. Aplikasi tetap
    // bisa dipakai untuk login; FCM dinonaktifkan dan dicatat di layar debug.
    debugPrint('Firebase tidak siap: ${error.runtimeType}');
  }

  final container = ProviderContainer();
  final router = buildRouter(container);
  final push = container.read(pushStatusProvider.notifier);

  // Angka badge di ikon aplikasi mengikuti jumlah notifikasi belum dibaca.
  // Didaftarkan sebelum pesan pertama bisa masuk supaya badge tidak pernah
  // tertinggal satu langkah.
  container.listen<int>(
    unreadCountProvider,
    (_, next) => container.read(badgeSinkProvider).setCount(next),
    fireImmediately: true,
  );

  if (firebaseReady) {
    registerBackgroundHandler();

    final granted = await requestNotificationPermission();
    push.permission(granted);

    final launchRoute = await initLocalNotifications(
      onOpen: (route, id) => _openFromNotification(
        container,
        router,
        route,
        'foreground',
        id: id,
      ),
    );

    // Background lalu banner diklik.
    listenMessageOpened(
      (data, messageId) => _openFromNotification(
        container,
        router,
        routeFromMessage(data),
        'background',
        id: InboxItem.fromMessage(
          messageId: messageId,
          title: data['title']?.toString(),
          body: data['body']?.toString(),
          data: data,
        ).id,
      ),
    );

    // Foreground: sistem tidak menampilkan banner otomatis.
    listenForeground(
      onMessage: (message) async {
        final item = inboxItemFromMessage(message);
        // Masuk daftar lebih dulu supaya badge ikut naik bersamaan dengan
        // banner muncul, bukan beberapa detik kemudian.
        await container.read(inboxProvider.notifier).add(item);
        await showForegroundNotification(
          message,
          payload: encodeNotificationPayload(
            id: item.id,
            route: item.route,
          ),
          badgeCount: container.read(unreadCountProvider),
        );
        push.note(
          PushDebugSource.foreground,
          'Pesan diterima saat aplikasi terbuka',
        );
      },
    );

    await initFcmToken(
      onToken: (token) async {
        await container.read(deviceRegistrarProvider).register(token);
        push.backendRegistered();
      },
      onTokenSeen: (token, {required fromRefresh}) =>
          push.token(token, fromRefresh: fromRefresh),
      onTokenError: (message) => push.backendFailed(message),
      onSubscribed: push.topic,
    );

    // Terminated lalu banner diklik: rute disimpan sampai pengguna terautentikasi.
    final initialItem = await initialItemFromNotification();
    if (initialItem != null) {
      container.read(pendingRouteProvider.notifier).hold(initialItem.route);
      push.opened(initialItem.route, 'terminated');
      // Dibuka langsung berarti sudah dibaca.
      await container.read(inboxProvider.notifier).markRead(initialItem.id);
    } else if (launchRoute != null) {
      container.read(pendingRouteProvider.notifier).hold(launchRoute.route);
      push.opened(launchRoute.route, 'foreground');
      final id = launchRoute.id;
      if (id != null) {
        await container.read(inboxProvider.notifier).markRead(id);
      }
    }
  }

  // Rute dari notifikasi baru dibuka setelah status login siap, supaya pengguna
  // tidak mendarat di halaman yang masih terlindungi guard.
  void flushPendingRoute() {
    if (container.read(authStateProvider).value != true) return;
    final pending = container.read(pendingRouteProvider.notifier).take();
    if (pending != null) router.go(pending);
  }

  container.listen<AsyncValue<bool>>(
    authStateProvider,
    (_, _) => flushPendingRoute(),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: CampusNotifyApp(router: router),
    ),
  );

  // Sesi yang sudah tersimpan tidak memicu perubahan status, jadi rute tertunda
  // dibuka sekali setelah frame pertama.
  WidgetsBinding.instance.addPostFrameCallback((_) => flushPendingRoute());
}

/// Membuka [route] bila router sudah siap. Saat pengguna belum login, rute
/// ditahan dan dibuka lagi setelah login berhasil.
///
/// [id] adalah notifikasi yang dibuka. Membukanya sama dengan membacanya,
/// sehingga butir itu dihapus dari daftar dan badge berkurang.
void _openFromNotification(
  ProviderContainer container,
  GoRouter router,
  String route,
  String source, {
  String? id,
}) {
  container.read(pushStatusProvider.notifier).opened(route, source);
  if (id != null) {
    container.read(inboxProvider.notifier).markRead(id);
  }
  if (container.read(authStateProvider).value == true) {
    router.go(route);
  } else {
    container.read(pendingRouteProvider.notifier).hold(route);
  }
}

GoRouter buildRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: container.read(routerRefreshProvider),
    redirect: (context, state) {
      final auth = container.read(authStateProvider);
      final location = state.matchedLocation;

      // Selama token masih dibaca, tampilkan layar tunggu supaya pengguna yang
      // sudah login tidak sempat melihat form login.
      if (auth.isLoading) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final loggedIn = auth.value ?? false;
      if (!loggedIn) {
        return location == Routes.login ? null : Routes.login;
      }
      if (location == Routes.login || location == Routes.splash) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
      GoRoute(path: Routes.inbox, builder: (_, _) => const InboxPage()),
      GoRoute(path: debugRoute, builder: (_, _) => const DebugPage()),
      GoRoute(
        path: Routes.announcementPattern,
        builder: (_, state) => AnnouncementPage(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class CampusNotifyApp extends StatelessWidget {
  const CampusNotifyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E5F)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
