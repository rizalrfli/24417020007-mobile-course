import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/debug_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
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

  if (firebaseReady) {
    registerBackgroundHandler();

    final granted = await requestNotificationPermission();
    push.permission(granted);

    final launchRoute = await initLocalNotifications(
      onOpen: (route) => _open(container, router, route, 'foreground'),
    );

    // Background lalu banner diklik.
    listenMessageOpened(
      (route) => _open(container, router, route, 'background'),
    );

    // Foreground: sistem tidak menampilkan banner otomatis.
    listenForeground(
      onMessage: (message) async {
        await showForegroundNotification(message);
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
    final initialRoute = await initialRouteFromNotification();
    if (initialRoute != null) {
      container.read(pendingRouteProvider.notifier).hold(initialRoute);
      push.opened(initialRoute, 'terminated');
    } else if (launchRoute != null) {
      container.read(pendingRouteProvider.notifier).hold(launchRoute);
      push.opened(launchRoute, 'foreground');
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
void _open(
  ProviderContainer container,
  GoRouter router,
  String route,
  String source,
) {
  container.read(pushStatusProvider.notifier).opened(route, source);
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
      if (auth.isLoading) return location == Routes.splash ? null : Routes.splash;

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
