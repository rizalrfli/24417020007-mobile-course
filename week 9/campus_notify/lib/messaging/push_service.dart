import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'message_route.dart';

const campusTopic = 'pengumuman-kampus';
const _channelId = 'pengumuman';

final _local = FlutterLocalNotificationsPlugin();

/// Dipanggil dari `main()` sebelum `runApp`, setelah `Firebase.initializeApp`.
///
/// Tidak boleh menyentuh `BuildContext` atau `Ref`: fungsi ini juga dijalankan
/// dari isolate background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate terpisah: tidak ada BuildContext, Riverpod, maupun router di sini.
  // Sistem Android/iOS sudah menampilkan payload `notification`; tugas handler
  // ini hanya mencatat, dan navigasi terjadi saat pengguna mengklik banner.
  debugPrint('Pesan background: ${message.messageId}');
}

/// Daftarkan handler background. Dipanggil sekali di `main()` sebelum
/// `runApp`, karena Android memasang entry point-nya saat engine start.
void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

/// True bila perangkat mengizinkan notifikasi.
///
/// Android 13+ menampilkan dialog izin `POST_NOTIFICATIONS` di sini; iOS
/// menampilkan dialog APNs. Di Android 12 ke bawah fungsi ini langsung true.
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  final status = settings.authorizationStatus;
  return status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}

/// Kanal notifikasi lokal + penanganan klik banner foreground.
///
/// Mengembalikan route dari banner yang dipakai untuk membuka aplikasi (cold
/// start), misalnya saat aplikasi dimatikan lalu pengguna mengklik banner.
Future<String?> initLocalNotifications({
  required void Function(String route) onOpen,
}) async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    // Izin sudah diminta lewat FCM; jangan munculkan dialog dua kali.
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _local.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) return;
      onOpen(routeFromMessage({'route': payload}));
    },
  );

  const channel = AndroidNotificationChannel(
    _channelId,
    'Pengumuman Kampus',
    description: 'Pemberitahuan jadwal dan pengumuman dari kampus.',
    importance: Importance.high,
  );
  await _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Aplikasi dibuka dari banner lokal (proses sebelumnya sudah mati). Tanpa
  // pembacaan ini, payload klik hilang karena callback response tidak dipanggil.
  final launch = await _local.getNotificationAppLaunchDetails();
  final payload = launch?.notificationResponse?.payload;
  if (launch?.didNotificationLaunchApp == true &&
      payload != null &&
      payload.isNotEmpty) {
    return routeFromMessage({'route': payload});
  }
  return null;
}

/// Menampilkan banner untuk pesan yang datang saat aplikasi foreground.
///
/// Tanpa langkah ini Android tidak menampilkan apa pun ketika aplikasi terbuka.
Future<void> showForegroundNotification(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'] ?? 'Pengumuman';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  final route = routeFromMessage(message.data);

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    'Pengumuman Kampus',
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentSound: true,
  );

  await _local.show(
    // Id stabil per pengumuman supaya kiriman ulang tidak menumpuk.
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
    title,
    body,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: route,
  );
}

/// Mengambil token perangkat, memantau rotasinya, lalu berlangganan topik.
///
/// [onToken] dipanggil untuk token saat ini dan setiap kali token berubah.
/// Tanpa listener `onTokenRefresh`, backend akan menyimpan token basi setelah
/// reinstall atau pembersihan data aplikasi.
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
  required void Function(String token, {required bool fromRefresh}) onTokenSeen,
  required void Function(String error) onTokenError,
  required void Function(String topic) onSubscribed,
}) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      onTokenSeen(token, fromRefresh: false);
      await _send(token, onToken, onTokenError);
    } else {
      onTokenError('Token kosong. Perangkat mungkin tanpa Google Play Services.');
    }
  } catch (error) {
    onTokenError('Gagal mengambil token: ${error.runtimeType}');
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    onTokenSeen(token, fromRefresh: true);
    await _send(token, onToken, onTokenError);
  });

  try {
    await FirebaseMessaging.instance.subscribeToTopic(campusTopic);
    onSubscribed(campusTopic);
  } catch (error) {
    onTokenError('Gagal berlangganan topik: ${error.runtimeType}');
  }
}

Future<void> _send(
  String token,
  Future<void> Function(String token) onToken,
  void Function(String error) onTokenError,
) async {
  try {
    await onToken(token);
  } catch (error) {
    onTokenError(error.toString());
  }
}

/// Pesan saat aplikasi di background lalu bannernya diklik.
void listenMessageOpened(void Function(String route) onOpen) {
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    onOpen(routeFromMessage(message.data));
  });
}

/// Pesan yang masuk saat aplikasi terbuka.
///
/// Sistem tidak menampilkan banner sendiri di state ini, jadi handler ini
/// menampilkan notifikasi lokal agar pengguna tetap melihat pengumuman.
void listenForeground({
  required Future<void> Function(RemoteMessage message) onMessage,
}) {
  FirebaseMessaging.onMessage.listen(onMessage);
}

/// Pesan yang membuka aplikasi dari keadaan terminated.
Future<String?> initialRouteFromNotification() async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial == null) return null;
  return routeFromMessage(initial.data);
}

Future<void> subscribeCampusTopic() =>
    FirebaseMessaging.instance.subscribeToTopic(campusTopic);

Future<void> unsubscribeCampusTopic() =>
    FirebaseMessaging.instance.unsubscribeFromTopic(campusTopic);
