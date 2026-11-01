import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/inbox_item.dart';
import '../data/inbox_store.dart';
import 'message_route.dart';

const campusTopic = 'pengumuman-kampus';

/// Versi kanal dinaikkan saat setelan bunyi berubah.
///
/// Android menyimpan setelan kanal selamanya setelah dibuat: mengubah
/// `importance` atau `sound` pada id yang sama tidak berpengaruh pada perangkat
/// yang sudah memasang aplikasi. Id baru memaksa sistem membuat kanal ulang.
const _channelId = 'pengumuman_v2';
const _channelName = 'Pengumuman Kampus';
const _channelDescription =
    'Pemberitahuan jadwal dan pengumuman dari kampus.';

final _local = FlutterLocalNotificationsPlugin();

/// Dipanggil dari `main()` sebelum `runApp`, setelah `Firebase.initializeApp`.
///
/// Tidak boleh menyentuh `BuildContext` atau `Ref`: fungsi ini juga dijalankan
/// dari isolate background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate terpisah: tidak ada BuildContext, Riverpod, maupun router di sini.
  // Yang bisa dilakukan hanya menyimpan data, dan itulah yang dikerjakan:
  // pesan dimasukkan ke kotak masuk supaya tetap terlihat di daftar saat
  // aplikasi dibuka kembali.
  try {
    // Isolate background tidak mewarisi plugin registrant dari isolate utama;
    // tanpa baris ini `shared_preferences` tidak bisa dipanggil.
    DartPluginRegistrant.ensureInitialized();
    final item = _itemFromMessage(message);
    await InboxRepository(PrefsInboxStore()).add(item);
  } catch (error) {
    // Penyimpanan gagal tidak boleh membuat proses background crash.
    debugPrint('Gagal menyimpan pesan background: ${error.runtimeType}');
  }
}

InboxItem _itemFromMessage(RemoteMessage message) {
  return InboxItem.fromMessage(
    messageId: message.messageId,
    title: message.notification?.title,
    body: message.notification?.body,
    data: message.data,
  );
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
/// Mengembalikan rute dari banner yang dipakai untuk membuka aplikasi (cold
/// start), misalnya saat aplikasi dimatikan lalu pengguna mengklik banner.
Future<({String? id, String route})?> initLocalNotifications({
  required void Function(String route, String? id) onOpen,
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
      final opened = decodeNotificationPayload(payload);
      onOpen(opened.route, opened.id);
    },
  );

  const channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
    // Bunyi notifikasi: kanal memakai suara bawaan sistem. Tanpa
    // `playSound: true` kanal bisa dibuat senyap pada beberapa perangkat.
    playSound: true,
    enableVibration: true,
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
    return decodeNotificationPayload(payload);
  }
  return null;
}

/// Menampilkan banner untuk pesan yang datang saat aplikasi foreground.
///
/// Tanpa langkah ini Android tidak menampilkan apa pun ketika aplikasi terbuka.
/// [badgeCount] dipakai untuk angka di tray notifikasi Android dan badge ikon
/// aplikasi di iOS.
Future<void> showForegroundNotification(
  RemoteMessage message, {
  required String payload,
  int badgeCount = 0,
}) async {
  final title =
      message.notification?.title ?? message.data['title'] ?? 'Pengumuman';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  final androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    // Bunyi: `playSound` + suara bawaan sistem. `sound` sengaja tidak diisi
    // agar tidak bergantung pada file audio di `res/raw`.
    playSound: true,
    enableVibration: true,
    number: badgeCount,
  );
  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentSound: true,
    badgeNumber: badgeCount,
  );

  await _local.show(
    // Id stabil per pengumuman supaya kiriman ulang tidak menumpuk.
    message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: payload,
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
      onTokenError(
        'Token kosong. Perangkat mungkin tanpa Google Play Services.',
      );
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
void listenMessageOpened(
  void Function(Map<String, dynamic> data, String? messageId) onOpen,
) {
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    onOpen(message.data, message.messageId);
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
Future<InboxItem?> initialItemFromNotification() async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial == null) return null;
  return _itemFromMessage(initial);
}

/// Membangun [InboxItem] dari pesan yang diterima di isolate utama.
InboxItem inboxItemFromMessage(RemoteMessage message) =>
    _itemFromMessage(message);

Future<void> subscribeCampusTopic() =>
    FirebaseMessaging.instance.subscribeToTopic(campusTopic);

Future<void> unsubscribeCampusTopic() =>
    FirebaseMessaging.instance.unsubscribeFromTopic(campusTopic);
